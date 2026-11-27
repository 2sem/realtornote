//
//  QuizScreenModel.swift
//  realtornote
//
//  Created for SwiftUI migration
//

import Foundation
import SwiftData
import Combine
import FirebaseAnalytics

@Observable
class QuizScreenModel {
    var questions: [RNQuestionInfo] = []
    var currentIndex: Int = 0
    var remainingSeconds: Int = 60
    var isQuizActive: Bool = false
    var isQuizComplete: Bool = false
    var canRestart: Bool = false
    var selectedAnswerIndex: Int? = nil
    var showCorrectAnswer: Bool = false
    var correctCount: Int = 0
    var incorrectCount: Int = 0
    /// Current AI generation status, shown as guidance in the quiz when AI can't be used yet.
    var aiStatus: QuizAIStatus = .unsupported
    /// True while the current question is still being generated and the user sees a loader instead of it.
    var isWaitingForQuestion: Bool = false
    /// Indices of questions whose AI generation is settled (refined, failed or timed out).
    private(set) var settledIndices: Set<Int> = []
    /// True while the progressive generation task may still settle more questions.
    private var isGenerating: Bool = false

    private var timer: Timer?
    @ObservationIgnored private var refinementTask: Task<Void, Never>?
    @ObservationIgnored private var waitTask: Task<Void, Never>?
    @ObservationIgnored private var waitStartedAt: Date?
    private let firstQuestionWaitSeconds: UInt64 = 15
    private let nextQuestionWaitSeconds: UInt64 = 5
    private let totalQuestions: Int = 10
    private let countdownDuration: Int = 60
    
    var currentQuestion: RNQuestionInfo? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    /// True when a loader should replace the question: while waiting, and before the quiz starts if Q1 is still pending.
    var showsLoader: Bool {
        isWaitingForQuestion || (!isQuizActive && !isQuizComplete && isPending(currentIndex))
    }

    var progressText: String {
        "자동 생성 퀴즈 (\(currentIndex + 1)/\(questions.count))"
    }
    
    init(chapter: Chapter) {
        // Start loading the on-device model before anything else; it overlaps with question building.
        QuizQuestionRefiner.prewarm()
        generateQuestions(from: chapter)
    }
    
    private func generateQuestions(from chapter: Chapter) {
        // Get all paragraphs from all parts in the chapter
        var allParagraphs: [LSDocumentRecognizer.LSDocumentParagraph] = []
        
        let sortedParts = (chapter.parts).sorted { $0.seq < $1.seq }
        for part in sortedParts {
            // Picks the content-tree JSON path or the legacy path per part — see ContentRendering.
            let paragraphs = ContentRendering.paragraphs(for: part.content)
            for paragraph in paragraphs {
                allParagraphs.append(paragraph)
                allParagraphs.append(contentsOf: paragraph.allParagraphs)
            }
        }
        
        // Generate 10 random questions
        self.questions = RNQuestionInfo.createQuestions(allParagraphs, count: totalQuestions)
        startRefinement()
    }

    /// Upgrades rule-based questions with Foundation Models output, one question at a time in display
    /// order, so the first question is usable as early as possible. A question is only touched while
    /// it has not been shown yet, and any failure leaves the rule-based question as is.
    private func startRefinement() {
        aiStatus = QuizQuestionRefiner.status
        guard aiStatus == .ready || aiStatus == .preparing else {
            quizLog.notice("Refinement not started: FM unavailable (\(String(describing: self.aiStatus), privacy: .public)), using rule-based questions")
            return
        }
        let targets = questions
        isGenerating = true

        refinementTask = Task { @MainActor [weak self] in
            // Model still downloading: re-check every 5s for up to 2 minutes, then give up.
            var attempts = 0
            while let current = self?.aiStatus, current == .preparing, attempts < 24 {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                if Task.isCancelled { return }
                attempts += 1
                self?.aiStatus = QuizQuestionRefiner.status
            }
            guard let self, self.aiStatus == .ready else {
                quizLog.notice("Refinement not started: model never became ready")
                self?.finishGeneration()
                return
            }
            quizLog.notice("Refinement started for \(targets.count, privacy: .public) questions (model \(ObjectIdentifier(self).hashValue, privacy: .public))")
            var applied = 0
            for (index, question) in targets.enumerated() {
                if Task.isCancelled { return }
                if let refinement = await QuizQuestionRefiner.refinement(for: question, number: index + 1) {
                    if Task.isCancelled { return }
                    self.apply(refinement, to: question)
                    applied += 1
                }
                self.settle(index)
            }
            quizLog.notice("Refinement finished: \(applied, privacy: .public)/\(targets.count, privacy: .public) applied")
            self.finishGeneration()
        }
    }

    /// Marks a question as done (refined, failed or timed out) and releases the loader if it was waiting on it.
    private func settle(_ index: Int) {
        settledIndices.insert(index)
        if isWaitingForQuestion && index == currentIndex {
            finishWaiting(timedOut: false)
        }
    }

    /// Generation is over: nothing else will change, so every question counts as settled.
    private func finishGeneration() {
        isGenerating = false
        settledIndices = Set(questions.indices)
        if isWaitingForQuestion { finishWaiting(timedOut: false) }
    }

    private func isPending(_ index: Int) -> Bool {
        isGenerating && !settledIndices.contains(index)
    }

