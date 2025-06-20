import SwiftUI

struct ResultsView: View {
    @ObservedObject var viewModel: QuizViewModel
    @Binding var path: NavigationPath
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showScore = false
    @State private var showIncorrect = false
    @State private var showButton = false
    @State private var showConfetti = false
    @State private var floatingScores: [FloatingScoreItem] = []
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 32) {
                    if let quiz = viewModel.currentQuiz {
                        scoreSummary(for: quiz)
                            .scaleEffect(showScore ? 1 : 0.8)
                            .opacity(showScore ? 1 : 0)
                        incorrectAnswersSection(for: quiz)
                            .opacity(showIncorrect ? 1 : 0)
                            .offset(y: showIncorrect ? 0 : 20)
                    }
                    tryAnotherQuizButton
                        .opacity(showButton ? 1 : 0)
                        .offset(y: showButton ? 0 : 20)
                }
                .padding()
            }
            
            
        }
        .background(Color.clear)
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            animateAppearance()
        }
    }
    
    @ViewBuilder
    private func scoreSummary(for quiz: Quiz) -> some View {
        let scorePercentage = Double(quiz.score) / Double(quiz.totalQuestions)
        
        VStack(spacing: 20) {
            Text("Quiz Results")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [themeManager.currentTheme.accentColor, themeManager.currentTheme.accentColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            ProgressRing(progress: scorePercentage)
                .frame(width: 150, height: 150)
            
            Text("\(quiz.score) out of \(quiz.totalQuestions) correct")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    Text("\(quiz.score)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                VStack {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                    Text("\(quiz.totalQuestions - quiz.score)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .glassmorphic()
    }
    
    @ViewBuilder
    private func incorrectAnswersSection(for quiz: Quiz) -> some View {
        let wrongAnswers = quiz.questions.filter { $0.userSelectedIndex != $0.correctAnswerIndex }
        if !wrongAnswers.isEmpty {
            VStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Incorrect Answers")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
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
            .padding(24)
            .glassmorphic()
        }
    }
    
    private var tryAnotherQuizButton: some View {
        AnimatedPrimaryButton(
            title: "Try Another Quiz",
            isLoading: false,
            accentColor: themeManager.currentTheme.accentColor
        ) {
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
    
    private func animateAppearance() {
        guard viewModel.currentQuiz != nil else { return }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showScore = true
        }
        
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
            showIncorrect = true
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6)) {
            showButton = true
        }
    }
    
    private func createFloatingScores() {
        guard let quiz = viewModel.currentQuiz else { return }
        let points = Int(Double(quiz.score) / Double(quiz.totalQuestions) * 100)
        
        for i in 0..<5 {
            let item = FloatingScoreItem(
                points: points,
                position: CGPoint(
                    x: CGFloat.random(in: 100...300),
                    y: CGFloat.random(in: 200...400)
                )
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                floatingScores.append(item)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    floatingScores.removeAll { $0.id == item.id }
                }
            }
        }
    }
}

struct FloatingScoreItem: Identifiable {
    let id = UUID()
    let points: Int
    let position: CGPoint
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
