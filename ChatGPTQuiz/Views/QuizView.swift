import SwiftUI

struct QuizView: View {
    @ObservedObject var viewModel: QuizViewModel
    @Binding var path: NavigationPath
    @State private var showingResults = false
    
    var body: some View {
        Group {
            if let quiz = viewModel.currentQuiz {
                VStack(spacing: 0) {
                    // Progress indicator
                    VStack(spacing: 8) {
                        Text("Question \(min(answeredCount + 1, quiz.totalQuestions)) of \(quiz.totalQuestions)")
                            .font(.bodyText)
                            .foregroundColor(.secondaryText)
                        
                        ProgressView(value: Double(answeredCount), total: Double(quiz.totalQuestions))
                            .progressViewStyle(LinearProgressViewStyle(tint: .accentBlue))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                    }
                    .padding()
                    .background(Color.deepCharcoal)
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 32) {
                                ForEach(quiz.questions) { question in
                                    QuestionCard(
                                        question: question,
                                        onSelect: { index in
                                            viewModel.selectAnswer(for: question, choiceIndex: index)
                                            // Auto-scroll to show the button when quiz is complete
                                            if quiz.isComplete {
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    withAnimation(.easeInOut(duration: 0.5)) {
                                                        proxy.scrollTo("viewResultsButton", anchor: .bottom)
                                                    }
                                                }
                                            }
                                        }
                                    )
                                    .id(question.id)
                                }
                                
                                // Add extra spacing before the button appears
                                if quiz.isComplete {
                                    Spacer(minLength: 120)
                                        .frame(height: 120)
                                        .id("viewResultsButton")
                                }
                            }
                            .padding()
                        }
                    }
                    .background(Color.deepCharcoal)
                    
                    if quiz.isComplete {
                        VStack {
                            PrimaryButton("View Results") {
                                showingResults = true
                            }
                        }
                        .padding()
                        .background(Color.deepCharcoal)
                    }
                }
                .navigationTitle("Quiz: \(quiz.subject)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Color.deepCharcoal, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .navigationDestination(isPresented: $showingResults) {
                    ResultsView(viewModel: viewModel, path: $path)
                }
            } else {
                Text("No quiz available")
                    .font(.bodyText)
                    .foregroundColor(.secondaryText)
            }
        }
        .background(Color.deepCharcoal)
    }
    
    private var answeredCount: Int {
        viewModel.currentQuiz?.questions.filter { $0.userSelectedIndex != nil }.count ?? 0
    }
}

struct QuestionCard: View {
    let question: Question
    let onSelect: (Int) -> Void
    
    var body: some View {
        QuizCard {
            VStack(alignment: .leading, spacing: 20) {
                Text(question.question)
                    .font(.subheadingBold)
                    .foregroundColor(.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                
                VStack(spacing: 12) {
                    ForEach(question.choices.indices, id: \.self) { index in
                        AnswerButton(
                            text: question.choices[index],
                            isSelected: question.userSelectedIndex == index,
                            isCorrect: nil
                        ) {
                            onSelect(index)
                        }
                    }
                }
            }
        }
    }
} 
