import Foundation

struct Question: Identifiable, Codable {
    let id: UUID
    let question: String
    var choices: [String]
    var correctAnswerIndex: Int
    var userSelectedIndex: Int?
    let explanation: String?
    
    init(id: UUID = UUID(), question: String, choices: [String], correctAnswerIndex: Int, explanation: String? = nil) {
        self.id = id
        self.question = question
        self.choices = choices
        self.correctAnswerIndex = correctAnswerIndex
        self.explanation = explanation
    }
}

struct Quiz: Identifiable, Codable {
    let id: UUID
    let subject: String
    var questions: [Question]
    var currentQuestionIndex: Int = 0
    
    var isComplete: Bool {
        questions.allSatisfy { $0.userSelectedIndex != nil }
    }
    
    var score: Int {
        questions.filter { $0.userSelectedIndex == $0.correctAnswerIndex }.count
    }
    
    var totalQuestions: Int {
        questions.count
    }
}

enum QuizError: Error {
    case invalidResponse
    case networkError
    case apiError(String)
} 