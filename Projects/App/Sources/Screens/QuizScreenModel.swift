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
    
    private var timer: Timer?
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
            let paragraphs = LSDocumentRecognizer.shared.recognize(doc: part.content)
            for paragraph in paragraphs {
                allParagraphs.append(paragraph)
                allParagraphs.append(contentsOf: paragraph.allParagraphs)
            }
        }
        
        // Generate 10 random questions
        self.questions = RNQuestionInfo.createQuestions(allParagraphs, count: totalQuestions)
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
    }
    
    deinit {
        cleanup()
    }
}
