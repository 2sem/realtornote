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
    /// Natural Korean question stem that contains the topic.
    let stem: String
    /// Validated model-written wrong choices (0...4). nil for negative questions, whose wrong choices are real items.
    /// Missing ones are filled from the rule-based question by the caller.
    let wrong: [String]?
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
        let value = stem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.count <= 120, isKorean(value) else { return false }
        // The stem must not leak the answer.
        let answer = normalized(correct)
        if answer.count >= 4 && normalized(value).contains(answer) { return false }
        return true
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
private struct GeneratedItem {
    @Guide(description: "문제 번호. 입력에서 받은 번호를 그대로 쓴다.")
    var number: Int

    @Guide(description: "항목의 주제를 문장 안에 자연스럽게 넣은 시험 문제 질문 문장 한 개. 예: '다음 중 ○○에 관한 설명으로 옳은 것은?'. 반드시 물음표(?)로 끝나는 완결된 문장. 한국어. 〉 같은 경로 표기와 보기·정답 내용은 쓰지 않는다.")
    var stem: String

    // Four separate fields (not an array) so the model writes four different wrong choices.
    @Guide(description: "오답 1: 정답의 핵심 단어나 수치 하나를 바꿔 틀리게 만든 보기. 정답과 달라야 한다. 한국어.")
    var wrong1: String

    @Guide(description: "오답 2: 정답과 반대되는 의미의 보기. 한국어.")
    var wrong2: String

    @Guide(description: "오답 3: 같은 상위 주제의 다른 개념에 해당하는 보기. 한국어.")
    var wrong3: String

    @Guide(description: "오답 4: 대상이나 범위를 바꿔 틀리게 만든 보기. 한국어.")
    var wrong4: String

    var wrong: [String] { [wrong1, wrong2, wrong3, wrong4] }
}

@available(iOS 26.0, *)
@Generable
private struct GeneratedBatch {
    @Guide(description: "입력된 문제 수와 같은 개수, 번호 순서대로.")
    var items: [GeneratedItem]
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
    }

    @MainActor
    static func refinements(for questions: [RNQuestionInfo], timeout: UInt64, distractorCount: Int) async -> [Int: QuizRefinement] {
        guard isAvailable else { return [:] }

        var inputs: [Input] = []
        for (offset, question) in questions.enumerated() {
            guard let reference = question.reference,
                  let correct = question.answers.first(where: { $0.isCorrect })?.title,
                  !correct.isEmpty else { continue }
            // Kept short: ten questions share one context window.
            inputs.append(Input(number: offset + 1,
                                path: question.text,
                                children: reference.children.prefix(5).map { String($0.text.prefix(50)) },
                                correct: String(correct.prefix(80)),
                                positive: question.positive))
        }
        guard !inputs.isEmpty else { return [:] }

        quizLog.notice("FM batch request start count=\(inputs.count, privacy: .public)")
        let started = Date()
        let drafts = await generateWithSplit(inputs, timeout: timeout)
        quizLog.notice("FM batch done in \(Date().timeIntervalSince(started), privacy: .public)s, drafts=\(drafts.count, privacy: .public)")

        var result: [Int: QuizRefinement] = [:]
        for input in inputs {
            guard let draft = drafts[input.number] else { continue }
            guard let draftStem = QuizQuestionRefiner.cleanedStem(draft.stem),
                  QuizQuestionRefiner.isValidStem(draftStem, correct: input.correct) else {
                quizLog.notice("FM rejected #\(input.number, privacy: .public): invalid stem=\(draft.stem, privacy: .public)")
                continue
            }
            let stem = draftStem.trimmingCharacters(in: .whitespacesAndNewlines)
            if input.positive {
                let wrong = QuizQuestionRefiner.sanitizedWrong(draft.wrong, trueItems: input.children, correct: input.correct, limit: distractorCount)
                quizLog.notice("FM #\(input.number, privacy: .public) usable wrong \(wrong.count, privacy: .public)/\(draft.wrong.count, privacy: .public)")
                if wrong.count < draft.wrong.count {
                    quizLog.notice("FM #\(input.number, privacy: .public) raw wrong=\(draft.wrong.joined(separator: " | "), privacy: .public) true=\(input.children.joined(separator: " | "), privacy: .public)")
                }
                result[input.number - 1] = QuizRefinement(stem: stem, wrong: wrong)
            } else {
                result[input.number - 1] = QuizRefinement(stem: stem, wrong: nil)
            }
        }
        return result
    }

    /// One request for the whole batch; if the model fails (e.g. context window exceeded), retry as two halves.
    @MainActor
    private static func generateWithSplit(_ inputs: [Input], timeout: UInt64) async -> [Int: GeneratedItem] {
        do {
            return try await withThrowingTaskGroup(of: [Int: GeneratedItem]?.self) { group in
                group.addTask { @MainActor in try await generate(inputs) }
                group.addTask {
                    try await Task.sleep(nanoseconds: timeout * 1_000_000_000)
                    return nil
                }
                let first = try await group.next() ?? nil
                group.cancelAll()
                guard let first else {
                    quizLog.notice("FM batch timed out")
                    return [:]
                }
                return first
            }
        } catch {
            quizLog.error("FM batch error (n=\(inputs.count, privacy: .public)): \(String(describing: error), privacy: .public)")
            guard inputs.count > 1, !Task.isCancelled else { return [:] }
            let mid = inputs.count / 2
            let left = await generateWithSplit(Array(inputs[..<mid]), timeout: timeout)
            let right = await generateWithSplit(Array(inputs[mid...]), timeout: timeout)
            return left.merging(right) { a, _ in a }
        }
    }

    @MainActor
    private static func generate(_ inputs: [Input]) async throws -> [Int: GeneratedItem] {
        let session = LanguageModelSession(instructions: instructions)
        let blocks = inputs.map { input -> String in
            let kind = input.positive ? "긍정형(속하거나 알맞은 것 고르기)" : "부정형(속하지 않거나 알맞지 않은 것 고르기)"
            let members = input.children.map { "  - \($0)" }.joined(separator: "\n")
            var block = "[문제 \(input.number)] \(kind)\n항목: \(input.path)\n실제로 속하는 내용(모두 참):\n\(members)"
            if input.positive { block += "\n정답 보기: \(input.correct)" }
            return block
        }.joined(separator: "\n\n")

        let prompt = """
        아래 \(inputs.count)개 문제 각각에 대해 작성하세요. 번호를 그대로 쓰고 번호 순서대로 답하세요.
        - stem: 항목의 주제(마지막 항목명)를 문장에 포함한 완결된 질문 문장. 문제 유형에 맞게 쓰고, 경로 표기(〉)와 보기 내용은 쓰지 않는다.
        - wrong1~wrong4: 서로 다른 그럴듯한 오답 4개. '실제로 속하는 내용'이나 정답을 복사하지 말고 새로 만든다. (부정형 문제는 아무 오답으로 채워도 된다)

        \(blocks)
        """
        let batch = try await session.respond(to: prompt, generating: GeneratedBatch.self).content
        var byNumber: [Int: GeneratedItem] = [:]
        for item in batch.items { byNumber[item.number] = item }
        return byNumber
    }
}
#endif
