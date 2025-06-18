import Foundation
import SwiftUI
import Combine

@MainActor
class QuizViewModel: ObservableObject {
    @Published var subject: String = ""
    @Published var questionCount: Int = 10
    @Published var currentQuiz: Quiz?
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var shouldNavigateToQuiz: Bool = false
    @Published var previousQuizzes: [Quiz] = []
    
    private let chatGPTService: ChatGPTService
    
    init(apiKey: String) {
        self.chatGPTService = ChatGPTService(apiKey: apiKey)
        loadSavedPreferences()
        loadPreviousQuizzes()
    }
    
    private func loadSavedPreferences() {
        questionCount = UserDefaults.standard.integer(forKey: "lastQuestionCount")
        if questionCount == 0 {
            questionCount = 10 // Default value
        }
    }
    
    private func savePreferences() {
        UserDefaults.standard.set(questionCount, forKey: "lastQuestionCount")
    }
    
    private func loadPreviousQuizzes() {
        if let data = UserDefaults.standard.data(forKey: "previousQuizzes") {
            if let decoded = try? JSONDecoder().decode([Quiz].self, from: data) {
                previousQuizzes = decoded
            }
        }
    }
    
    private func savePreviousQuizzes() {
        if let data = try? JSONEncoder().encode(previousQuizzes) {
            UserDefaults.standard.set(data, forKey: "previousQuizzes")
        }
    }
    
    func generateQuiz() async {
        guard !subject.isEmpty else {
            error = "Please enter a subject"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            var quiz = try await chatGPTService.generateQuiz(
                subject: subject,
                questionCount: questionCount
            )
            // Shuffle choices for each question
            quiz.questions = quiz.questions.map { question in
                var q = question
                let zipped = Array(zip(q.choices, 0..<q.choices.count))
                let shuffled = zipped.shuffled()
                let newChoices = shuffled.map { $0.0 }
                let newCorrectIndex = shuffled.firstIndex(where: { $0.1 == q.correctAnswerIndex }) ?? 0
                q.choices = newChoices
                q.correctAnswerIndex = newCorrectIndex
                q.userSelectedIndex = nil // Clear any answers
                return q
            }
            currentQuiz = quiz
            // Save a fresh copy to previousQuizzes
            previousQuizzes.insert(quiz, at: 0)
            savePreviousQuizzes()
            shouldNavigateToQuiz = true
            savePreferences()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func selectAnswer(for question: Question, choiceIndex: Int) {
        guard var quiz = currentQuiz else { return }
        if let questionIndex = quiz.questions.firstIndex(where: { $0.id == question.id }) {
            quiz.questions[questionIndex].userSelectedIndex = choiceIndex
            currentQuiz = quiz
        }
    }
    
    func resetQuiz() {
        currentQuiz = nil
        error = nil
        subject = ""
    }
    
    func playPreviousQuiz(_ quiz: Quiz) {
        var freshQuiz = quiz
        freshQuiz.questions = quiz.questions.map { question in
            var freshQuestion = question
            freshQuestion.userSelectedIndex = nil
            return freshQuestion
        }
        freshQuiz.currentQuestionIndex = 0
        currentQuiz = freshQuiz
        shouldNavigateToQuiz = true
    }
    
    func deletePreviousQuiz(at offsets: IndexSet) {
        previousQuizzes.remove(atOffsets: offsets)
        savePreviousQuizzes()
    }
} 