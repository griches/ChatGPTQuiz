import SwiftUI

struct QuizView: View {
    @ObservedObject var viewModel: QuizViewModel
    @Binding var path: NavigationPath
    @State private var showingResults = false
    @State private var showButton = false
    @State private var questionOffsets: [UUID: CGFloat] = [:]
    @State private var questionOpacities: [UUID: Double] = [:]
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Group {
            if let quiz = viewModel.currentQuiz {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // Progress indicator
                        VStack(spacing: 12) {
                            Text("Question \(min(answeredCount + 1, quiz.totalQuestions)) of \(quiz.totalQuestions)")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            ProgressBar(
                                value: Double(answeredCount),
                                total: Double(quiz.totalQuestions),
                                accentColor: themeManager.currentTheme.accentColor
                            )
                        }
                        .padding()
                        .background(
                            themeManager.currentTheme.cardBackground
                                .overlay(
                                    LinearGradient(
                                        colors: [themeManager.currentTheme.accentColor.opacity(0.2), Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(spacing: 32) {
                                    ForEach(Array(quiz.questions.enumerated()), id: \.element.id) { index, question in
                                        AnimatedQuestionCard(
                                            question: question,
                                            index: index,
                                            accentColor: themeManager.currentTheme.accentColor,
                                            onSelect: { selectedIndex in
                                                viewModel.selectAnswer(for: question, choiceIndex: selectedIndex)
                                                // Auto-scroll to bottom when quiz is complete
                                                // Add haptic feedback for answer selection
                                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                                impactFeedback.impactOccurred()
                                                
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                    if viewModel.currentQuiz?.isComplete == true {
                                                        // Show button first
                                                        withAnimation(.easeInOut(duration: 0.3)) {
                                                            showButton = true
                                                        }
                                                        // Then scroll to it
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                                            withAnimation(.easeInOut(duration: 0.6)) {
                                                                proxy.scrollTo("viewResultsButton", anchor: .bottom)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        )
                                        .id(question.id)
                                        .offset(x: questionOffsets[question.id] ?? 50)
                                        .opacity(questionOpacities[question.id] ?? 0)
                                        .onAppear {
                                            withAnimation(
                                                .spring(response: 0.6, dampingFraction: 0.8)
                                                .delay(Double(index) * 0.1)
                                            ) {
                                                questionOffsets[question.id] = 0
                                                questionOpacities[question.id] = 1
                                            }
                                        }
                                    }
                                    
                                    if showButton {
                                        AnimatedPrimaryButton(
                                            title: "View Results",
                                            isLoading: false,
                                            accentColor: themeManager.currentTheme.accentColor
                                        ) {
                                            showingResults = true
                                        }
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .bottom).combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                        .id("viewResultsButton")
                                    }
                                }
                                .padding()
                            }
                        }
                        .background(Color.clear)
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
        .background(Color.clear)
        .onAppear {
            showButton = false
        }
    }
    
    private var answeredCount: Int {
        viewModel.currentQuiz?.questions.filter { $0.userSelectedIndex != nil }.count ?? 0
    }
}

struct AnimatedQuestionCard: View {
    let question: Question
    let index: Int
    let accentColor: Color
    let onSelect: (Int) -> Void
    @State private var showParticles = false
    @State private var cardRotation: Double = 0
    @State private var showResults = false
    
    var body: some View {
        ZStack {
            cardContent
            .rotation3DEffect(
                .degrees(cardRotation),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.5
            )
            
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(Double(index) * 0.1)) {
                cardRotation = 0
            }
        }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(question.question)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
            }
            
            VStack(spacing: 12) {
                ForEach(question.choices.indices, id: \.self) { choiceIndex in
                    AnimatedAnswerButton(
                        text: question.choices[choiceIndex],
                        isSelected: question.userSelectedIndex == choiceIndex,
                        isCorrect: nil,
                        accentColor: accentColor,
                        delay: Double(choiceIndex) * 0.05
                    ) {
                        selectAnswer(choiceIndex)
                    }
                }
            }
        }
        .padding(24)
        .glassmorphic()
    }
    
    private func selectAnswer(_ choiceIndex: Int) {
        onSelect(choiceIndex)
        
    }
}

struct ProgressBar: View {
    let value: Double
    let total: Double
    let accentColor: Color
    @State private var animatedValue: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * (animatedValue / total), height: 8)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animatedValue)
            }
        }
        .frame(height: 8)
        .onChange(of: value) { _, newValue in
            animatedValue = newValue
        }
        .onAppear {
            animatedValue = value
        }
    }
}

struct AnimatedAnswerButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool?
    let accentColor: Color
    let delay: Double
    let action: () -> Void
    
    @State private var scale: CGFloat = 0.9
    @State private var opacity: Double = 0
    
    var backgroundColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? Color.green.opacity(0.2) : Color.red.opacity(0.2)
        }
        return isSelected ? accentColor.opacity(0.2) : Color.white.opacity(0.1)
    }
    
    var borderColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? .green : .red
        }
        return isSelected ? accentColor : Color.white.opacity(0.3)
    }
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                Text(text)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let isCorrect = isCorrect {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isCorrect ? .green : .red)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(16)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(
                .spring(response: 0.5, dampingFraction: 0.7)
                .delay(delay)
            ) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
} 
