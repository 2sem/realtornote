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

    @Guide(description: "항목의 주제를 문장 안에 자연스럽게 넣은 시험 문제 질문 문장 한 개. 예: '다음 중 ○○에 관한 설명으로 옳은 것은?'. 한국어. 〉 같은 경로 표기와 보기·정답 내용은 쓰지 않는다.")
    var stem: String

    @Guide(description: "긍정형 문제는 그럴듯하지만 이 항목에는 해당하지 않는 오답 보기 4개, 부정형 문제는 빈 배열. 한국어.")
    var wrong: [String]
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
            guard QuizQuestionRefiner.isValidStem(draft.stem, correct: input.correct) else {
                quizLog.notice("FM rejected #\(input.number, privacy: .public): invalid stem=\(draft.stem, privacy: .public)")
                continue
            }
            let stem = draft.stem.trimmingCharacters(in: .whitespacesAndNewlines)
            if input.positive {
                let wrong = QuizQuestionRefiner.sanitizedWrong(draft.wrong, trueItems: input.children, correct: input.correct, limit: distractorCount)
                quizLog.notice("FM #\(input.number, privacy: .public) usable wrong \(wrong.count, privacy: .public)/\(draft.wrong.count, privacy: .public)")
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
        - wrong: 긍정형은 정답과 같은 주제·형식이지만 이 항목에는 속하지 않는 오답 4개('실제로 속하는 내용'을 그대로 쓰면 안 됨). 부정형은 빈 배열.

        \(blocks)
        """
        let batch = try await session.respond(to: prompt, generating: GeneratedBatch.self).content
        var byNumber: [Int: GeneratedItem] = [:]
        for item in batch.items { byNumber[item.number] = item }
        return byNumber
    }
}
#endif
