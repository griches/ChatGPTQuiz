import SwiftUI

struct QuizView: View {
    @ObservedObject var viewModel: QuizViewModel
    @Binding var path: NavigationPath
    @State private var showingResults = false
    
    var body: some View {
        Group {
            if let quiz = viewModel.currentQuiz {
                VStack {
                    ScrollView {
                        VStack(spacing: 32) {
                            ForEach(quiz.questions) { question in
                                QuestionView(
                                    question: question,
                                    onSelect: { index in
                                        viewModel.selectAnswer(for: question, choiceIndex: index)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                    
                    if quiz.isComplete {
                        Button(action: {
                            showingResults = true
                        }) {
                            Text("View Results")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                }
                .navigationTitle("Quiz: \(quiz.subject)")
                .navigationDestination(isPresented: $showingResults) {
                    ResultsView(viewModel: viewModel, path: $path)
                }
            } else {
                Text("No quiz available")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct QuestionView: View {
    let question: Question
    let onSelect: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.question)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 4)
            
            ForEach(question.choices.indices, id: \.self) { index in
                Button(action: {
                    onSelect(index)
                }) {
                    HStack {
                        Text(question.choices[index])
                            .foregroundColor(.primary)
                        Spacer()
                        if question.userSelectedIndex == index {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(question.userSelectedIndex == index ? Color.accentColor.opacity(0.15) : Color(uiColor: .tertiarySystemBackground))
                    )
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(uiColor: .secondarySystemBackground)))
        .shadow(radius: 2)
    }
} 