    /// Shows the loader for the current question for at most `seconds`, then falls back to the rule-based text.
    private func beginWaiting(seconds: UInt64) {
        timer?.invalidate()
        selectedAnswerIndex = nil
        showCorrectAnswer = false
        isWaitingForQuestion = true
        waitStartedAt = Date()
        quizLog.notice("Loader shown for q#\(self.currentIndex + 1, privacy: .public) (cap \(seconds, privacy: .public)s)")
        waitTask?.cancel()
        waitTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: seconds * 1_000_000_000)
            if Task.isCancelled { return }
            self?.finishWaiting(timedOut: true)
        }
    }

    private func finishWaiting(timedOut: Bool) {
        guard isWaitingForQuestion else { return }
        waitTask?.cancel()
        waitTask = nil
        let duration = waitStartedAt.map { Date().timeIntervalSince($0) } ?? 0
        waitStartedAt = nil
        isWaitingForQuestion = false
        if timedOut {
            quizLog.notice("Loader timed out for q#\(self.currentIndex + 1, privacy: .public) after \(duration, privacy: .public)s, fallback to rule-based")
        } else {
            quizLog.notice("Loader hidden for q#\(self.currentIndex + 1, privacy: .public) after \(duration, privacy: .public)s")
        }
        isQuizActive = true
        startCountdown()
    }

    private func apply(_ refinement: QuizRefinement, to question: RNQuestionInfo) {
        // Skip questions already on screen or answered. Before the quiz starts (e.g. while the
        // pre-quiz ad is showing) the first question is still untouched and may be refined.
        guard let index = questions.firstIndex(where: { $0 === question }),
              index > currentIndex || (index == currentIndex && (isWaitingForQuestion || (!isQuizActive && !isQuizComplete))) else {
            quizLog.notice("Refinement dropped: question already shown (current=\(self.currentIndex, privacy: .public))")
            return
        }

        // Rewritten summary choices, matched by original title (answers are shuffled). isCorrect never changes.
        let rewrites = refinement.rewrites
        if !rewrites.isEmpty {
            let originals = question.answers.map(\.title)
            for (answer, original) in zip(question.answers, originals) {
                if let text = rewrites[original] { answer.title = text }
            }
        }

        if let newWrong = refinement.wrong, !newWrong.isEmpty {
            // Rewrites are already applied. Model-written wrong choices override only the slots they
            // fill, taking slots that still show memo notation first; unfilled slots keep their text.
            let slots = question.answers.filter { !$0.isCorrect }
            let ordered = slots.filter { QuizQuestionRefiner.isMemo($0.title) } + slots.filter { !QuizQuestionRefiner.isMemo($0.title) }
            for (slot, title) in zip(ordered, newWrong) {
                slot.title = title
            }
        }
        if let stem = refinement.stem {
            question.generatedStem = stem
        }
        quizLog.notice("Refinement applied to question \(index, privacy: .public)")
    }
    
    func startQuiz() {
        guard !questions.isEmpty, !isWaitingForQuestion else { return }
        // Wait (capped) for the AI version of the first question instead of showing the rule-based one.
        if isPending(currentIndex) {
            beginWaiting(seconds: firstQuestionWaitSeconds)
            return
        }
        isQuizActive = true
        startCountdown()
    }
    
    func startCountdown() {
        remainingSeconds = countdownDuration
        selectedAnswerIndex = nil
        showCorrectAnswer = false
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
            } else {
                // Time's up - show correct answer
                self.handleTimeout()
            }
        }
    }
    
    private func handleTimeout() {
        timer?.invalidate()
        showCorrectAnswer = true

        // Count as incorrect
        incorrectCount += 1

        // Auto-advance after 2 seconds (but not on last question)
        if currentIndex < questions.count - 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.nextQuestion()
            }
        } else {
            // Last question - show result after 2 seconds delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.isQuizComplete = true
                self?.isQuizActive = false
                self?.canRestart = true
                Analytics.logLeesamEvent(.finishQuiz, parameters: [:])
            }
        }
    }
    
    func selectAnswer(at index: Int) {
        guard selectedAnswerIndex == nil else { return }

        selectedAnswerIndex = index
        timer?.invalidate()
        showCorrectAnswer = true

        // Track score
        if let question = currentQuestion, index < question.answers.count {
            if question.answers[index].isCorrect {
                correctCount += 1
            } else {
                incorrectCount += 1
            }
        }

        // Auto-advance after 3 seconds (but not on last question)
        if currentIndex < questions.count - 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.nextQuestion()
            }
        } else {
            // Last question - show result after 3 seconds delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.isQuizComplete = true
                self?.isQuizActive = false
                self?.canRestart = true
                Analytics.logLeesamEvent(.finishQuiz, parameters: [:])
            }
        }
    }
    
    func nextQuestion() {
        currentIndex += 1

        if currentIndex < questions.count {
            // Load next question; if AI is still generating it, show a short loader first.
            if isPending(currentIndex) {
                beginWaiting(seconds: nextQuestionWaitSeconds)
            } else {
                startCountdown()
            }
        }
        // If currentIndex >= questions.count, quiz is already marked complete in selectAnswer/handleTimeout
    }
    
    func restartQuiz() {
        Analytics.logLeesamEvent(.restartQuiz, parameters: [:])
        currentIndex = 0
        isQuizComplete = false
        canRestart = false
        correctCount = 0
        incorrectCount = 0
        startQuiz()
    }
    
    func cleanup() {
        timer?.invalidate()
        timer = nil
        refinementTask?.cancel()
        refinementTask = nil
        waitTask?.cancel()
        waitTask = nil
    }
    
    deinit {
        cleanup()
    }
}
