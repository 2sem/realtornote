//
//  QuizScreen.swift
//  realtornote
//
//  Created for SwiftUI migration
//

import SwiftUI
import SwiftData

struct QuizScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel: QuizScreenModel
    
    init(chapter: Chapter) {
        _viewModel = State(initialValue: QuizScreenModel(chapter: chapter))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background adapts to dark/light mode
                backgroundColor
                    .ignoresSafeArea()
                
                if viewModel.questions.isEmpty {
                    emptyState
                } else if let question = viewModel.currentQuestion {
                    ZStack {
                        quizContent(question: question)

                        // Show results overlay on last question when complete
                        if viewModel.isQuizComplete {
                            resultsOverlay
                        }
                    }
                }
            }
            .navigationTitle(viewModel.progressText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .toolbarBackground(.automatic, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .onAppear {
                if !viewModel.isQuizActive && !viewModel.isQuizComplete {
                    viewModel.startQuiz()
                }
            }
            .onDisappear {
                viewModel.cleanup()
            }
        }
    }
    
    private var backgroundColor: Color {
        Color(red: 0.506, green: 0.831, blue: 0.980)
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color.white
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.8))

            Text("문제생성 실패")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("문제 생성을 위한 데이터가 충분하지 않습니다")
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var resultsOverlay: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text("퀴즈 완료!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
            }

            VStack(spacing: 16) {
                HStack(spacing: 40) {
                    VStack(spacing: 4) {
                        Text("\(viewModel.correctCount)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.green)
                        Text("정답")
                            .font(.headline)
                            .foregroundColor(textColor.opacity(0.8))
                    }

                    VStack(spacing: 4) {
                        Text("\(viewModel.incorrectCount)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.red)
                        Text("오답")
                            .font(.headline)
                            .foregroundColor(textColor.opacity(0.8))
                    }
                }

                Text("총 \(viewModel.questions.count)문제")
                    .font(.subheadline)
                    .foregroundColor(textColor.opacity(0.6))
            }

            Text("광고 시청으로 재도전할 수 있습니다")
                .font(.body)
                .foregroundColor(textColor.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBackgroundColor)
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .padding(40)
    }
    
    private func quizContent(question: RNQuestionInfo) -> some View {
        VStack(spacing: 0) {
            // Question header card
            VStack(alignment: .leading, spacing: 16) {
                // Question title
                Text(question.title)
                    .font(.headline)
                    .foregroundColor(textColor)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Countdown timer
                if viewModel.isQuizActive && !viewModel.showCorrectAnswer {
                    HStack {
                        Spacer()
                        Text("\(viewModel.remainingSeconds)")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(viewModel.remainingSeconds <= 10 ? .red : timerColor)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                // Question text
                Text(question.text)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackgroundColor)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            .padding()
            
            // Answer options
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(question.answers.enumerated()), id: \.offset) { index, answer in
                        answerButton(answer: answer, index: index)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var timerColor: Color {
        colorScheme == .dark ? Color(red: 0.3, green: 0.7, blue: 1.0) : Color(red: 0.0, green: 0.5, blue: 0.9)
    }
    
    private func answerButton(answer: RNQuestionAnswerInfo, index: Int) -> some View {
        Button {
            viewModel.selectAnswer(at: index)
        } label: {
            HStack(spacing: 12) {
                // Number circle
                Text("\(index + 1)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(numberCircleColor(answer: answer, index: index))
                    .clipShape(Circle())
                
                // Answer text
                Text(answer.title)
                    .font(.body)
                    .foregroundColor(answerTextColor(answer: answer, index: index))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Checkmark for correct answer when revealed
                if viewModel.showCorrectAnswer && answer.isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                } else if viewModel.selectedAnswerIndex == index && !answer.isCorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                }
            }
            .padding(16)
            .background(answerBackground(answer: answer, index: index))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(answerBorderColor(answer: answer, index: index), lineWidth: 2)
            )
        }
        .disabled(viewModel.selectedAnswerIndex != nil)
    }
    
    private func numberCircleColor(answer: RNQuestionAnswerInfo, index: Int) -> Color {
        if viewModel.showCorrectAnswer && answer.isCorrect {
            return .green
        } else if viewModel.selectedAnswerIndex == index && !answer.isCorrect {
            return .red
        }
        return Color(red: 0.2, green: 0.6, blue: 0.9)
    }
    
    private func answerTextColor(answer: RNQuestionAnswerInfo, index: Int) -> Color {
        if viewModel.showCorrectAnswer && answer.isCorrect {
            return .green
        } else if viewModel.selectedAnswerIndex == index && !answer.isCorrect {
            return .red
        }
        return colorScheme == .dark ? .white : .black
    }
    
    private func answerBackground(answer: RNQuestionAnswerInfo, index: Int) -> Color {
        if viewModel.showCorrectAnswer && answer.isCorrect {
            return Color.green.opacity(colorScheme == .dark ? 0.2 : 0.1)
        } else if viewModel.selectedAnswerIndex == index && !answer.isCorrect {
            return Color.red.opacity(colorScheme == .dark ? 0.2 : 0.1)
        }
        return colorScheme == .dark ? Color(white: 0.15) : Color.white
    }
    
    private func answerBorderColor(answer: RNQuestionAnswerInfo, index: Int) -> Color {
        if viewModel.showCorrectAnswer && answer.isCorrect {
            return .green
        } else if viewModel.selectedAnswerIndex == index && !answer.isCorrect {
            return .red
        }
        return Color.clear
    }
}

#Preview {
    // Mock preview
    QuizScreen(chapter: Chapter(id: 1, seq: 1, name: "Test Chapter", subject: nil))
}


#Preview {
    // Mock preview
    QuizScreen(chapter: Chapter(id: 1, seq: 1, name: "Test Chapter", subject: nil))
}
