//
//  QuizQuestionRefiner.swift
//  realtornote
//
//  Optional on-device refinement (Foundation Models, iOS 26+) of rule-based quiz questions.
//  Rules still pick the paragraph and the correct answer; the model only writes the question
//  stem and (for positive questions) plausible wrong choices. Any failure returns nil so the
//  caller keeps the rule-based question untouched.
//

import Foundation
import OSLog
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Shared logger; filter Console/Xcode by category `QuizFM`.
let quizLog = Logger(subsystem: Bundle.main.bundleIdentifier ?? "realtornote", category: "QuizFM")

struct QuizRefinement {
    /// Natural Korean question stem that contains the topic. nil when only choice rewrites exist.
    let stem: String?
    /// Validated model-written wrong choices (0...4). nil for negative questions, whose wrong choices are real items.
    /// Missing ones are filled from the rule-based question by the caller.
    let wrong: [String]?
    /// Validated natural-language rewrites of choices that came from the summary, keyed by the
    /// choice's ORIGINAL title (answers are shuffled, so never match by position).
    var rewrites: [String: String] = [:]

    init(stem: String?, wrong: [String]?, rewrites: [String: String] = [:]) {
        self.stem = stem
        self.wrong = wrong
        self.rewrites = rewrites
    }
}

/// Why AI question generation can or can't run right now. Drives the in-quiz guidance banner.
enum QuizAIStatus: Equatable {
    case ready
    /// Apple Intelligence is on but the on-device model is still downloading/preparing.
    case preparing
    /// Device supports it, but Apple Intelligence is switched off in Settings.
    case notEnabled
    /// Device, OS version or language can't run it; nothing the user can do.
    case unsupported
}

enum QuizQuestionRefiner {
    private static let timeoutSeconds: UInt64 = 60
    private static let distractorCount = 4

    /// Cheap check callers can use to skip scheduling work entirely.
    static var isAvailable: Bool { status == .ready }

