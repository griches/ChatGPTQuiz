import SwiftUI

struct QuizView: View {
    @ObservedObject var viewModel: QuizViewModel
    @Binding var path: NavigationPath
    @State private var showingResults = false
    @State private var showButton = false
    
    var body: some View {
        Group {
            if let quiz = viewModel.currentQuiz {
                GeometryReader { geometry in
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
                                                // Auto-scroll to bottom when quiz is complete
                                                // Add haptic feedback for answer selection
                                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                                impactFeedback.impactOccurred()
                                                
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                    if viewModel.currentQuiz?.isComplete == true {
                                                        // Trigger scroll and button animation simultaneously
                                                        withAnimation(.easeInOut(duration: 0.6)) {
                                                            showButton = true
                                                            if let lastQuestion = viewModel.currentQuiz?.questions.last {
                                                                proxy.scrollTo(lastQuestion.id, anchor: .bottom)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        )
                                        .id(question.id)
                                    }
                                }
                                .padding()
                                .padding(.bottom, showButton ? 80 : 0)
                            }
                        }
                        .background(Color.deepCharcoal)
                        
                        if showButton {
                            VStack {
                                PrimaryButton("View Results") {
                                    showingResults = true
                                }
                            }
                            .padding()
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                    }
                }
                .navigationTitle("Quiz: \(quiz.subject)")
                .navigationBarTitleDisplayMode(.inline)
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
        .onAppear {
            showButton = false
        }
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
