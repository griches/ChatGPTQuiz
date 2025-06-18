import SwiftUI

struct ResultsView: View {
    @ObservedObject var viewModel: QuizViewModel
    @Binding var path: NavigationPath
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                if let quiz = viewModel.currentQuiz {
                    scoreSummary(for: quiz)
                    incorrectAnswersSection(for: quiz)
                }
                tryAnotherQuizButton
            }
            .padding()
        }
        .background(Color.deepCharcoal)
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(Color.deepCharcoal, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    @ViewBuilder
    private func scoreSummary(for quiz: Quiz) -> some View {
        QuizCard {
            ScoreDisplay(score: quiz.score, total: quiz.totalQuestions)
        }
    }
    
    @ViewBuilder
    private func incorrectAnswersSection(for quiz: Quiz) -> some View {
        let wrongAnswers = quiz.questions.filter { $0.userSelectedIndex != $0.correctAnswerIndex }
        if !wrongAnswers.isEmpty {
            QuizCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Incorrect Answers")
                        .font(.subheadingBold)
                        .foregroundColor(.primaryText)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(wrongAnswers) { question in
                            IncorrectAnswerCard(
                                question: question.question,
                                userAnswer: question.choices[question.userSelectedIndex ?? 0],
                                correctAnswer: question.choices[question.correctAnswerIndex]
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var tryAnotherQuizButton: some View {
        PrimaryButton("Try Another Quiz") {
            viewModel.resetQuiz()
            path.removeLast(path.count)
        }
    }
    
    private func scoreColor(score: Double) -> Color {
        switch score {
        case 0.8...1.0:
            return .correctGreen
        case 0.6..<0.8:
            return .orange
        default:
            return .incorrectRed
        }
    }
}

struct IncorrectAnswerView: View {
    let question: Question
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.question)
                .font(.headline)
            
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text("Your answer: \(question.choices[question.userSelectedIndex ?? 0])")
            }
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Correct answer: \(question.choices[question.correctAnswerIndex])")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
} 