    static var status: QuizAIStatus {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return FoundationModelsRefiner.status
        }
        quizLog.notice("FM skipped: OS < 26")
        #else
        quizLog.notice("FM skipped: FoundationModels not importable in this build")
        #endif
        return .unsupported
    }

    /// Refines all questions with ONE model request. Returns validated refinements keyed by the
    /// question's position in `questions`; missing keys mean "keep the rule-based question".
    @MainActor
    static func refinements(for questions: [RNQuestionInfo]) async -> [Int: QuizRefinement] {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return await FoundationModelsRefiner.refinements(for: questions, timeout: timeoutSeconds, distractorCount: distractorCount)
        }
        #endif
        return [:]
    }

    // MARK: - Validation (framework independent)

    static func isKorean(_ text: String) -> Bool {
        text.unicodeScalars.contains { (0xAC00...0xD7A3).contains($0.value) }
    }

    /// True when the text still looks like a summary memo (arrows, "A < B < C" chains).
    static func isMemo(_ text: String) -> Bool {
        if ["=>", "→", "⇒", "<-", "->"].contains(where: { text.contains($0) }) { return true }
        return text.range(of: #"[^\s<>]\s*[<>]\s*[^\s<>]"#, options: .regularExpression) != nil
    }

    static func normalized(_ text: String) -> String {
        text.filter { !$0.isWhitespace && !$0.isPunctuation }.lowercased()
    }

    private static let questionEndings = ["것은", "것을", "것인가", "무엇인가", "무엇입니까", "인가", "일까", "는가", "은가", "나요", "습니까"]

    /// Returns the stem as a complete question (ending with "?"), or nil if it is a fragment.
    /// A missing "?" is appended only after a typical question ending.
    static func completeQuestion(_ text: String) -> String? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        if value.hasSuffix("?") || value.hasSuffix("？") { return value }
        // Exam imperative endings are complete as-is (고르시오, 선택하시오 ...).
        if value.hasSuffix("시오.") || value.hasSuffix("시오") { return value }
        if questionEndings.contains(where: { value.hasSuffix($0) }) { return value + "?" }
        return nil
    }

    /// The model sometimes writes the section 〉 part path inside the stem. Without 〉 the stem is used as is.
    /// With 〉, prefer the text before the first 〉 if it is a complete question, else the text after the last 〉.
    /// Returns nil when no complete question can be recovered.
    static func cleanedStem(_ stem: String) -> String? {
        guard let first = stem.firstIndex(of: "〉"), let last = stem.lastIndex(of: "〉") else {
            return completeQuestion(stem)
        }
        if let head = completeQuestion(String(stem[..<first])) { return head }
        return completeQuestion(String(stem[stem.index(after: last)...]))
    }

    static func isValidStem(_ stem: String, correct: String) -> Bool {
        stemRejectionReason(stem, correct: correct) == nil
    }

    /// nil when the stem is usable, else a short reason for logging.
    static func stemRejectionReason(_ stem: String, correct: String) -> String? {
        let value = stem.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty { return "empty" }
        if value.count > 120 { return "too long" }
        if !isKorean(value) { return "not Korean" }
        // The stem must not leak the answer.
        let answer = normalized(correct)
        if answer.count >= 4 && normalized(value).contains(answer) { return "leaks answer" }
        return nil
    }

    /// Digit runs ("3", "10", "2.5" -> "2","5") of a text, sorted, for exact-preservation checks.
    static func digitRuns(_ text: String) -> [String] {
        var runs: [String] = []
        var current = ""
        for ch in text {
            if ch.isASCII && ch.isNumber { current.append(ch) } else if !current.isEmpty { runs.append(current); current = "" }
        }
        if !current.isEmpty { runs.append(current) }
        return runs.sorted()
    }

    /// Returns the rewritten choice if usable, else nil (caller keeps the original text).
    /// `others` are the other choices of the same question (current texts).
    static func validatedRewrite(_ raw: String, original: String, others: [String]) -> String? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, isKorean(value), value.count <= 200 else {
            quizLog.notice("FM rewrite rejected (empty/non-Korean/long): \(value, privacy: .public)")
            return nil
        }
        guard digitRuns(value) == digitRuns(original) else {
            quizLog.notice("FM rewrite rejected (digits changed): \(original, privacy: .public) -> \(value, privacy: .public)")
            return nil
        }
        if isMemo(value) {
            quizLog.notice("FM rewrite rejected (memo notation left): \(value, privacy: .public)")
            return nil
        }
        let key = normalized(value)
        if others.contains(where: { normalized($0) == key }) {
            quizLog.notice("FM rewrite rejected (collides with another choice): \(value, privacy: .public)")
            return nil
        }
        return value
    }

    /// Keeps the usable wrong choices; drops (instead of failing the whole quiz) any that are empty,
    /// not Korean, duplicated, or equal to a real item / the correct answer.
    static func sanitizedWrong(_ raw: [String], trueItems: [String], correct: String, limit: Int) -> [String] {
        var blocked = Set(trueItems.map(normalized).filter { !$0.isEmpty })
        blocked.insert(normalized(correct))
        var seen = Set<String>()
        var result: [String] = []

        for item in raw {
            let title = item.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = normalized(title)
            guard !key.isEmpty, isKorean(title), title.count <= 200 else { continue }
            guard !blocked.contains(key), seen.insert(key).inserted else { continue }
            result.append(title)
            if result.count == limit { break }
        }
        return result
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
private struct GeneratedPositive {
    @Guide(description: "문제 번호. 입력에서 받은 번호를 그대로 쓴다.")
    var number: Int

    @Guide(description: "마지막 항목명 하나만 주제로 넣은 짧은 시험 문제 질문 문장 한 개. 경로를 '속에서'·'중'·'의'로 이어 쓰지 않는다. 예: '다음 중 ○○에 관한 설명으로 옳은 것은?'. 반드시 '?' 또는 '고르시오.'로 끝나는 완결된 문장. 한국어. 〉 같은 경로 표기와 보기·정답 내용은 쓰지 않는다. 반드시 채운다.")
    var stem: String

    @Guide(description: "정답 보기를 의미 그대로 자연스러운 한국어로 다시 쓴 것. 원문은 암기용 요약 메모다. 뜻을 이해한 뒤 실제 시험 보기처럼 자연스러운 단어(구) 또는 문장으로 쓴다. 기호(=>, →, <, 괄호 등)는 남기지 않는다. 숫자·법률 용어·기간·금액·비율은 유지, 새 사실 금지. 오답과 같은 문체. 반드시 채운다. 빈 문자열 금지.")
    var correct: String

    // Four separate fields (not an array) so the model writes four different wrong choices.
    @Guide(description: "오답 1: 정답의 핵심 단어나 수치 하나를 바꿔 틀리게 만든 자연스러운 보기. 정답과 같은 형태(자연스러운 단어(구) 또는 문장). 정답과 달라야 한다. 한국어. 반드시 채운다. 빈 문자열 금지.")
    var wrong1: String

    @Guide(description: "오답 2: 정답과 반대되는 의미의 보기. 한국어. 반드시 채운다. 빈 문자열 금지.")
    var wrong2: String

    @Guide(description: "오답 3: 같은 상위 주제의 다른 개념에 해당하는 보기. 한국어. 반드시 채운다. 빈 문자열 금지.")
    var wrong3: String

    @Guide(description: "오답 4: 대상이나 범위를 바꿔 틀리게 만든 보기. 한국어. 반드시 채운다. 빈 문자열 금지.")
    var wrong4: String
}

@available(iOS 26.0, *)
@Generable
private struct GeneratedPositiveBatch {
    @Guide(description: "입력된 문제 수와 같은 개수, 번호 순서대로.")
    var items: [GeneratedPositive]
}

@available(iOS 26.0, *)
@Generable
private struct GeneratedNegative {
    @Guide(description: "문제 번호. 입력에서 받은 번호를 그대로 쓴다.")
    var number: Int

    @Guide(description: "마지막 항목명 하나만 주제로 넣은 짧은 시험 문제 질문 문장 한 개. 경로를 '속에서'·'중'·'의'로 이어 쓰지 않는다. 예: '다음 중 ○○에 해당하지 않는 것은?'. 반드시 '?' 또는 '고르시오.'로 끝나는 완결된 문장. 한국어. 〉 같은 경로 표기와 보기 내용은 쓰지 않는다. 반드시 채운다.")
    var stem: String

    @Guide(description: "보기 1을 의미 그대로 다시 쓴 것. 원문은 암기용 요약 메모다. 뜻을 이해한 뒤 실제 시험 보기처럼 자연스러운 단어(구) 또는 문장으로 쓴다. 기호(=>, →, <, 괄호 등)는 남기지 않는다. 숫자·법률 용어·기간·금액·비율은 유지, 새 사실 금지. 보기 1~5는 같은 문체. 반드시 채운다. 빈 문자열 금지.")
    var choice1: String

    @Guide(description: "보기 2를 같은 규칙으로 다시 쓴 것. 반드시 채운다. 빈 문자열 금지.")
    var choice2: String

    @Guide(description: "보기 3을 같은 규칙으로 다시 쓴 것. 반드시 채운다. 빈 문자열 금지.")
    var choice3: String

    @Guide(description: "보기 4를 같은 규칙으로 다시 쓴 것. 반드시 채운다. 빈 문자열 금지.")
    var choice4: String

    @Guide(description: "보기 5를 같은 규칙으로 다시 쓴 것. 반드시 채운다. 빈 문자열 금지.")
    var choice5: String
}

@available(iOS 26.0, *)
@Generable
private struct GeneratedNegativeBatch {
    @Guide(description: "입력된 문제 수와 같은 개수, 번호 순서대로.")
    var items: [GeneratedNegative]
}

@available(iOS 26.0, *)
@Generable
private struct GeneratedNote {
    @Guide(description: "입력에서 받은 번호를 그대로 쓴다.")
    var id: Int

    @Guide(description: "메모를 의미 그대로 실제 시험 보기처럼 자연스러운 단어(구) 또는 문장으로 다시 쓴 것. 기호(=>, →, <, > 등) 금지. 숫자·법률 용어 유지, 새 사실 금지. 한국어.")
    var text: String
}

@available(iOS 26.0, *)
@Generable
private struct GeneratedNoteBatch {
    @Guide(description: "입력된 메모 수와 같은 개수.")
    var items: [GeneratedNote]
}

@available(iOS 26.0, *)
private enum FoundationModelsRefiner {
    static var isAvailable: Bool { status == .ready }

    static var status: QuizAIStatus {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            let ok = model.supportsLocale(Locale(identifier: "ko_KR"))
            quizLog.notice("FM available, ko_KR supported: \(ok, privacy: .public)")
            return ok ? .ready : .unsupported
        case .unavailable(let reason):
            quizLog.notice("FM unavailable: \(String(describing: reason), privacy: .public)")
            switch reason {
            case .modelNotReady: return .preparing
            case .appleIntelligenceNotEnabled: return .notEnabled
            default: return .unsupported
            }
        @unknown default:
            return .unsupported
        }
    }

    private static let instructions = """
    당신은 공인중개사 시험 문제 출제 보조자입니다. 주어진 법령 요약 내용만 근거로 사용하고, \
    새로운 법률 사실을 만들어내지 마세요. 항상 한국어로 답합니다.
    """

    private struct Input {
        let number: Int
        let path: String
        let children: [String]
        let correct: String
        let positive: Bool
        /// Full original titles of the choices the model rewrites: [correct] for positive, all answers for negative.
        let choices: [String]
        /// Current rule-based wrong titles (positive questions only); model wrong choices may replace them.
        let wrongTitles: [String]
    }

    /// Model output of one question, independent of positive/negative generable type.
    private struct Draft {
        let stem: String
        /// Rewrites of `Input.choices` by index (positive: [correct]; negative: choice1...5).
        let texts: [String]
        /// New wrong choices (positive only).
        let wrong: [String]
    }

    private enum Kind: String { case positive, negative }

    @MainActor
    static func refinements(for questions: [RNQuestionInfo], timeout: UInt64, distractorCount: Int) async -> [Int: QuizRefinement] {
        guard isAvailable else { return [:] }

        var inputs: [Input] = []
        for (offset, question) in questions.enumerated() {
            guard let reference = question.reference,
                  let correct = question.answers.first(where: { $0.isCorrect })?.title,
                  !correct.isEmpty else { continue }
            // Kept short: ten questions share one context window.
            // Negative questions: the choices ARE the real items, so no separate children list.
            inputs.append(Input(number: offset + 1,
                                path: question.text,
                                children: question.positive ? reference.children.prefix(5).map { String($0.text.prefix(50)) } : [],
                                correct: String(correct.prefix(80)),
                                positive: question.positive,
                                choices: question.positive ? [correct] : question.answers.map(\.title),
                                wrongTitles: question.positive ? question.answers.filter { !$0.isCorrect }.map(\.title) : []))
        }
        guard !inputs.isEmpty else { return [:] }

        // Two requests with only their own required fields; one mixed schema made the model leave every choice empty.
        let positives = inputs.filter(\.positive)
        let negatives = inputs.filter { !$0.positive && $0.choices.count == 5 }
        let skipped = inputs.filter { !$0.positive && $0.choices.count != 5 }
        if !skipped.isEmpty {
            quizLog.notice("FM negative skipped (choices != 5), keeping original: \(skipped.map(\.number).map(String.init).joined(separator: ","), privacy: .public)")
        }

        var drafts: [Int: Draft] = [:]
        for (kind, group) in [(Kind.positive, positives), (Kind.negative, negatives)] where !group.isEmpty {
            quizLog.notice("FM \(kind.rawValue, privacy: .public) request start count=\(group.count, privacy: .public)")
            let started = Date()
            let part = await generateWithSplit(group, kind: kind, timeout: timeout)
            quizLog.notice("FM \(kind.rawValue, privacy: .public) done in \(Date().timeIntervalSince(started), privacy: .public)s, drafts=\(part.count, privacy: .public)/\(group.count, privacy: .public)")
            drafts.merge(part) { a, _ in a }
        }

        var result: [Int: QuizRefinement] = [:]
        for input in inputs {
            guard let draft = drafts[input.number] else { continue }
            // An invalid stem only drops the stem; rewrites and wrong choices are still used.
            var stem: String?
            if let draftStem = QuizQuestionRefiner.cleanedStem(draft.stem) {
                if let reason = QuizQuestionRefiner.stemRejectionReason(draftStem, correct: input.correct) {
                    quizLog.notice("FM #\(input.number, privacy: .public) stem rejected (\(reason, privacy: .public)): \(draft.stem, privacy: .public)")
                } else {
                    stem = draftStem.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } else {
                quizLog.notice("FM #\(input.number, privacy: .public) stem rejected (incomplete): \(draft.stem, privacy: .public)")
            }
            let rewrites = rewrittenChoices(input: input, draft: draft)
            if input.positive {
                let finalCorrect = rewrites[input.choices[0]] ?? input.correct
                let wrong = QuizQuestionRefiner.sanitizedWrong(draft.wrong, trueItems: input.children, correct: finalCorrect, limit: distractorCount)
                    .filter { !QuizQuestionRefiner.isMemo($0) }
                quizLog.notice("FM #\(input.number, privacy: .public) usable wrong \(wrong.count, privacy: .public)/\(draft.wrong.count, privacy: .public)")
                if wrong.count < draft.wrong.count {
                    quizLog.notice("FM #\(input.number, privacy: .public) raw wrong=\(draft.wrong.joined(separator: " | "), privacy: .public) true=\(input.children.joined(separator: " | "), privacy: .public)")
                }
                result[input.number - 1] = QuizRefinement(stem: stem, wrong: wrong, rewrites: rewrites)
            } else {
                result[input.number - 1] = QuizRefinement(stem: stem, wrong: nil, rewrites: rewrites)
            }
        }

        // Second chance: rewrite notes that would still be shown as raw memo.
        var leaks: [(number: Int, original: String, others: [String])] = []
        for input in inputs {
            let all = input.choices + input.wrongTitles
            for original in memoNotes(input: input, refinement: result[input.number - 1]) {
                leaks.append((input.number, original, all.filter { $0 != original }))
            }
        }
        if !leaks.isEmpty {
            quizLog.notice("FM second pass start notes=\(leaks.count, privacy: .public)")
            let paths = Dictionary(uniqueKeysWithValues: inputs.map { ($0.number, $0.path) })
            let rewritten = await rewriteNotes(leaks.map { (paths[$0.number] ?? "", $0.original) }, timeout: timeout)
            for (id, leak) in leaks.enumerated() {
                guard let raw = rewritten[id],
                      let value = QuizQuestionRefiner.validatedRewrite(raw, original: leak.original, others: leak.others) else { continue }
                var refinement = result[leak.number - 1] ?? QuizRefinement(stem: nil, wrong: nil)
                refinement.rewrites[leak.original] = value
                result[leak.number - 1] = refinement
            }
        }

        for input in inputs {
            let rest = memoNotes(input: input, refinement: result[input.number - 1])
            quizLog.notice("FM #\(input.number, privacy: .public) memo remaining=\(rest.count, privacy: .public) (answers \(input.choices.count, privacy: .public), wrong \(input.wrongTitles.count, privacy: .public), draft=\(drafts[input.number] != nil, privacy: .public))")
        }
        return result
    }

    /// Original titles that would still show memo notation after rewrites and model wrong choices.
    /// Model wrong choices replace memo wrong slots first (same order as QuizScreenModel.apply).
    private static func memoNotes(input: Input, refinement: QuizRefinement?) -> [String] {
        let rewrites = refinement?.rewrites ?? [:]
        var notes = input.choices.filter { QuizQuestionRefiner.isMemo(rewrites[$0] ?? $0) }
        let memoWrong = input.wrongTitles.filter { QuizQuestionRefiner.isMemo(rewrites[$0] ?? $0) }
        notes += memoWrong.dropFirst(refinement?.wrong?.count ?? 0)
        return notes
    }

    /// One short request rewriting only the leftover notes. Returns text by index; empty on failure/timeout.
    @MainActor
    private static func rewriteNotes(_ notes: [(path: String, text: String)], timeout: UInt64) async -> [Int: String] {
        do {
            let found = try await withThrowingTaskGroup(of: [Int: String]?.self) { group in
                group.addTask { @MainActor in
                    let session = LanguageModelSession(instructions: instructions)
                    let lines = notes.enumerated().map { "[\($0.offset)] 항목: \(String($0.element.path.prefix(60))) / 메모: \(String($0.element.text.prefix(80)))" }.joined(separator: "\n")
                    let prompt = """
                    아래 암기 메모를 각각 의미 그대로 실제 시험 보기처럼 자연스러운 단어(구) 또는 문장으로 다시 쓰세요. 기호(=>, →, <, >)는 쓰지 말고 숫자·법률 용어는 유지하며 새 사실은 만들지 마세요. 번호를 그대로 쓰세요.

                    \(lines)
                    """
                    let batch = try await session.respond(to: prompt, generating: GeneratedNoteBatch.self).content
                    var byId: [Int: String] = [:]
                    for item in batch.items { byId[item.id] = item.text }
                    return byId
                }
                group.addTask {
                    try await Task.sleep(nanoseconds: timeout * 1_000_000_000)
                    return nil
                }
                let first = try await group.next() ?? nil
                group.cancelAll()
                return first
            }
            if found == nil { quizLog.notice("FM second pass timed out") }
            return found ?? [:]
        } catch {
            quizLog.error("FM second pass error: \(String(describing: error), privacy: .public)")
            return [:]
        }
    }

    /// Validates each rewritten choice on its own; a rejected one keeps its original text.
    private static func rewrittenChoices(input: Input, draft: Draft) -> [String: String] {
        let drafts = draft.texts
        var finals = input.choices
        var result: [String: String] = [:]
        for (index, original) in input.choices.enumerated() where index < drafts.count {
            let others = finals.enumerated().filter { $0.offset != index }.map(\.element)
            guard let value = QuizQuestionRefiner.validatedRewrite(drafts[index], original: original, others: others) else { continue }
            finals[index] = value
            result[original] = value
        }
        return result
    }

    /// One request for the whole group; if the model fails (e.g. context window exceeded), retry as two halves.
    @MainActor
    private static func generateWithSplit(_ inputs: [Input], kind: Kind, timeout: UInt64) async -> [Int: Draft] {
        do {
            return try await withThrowingTaskGroup(of: [Int: Draft]?.self) { group in
                group.addTask { @MainActor in try await generate(inputs, kind: kind) }
                group.addTask {
                    try await Task.sleep(nanoseconds: timeout * 1_000_000_000)
                    return nil
                }
                let first = try await group.next() ?? nil
                group.cancelAll()
                guard let first else {
                    quizLog.notice("FM \(kind.rawValue, privacy: .public) timed out")
                    return [:]
                }
                return first
            }
        } catch {
            quizLog.error("FM \(kind.rawValue, privacy: .public) error (n=\(inputs.count, privacy: .public)): \(String(describing: error), privacy: .public)")
            guard inputs.count > 1, !Task.isCancelled else { return [:] }
            let mid = inputs.count / 2
            let left = await generateWithSplit(Array(inputs[..<mid]), kind: kind, timeout: timeout)
            let right = await generateWithSplit(Array(inputs[mid...]), kind: kind, timeout: timeout)
            return left.merging(right) { a, _ in a }
        }
    }

    private static let styleRule = "보기 문체 규칙: 원문은 암기용 요약 메모다. 뜻을 이해한 뒤 실제 시험 보기처럼 자연스러운 단어(구) 또는 문장으로 쓴다. 기호(=>, →, <, 괄호 등)는 남기지 않는다. 한 문제의 보기는 같은 형태. 숫자·법률 용어·기간·금액·비율은 유지, 새 사실 금지."
    private static let exampleRule = "예: \"미채굴 광물은 소유권이 없다 => 국가소유\" → \"미채굴 광물은 국가 소유이다\" (질문이 소유자를 물으면 \"국가\") / \"지상권\" → \"지상권\""

    @MainActor
    private static func generate(_ inputs: [Input], kind: Kind) async throws -> [Int: Draft] {
        let session = LanguageModelSession(instructions: instructions)
        var drafts: [Int: Draft] = [:]
        var empty = 0

        switch kind {
        case .positive:
            let blocks = inputs.map { input -> String in
                let members = input.children.map { "  - \($0)" }.joined(separator: "\n")
                return "[문제 \(input.number)] 긍정형(속하거나 알맞은 것 고르기)\n항목: \(input.path)\n실제로 속하는 내용(모두 참):\n\(members)\n정답 보기: \(input.correct)"
            }.joined(separator: "\n\n")
            let prompt = """
            아래 \(inputs.count)개 문제 각각에 대해 작성하세요. 번호를 그대로 쓰고 번호 순서대로 답하세요.
            - stem: 주제는 마지막 항목명 하나만 쓴다. 경로를 '속에서'·'중'·'의'로 이어 쓰지 않는다(나쁜 예: '부동산의 분류 속에서 기타 토지에 속하지 않는 것', 좋은 예: '다음 중 기타 토지에 속하지 않는 것은?'). 짧게, '?' 또는 '고르시오.'로 끝낸다. 보기 내용은 쓰지 않는다.
            - correct: '정답 보기'를 의미 그대로 다시 쓴 것.
            - wrong1~wrong4: 서로 다른 그럴듯한 오답 4개(복사 금지, 새로 만들고 correct와 같은 문체).
            - \(styleRule)
            - \(exampleRule)
            - 모든 필드를 반드시 채운다. 빈 문자열 금지.

            \(blocks)
            """
            let batch = try await session.respond(to: prompt, generating: GeneratedPositiveBatch.self).content
            for item in batch.items {
                let fields = [item.stem, item.correct, item.wrong1, item.wrong2, item.wrong3, item.wrong4]
                empty += fields.filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
                drafts[item.number] = Draft(stem: item.stem, texts: [item.correct], wrong: [item.wrong1, item.wrong2, item.wrong3, item.wrong4])
            }
            quizLog.notice("FM positive raw: items=\(batch.items.count, privacy: .public) emptyFields=\(empty, privacy: .public)/\(batch.items.count * 6, privacy: .public)")
        case .negative:
            let blocks = inputs.map { input -> String in
                let choices = input.choices.enumerated().map { "  보기\($0.offset + 1): \(String($0.element.prefix(80)))" }.joined(separator: "\n")
                return "[문제 \(input.number)] 부정형(속하지 않거나 알맞지 않은 것 고르기)\n항목: \(input.path)\n\(choices)"
            }.joined(separator: "\n\n")
            let prompt = """
            아래 \(inputs.count)개 문제 각각에 대해 작성하세요. 번호를 그대로 쓰고 번호 순서대로 답하세요.
            - stem: 주제는 마지막 항목명 하나만 쓴다. 경로를 '속에서'·'중'·'의'로 이어 쓰지 않는다(나쁜 예: '부동산의 분류 속에서 기타 토지에 속하지 않는 것', 좋은 예: '다음 중 기타 토지에 속하지 않는 것은?'). 짧게, '?' 또는 '고르시오.'로 끝낸다. 보기 내용은 쓰지 않는다.
            - choice1~choice5: 보기1~5를 각각 의미 그대로 다시 쓴 것.
            - \(styleRule)
            - \(exampleRule)
            - 모든 필드를 반드시 채운다. 빈 문자열 금지.

            \(blocks)
            """
            let batch = try await session.respond(to: prompt, generating: GeneratedNegativeBatch.self).content
            for item in batch.items {
                let texts = [item.choice1, item.choice2, item.choice3, item.choice4, item.choice5]
                empty += ([item.stem] + texts).filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
                drafts[item.number] = Draft(stem: item.stem, texts: texts, wrong: [])
            }
            quizLog.notice("FM negative raw: items=\(batch.items.count, privacy: .public) emptyFields=\(empty, privacy: .public)/\(batch.items.count * 6, privacy: .public)")
        }
        return drafts
    }
}
#endif
