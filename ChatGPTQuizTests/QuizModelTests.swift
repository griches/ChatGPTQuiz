import XCTest
@testable import ChatGPTQuiz

final class QuizModelTests: XCTestCase {
    
    func testQuestionInitialization() {
        // Given
        let choices = ["Option A", "Option B", "Option C"]
        let correctIndex = 1
        
        // When
        let question = Question(question: "Test question?", choices: choices, correctAnswerIndex: correctIndex)
        
        // Then
        XCTAssertEqual(question.question, "Test question?")
        XCTAssertEqual(question.choices, choices)
        XCTAssertEqual(question.correctAnswerIndex, correctIndex)
        XCTAssertNil(question.userSelectedIndex)
        XCTAssertNotNil(question.id)
    }
    
    func testQuizInitialization() {
        // Given
        let subject = "Swift Programming"
        let questions = [
            Question(question: "What is Swift?", choices: ["Language", "Bird", "Car"], correctAnswerIndex: 0),
            Question(question: "What is iOS?", choices: ["Robot", "OS", "App"], correctAnswerIndex: 1)
        ]
        
        // When
        let quiz = Quiz(id: UUID(), subject: subject, questions: questions)
        
        // Then
        XCTAssertEqual(quiz.subject, subject)
        XCTAssertEqual(quiz.questions.count, 2)
        XCTAssertEqual(quiz.totalQuestions, 2)
        XCTAssertEqual(quiz.currentQuestionIndex, 0)
        XCTAssertFalse(quiz.isComplete)
        XCTAssertEqual(quiz.score, 0)
    }
    
    func testQuizIsCompleteWhenAllQuestionsAnswered() {
        // Given
        var quiz = Quiz(id: UUID(), subject: "Test", questions: [
            Question(question: "Q1?", choices: ["A", "B", "C"], correctAnswerIndex: 0),
            Question(question: "Q2?", choices: ["A", "B", "C"], correctAnswerIndex: 1)
        ])
        
        // When - Answer all questions
        quiz.questions[0].userSelectedIndex = 0
        quiz.questions[1].userSelectedIndex = 1
        
        // Then
        XCTAssertTrue(quiz.isComplete)
    }
    
    func testQuizIsNotCompleteWhenSomeQuestionsUnanswered() {
        // Given
        var quiz = Quiz(id: UUID(), subject: "Test", questions: [
            Question(question: "Q1?", choices: ["A", "B", "C"], correctAnswerIndex: 0),
            Question(question: "Q2?", choices: ["A", "B", "C"], correctAnswerIndex: 1)
        ])
        
        // When - Answer only first question
        quiz.questions[0].userSelectedIndex = 0
        
        // Then
        XCTAssertFalse(quiz.isComplete)
    }
    
    func testQuizScoreCalculation() {
        // Given
        var quiz = Quiz(id: UUID(), subject: "Test", questions: [
            Question(question: "Q1?", choices: ["A", "B", "C"], correctAnswerIndex: 0),
            Question(question: "Q2?", choices: ["A", "B", "C"], correctAnswerIndex: 1),
            Question(question: "Q3?", choices: ["A", "B", "C"], correctAnswerIndex: 2)
        ])
        
        // When - Answer 2 correctly, 1 incorrectly
        quiz.questions[0].userSelectedIndex = 0  // Correct
        quiz.questions[1].userSelectedIndex = 1  // Correct
        quiz.questions[2].userSelectedIndex = 0  // Incorrect (should be 2)
        
        // Then
        XCTAssertEqual(quiz.score, 2)
    }
    
    func testQuizScoreWhenNoQuestionsAnswered() {
        // Given
        let quiz = Quiz(id: UUID(), subject: "Test", questions: [
            Question(question: "Q1?", choices: ["A", "B", "C"], correctAnswerIndex: 0),
            Question(question: "Q2?", choices: ["A", "B", "C"], correctAnswerIndex: 1)
        ])
        
        // Then
        XCTAssertEqual(quiz.score, 0)
    }
    
    func testQuizScoreWhenAllAnswersCorrect() {
        // Given
        var quiz = Quiz(id: UUID(), subject: "Test", questions: [
            Question(question: "Q1?", choices: ["A", "B", "C"], correctAnswerIndex: 0),
            Question(question: "Q2?", choices: ["A", "B", "C"], correctAnswerIndex: 1)
        ])
        
        // When - Answer all correctly
        quiz.questions[0].userSelectedIndex = 0
        quiz.questions[1].userSelectedIndex = 1
        
        // Then
        XCTAssertEqual(quiz.score, 2)
    }
    
    func testQuizScoreWhenAllAnswersIncorrect() {
        // Given
        var quiz = Quiz(id: UUID(), subject: "Test", questions: [
            Question(question: "Q1?", choices: ["A", "B", "C"], correctAnswerIndex: 0),
            Question(question: "Q2?", choices: ["A", "B", "C"], correctAnswerIndex: 1)
        ])
        
        // When - Answer all incorrectly
        quiz.questions[0].userSelectedIndex = 1  // Should be 0
        quiz.questions[1].userSelectedIndex = 0  // Should be 1
        
        // Then
        XCTAssertEqual(quiz.score, 0)
    }
    
}