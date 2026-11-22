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
    
    private var timer: Timer?
    @ObservationIgnored private var refinementTask: Task<Void, Never>?
    private let totalQuestions: Int = 10
    private let countdownDuration: Int = 60
    
    var currentQuestion: RNQuestionInfo? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    var progressText: String {
        "자동 생성 퀴즈 (\(currentIndex + 1)/\(questions.count))"
    }
    
    init(chapter: Chapter) {
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

    /// Upgrades rule-based questions with Foundation Models output in the background.
    /// The quiz never waits for it: a question is only touched while it has not been shown yet,
    /// and any failure leaves the rule-based question as is.
    private func startRefinement() {
        aiStatus = QuizQuestionRefiner.status
        guard aiStatus == .ready || aiStatus == .preparing else {
            quizLog.notice("Refinement not started: FM unavailable (\(String(describing: self.aiStatus), privacy: .public)), using rule-based questions")
            return
        }
        let targets = questions

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
                return
            }
            quizLog.notice("Refinement started for \(targets.count, privacy: .public) questions (model \(ObjectIdentifier(self).hashValue, privacy: .public))")
            // One model request for all questions; apply whatever validated results come back.
            let results = await QuizQuestionRefiner.refinements(for: targets)
            if Task.isCancelled { return }
            for (index, refinement) in results.sorted(by: { $0.key < $1.key }) {
                self.apply(refinement, to: targets[index])
            }
            quizLog.notice("Refinement finished: \(results.count, privacy: .public)/\(targets.count, privacy: .public) applied")
        }
    }

    private func apply(_ refinement: QuizRefinement, to question: RNQuestionInfo) {
        // Skip questions already on screen or answered. Before the quiz starts (e.g. while the
        // pre-quiz ad is showing) the first question is still untouched and may be refined.
        guard let index = questions.firstIndex(where: { $0 === question }),
              index > currentIndex || (index == currentIndex && !isQuizActive && !isQuizComplete) else {
            quizLog.notice("Refinement dropped: question already shown (current=\(self.currentIndex, privacy: .public))")
            return
        }

        if let newWrong = refinement.wrong {
            // Model-written wrong choices first; any missing slot keeps its rule-based wrong choice.
            let slots = question.answers.filter { !$0.isCorrect }
            let kept = slots.map(\.title).filter { old in !newWrong.contains(old) }
            let titles = newWrong + kept
            for (slot, title) in zip(slots, titles) {
                slot.title = title
            }
        }
        question.generatedStem = refinement.stem
        quizLog.notice("Refinement applied to question \(index, privacy: .public)")
    }
    
    func startQuiz() {
        guard !questions.isEmpty else { return }
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
            // Load next question
            startCountdown()
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
    }
    
    deinit {
        cleanup()
    }
}
