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
    /// Natural Korean question stem for the chosen paragraph.
    let stem: String
    /// Replacement wrong choices (4). nil for negative questions, whose wrong choices are real items.
    let distractors: [String]?
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
    private static let timeoutSeconds: UInt64 = 10
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

    /// Returns a validated refinement, or nil on unavailability, timeout, error or invalid output.
    @MainActor
    static func refinement(for question: RNQuestionInfo) async -> QuizRefinement? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return await FoundationModelsRefiner.refinement(for: question, timeout: timeoutSeconds, distractorCount: distractorCount)
        }
        #endif
        return nil
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

    /// `trueItems` are real members of the paragraph (including the correct answer); a distractor must not match them.
    static func validDistractors(_ raw: [String], trueItems: [String], count: Int) -> [String]? {
        let blocked = trueItems.map(normalized).filter { !$0.isEmpty }
        var result: [String] = []
        var seen = Set<String>()

        for item in raw {
            let title = item.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = normalized(title)
            guard !key.isEmpty, isKorean(title), title.count <= 200 else { return nil }
            guard seen.insert(key).inserted else { return nil }
            // Reject equal / containing / contained-in a true item.
            for true_ in blocked where key == true_ || key.contains(true_) || (key.count >= 4 && true_.contains(key)) {
                return nil
            }
            result.append(title)
        }

        return result.count == count ? result : nil
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
private struct GeneratedStem {
    @Guide(description: "시험 문제의 질문 문장 한 개. 한국어. 보기나 정답 내용을 포함하지 않는다.")
    var stem: String
}

@available(iOS 26.0, *)
@Generable
private struct GeneratedQuestion {
    @Guide(description: "시험 문제의 질문 문장 한 개. 한국어. 보기나 정답 내용을 포함하지 않는다.")
    var stem: String

    @Guide(description: "정답과 같은 주제의 그럴듯하지만 질문에는 해당하지 않는 오답 보기 4개. 한국어.", .count(4))
    var distractors: [String]
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

    @MainActor
    static func refinement(for question: RNQuestionInfo, timeout: UInt64, distractorCount: Int) async -> QuizRefinement? {
        guard isAvailable,
              let reference = question.reference,
              let correct = question.answers.first(where: { $0.isCorrect })?.title,
              !correct.isEmpty else {
            quizLog.notice("FM skip: unavailable or question has no reference/correct answer")
            return nil
        }

        let path = question.text
        let childTexts = reference.children.prefix(8).map { String($0.text.prefix(120)) }
        let positive = question.positive
        quizLog.notice("FM request start positive=\(positive, privacy: .public) path=\(path, privacy: .public)")
        let started = Date()

        do {
            return try await withThrowingTaskGroup(of: QuizRefinement?.self) { group in
                group.addTask { @MainActor in
                    try await generate(path: path, children: childTexts, correct: correct, positive: positive, distractorCount: distractorCount)
                }
                group.addTask {
                    try await Task.sleep(nanoseconds: timeout * 1_000_000_000)
                    return nil
                }
                let first = try await group.next() ?? nil
                group.cancelAll()
                let secs = Date().timeIntervalSince(started)
                if first == nil {
                    quizLog.notice("FM request returned nil after \(secs, privacy: .public)s (timeout or invalid output)")
                } else {
                    quizLog.notice("FM request ok in \(secs, privacy: .public)s")
                }
                return first
            }
        } catch {
            quizLog.error("FM request error: \(String(describing: error), privacy: .public)")
            return nil
        }
    }

    @MainActor
    private static func generate(path: String, children: [String], correct: String, positive: Bool, distractorCount: Int) async throws -> QuizRefinement? {
        let session = LanguageModelSession(instructions: instructions)
        let kind = positive
            ? "보기 중 아래 항목에 속하거나 알맞게 설명하는 것을 고르는 문제"
            : "보기 중 아래 항목에 속하지 않거나 알맞지 않은 것을 고르는 문제"
        let members = children.map { "- \($0)" }.joined(separator: "\n")

        if positive {
            let prompt = """
            문제 유형: \(kind)
            항목(상위 〉 하위): \(path)
            이 항목에 실제로 속하는 내용(모두 참):
            \(members)
            정답 보기: \(correct)

            1) 질문 문장을 자연스러운 시험 문체로 한 개 작성하세요.
            2) 정답과 같은 주제·형식이지만 이 항목에는 속하지 않는 오답 보기 \(distractorCount)개를 작성하세요. \
            위 '실제로 속하는 내용'과 같거나 비슷한 것은 안 됩니다.
            """
            let draft = try await session.respond(to: prompt, generating: GeneratedQuestion.self).content
            let joined = draft.distractors.joined(separator: " | ")
            quizLog.notice("FM draft stem=\(draft.stem, privacy: .public) distractors=\(joined, privacy: .public)")
            guard QuizQuestionRefiner.isValidStem(draft.stem, correct: correct) else {
                quizLog.notice("FM rejected: invalid stem")
                return nil
            }
            guard let distractors = QuizQuestionRefiner.validDistractors(draft.distractors, trueItems: children + [correct], count: distractorCount) else {
                quizLog.notice("FM rejected: invalid distractors")
                return nil
            }
            return QuizRefinement(stem: draft.stem.trimmingCharacters(in: .whitespacesAndNewlines), distractors: distractors)
        } else {
            let prompt = """
            문제 유형: \(kind)
            항목(상위 〉 하위): \(path)
            이 항목에 실제로 속하는 내용(모두 참):
            \(members)

            질문 문장을 자연스러운 시험 문체로 한 개 작성하세요. 보기 내용은 포함하지 마세요.
            """
            let draft = try await session.respond(to: prompt, generating: GeneratedStem.self).content
            quizLog.notice("FM draft stem=\(draft.stem, privacy: .public)")
            guard QuizQuestionRefiner.isValidStem(draft.stem, correct: correct) else {
                quizLog.notice("FM rejected: invalid stem")
                return nil
            }
            return QuizRefinement(stem: draft.stem.trimmingCharacters(in: .whitespacesAndNewlines), distractors: nil)
        }
    }
}
#endif
