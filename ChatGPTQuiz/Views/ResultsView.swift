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
    }
    
    @ViewBuilder
    private func scoreSummary(for quiz: Quiz) -> some View {
        VStack(spacing: 12) {
            Text("Quiz Results")
                .font(.titleBold)
                .foregroundColor(.primaryText)
            
            Text("\(quiz.score) out of \(quiz.totalQuestions) correct")
                .font(.subheadingBold)
                .foregroundColor(.secondaryText)
            
            Text("\(Int((Double(quiz.score) / Double(quiz.totalQuestions)) * 100))%")
                .font(.scoreText)
                .foregroundColor(scoreColor(score: Double(quiz.score) / Double(quiz.totalQuestions)))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
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
                                correctAnswer: question.choices[question.correctAnswerIndex],
                                explanation: question.explanation
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var tryAnotherQuizButton: some View {
        PrimaryButton("Try Another Quiz") {
            // Pop back to root by removing all items from path
            while !path.isEmpty {
                path.removeLast()
            }
            
            // Reset quiz after navigation animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewModel.resetQuiz()
            }
        }
    }
    
    private func scoreColor(score: Double) -> Color {
        switch score {
        case 0.8...1.0:
            return .correctGreen
        case 0.6..<0.8:
            return Color(.systemOrange)
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
                    .foregroundColor(.incorrectRed)
                Text("Your answer: \(question.choices[question.userSelectedIndex ?? 0])")
            }
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.correctGreen)
                Text("Correct answer: \(question.choices[question.correctAnswerIndex])")
            }
            
            if let explanation = question.explanation, !explanation.isEmpty {
                HStack(alignment: .top) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.accentBlue)
                    Text(explanation)
                        .font(.bodyText)
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding()
        .background(Color.textFieldBackground)
        .cornerRadius(8)
    }
} 