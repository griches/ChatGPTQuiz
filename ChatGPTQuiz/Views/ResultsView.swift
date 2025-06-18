import SwiftUI

struct ResultsView: View {
    @ObservedObject var viewModel: QuizViewModel
    @Binding var path: NavigationPath
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let quiz = viewModel.currentQuiz {
                    // Score Summary
                    VStack(spacing: 8) {
                        Text("Quiz Results")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("\(quiz.score) out of \(quiz.totalQuestions) correct")
                            .font(.title2)
                        
                        Text("\(Int((Double(quiz.score) / Double(quiz.totalQuestions)) * 100))%")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor(score: Double(quiz.score) / Double(quiz.totalQuestions)))
                    }
                    .padding()
                    
                    // Incorrect Answers
                    if quiz.score < quiz.totalQuestions {
                        Text("Incorrect Answers")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top)
                        
                        ForEach(quiz.questions.filter { $0.userSelectedIndex != $0.correctAnswerIndex }) { question in
                            IncorrectAnswerView(question: question)
                        }
                    }
                }
                
                Button(action: {
                    viewModel.resetQuiz()
                    path.removeLast(path.count)
                }) {
                    Text("Try Another Quiz")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .padding()
        }
        .navigationTitle("Results")
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.completeQuiz()
        }
    }
    
    private func scoreColor(score: Double) -> Color {
        switch score {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .yellow
        default:
            return .red
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