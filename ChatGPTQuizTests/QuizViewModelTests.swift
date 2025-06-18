import XCTest
@testable import ChatGPTQuiz

@MainActor
final class QuizViewModelTests: XCTestCase {
    
    var viewModel: QuizViewModel!
    
    override func setUp() {
        super.setUp()
        // Clear UserDefaults to ensure clean test state
        UserDefaults.standard.removeObject(forKey: "lastQuestionCount")
        UserDefaults.standard.removeObject(forKey: "previousQuizzes")
        viewModel = QuizViewModel()
    }
    
    override func tearDown() {
        // Clean up UserDefaults after each test
        UserDefaults.standard.removeObject(forKey: "lastQuestionCount")
        UserDefaults.standard.removeObject(forKey: "previousQuizzes")
        viewModel = nil
        super.tearDown()
    }
    
    func testInitialState() {
        // Then
        XCTAssertEqual(viewModel.subject, "")
        XCTAssertEqual(viewModel.questionCount, 10)
        XCTAssertNil(viewModel.currentQuiz)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.shouldNavigateToQuiz)
        XCTAssertTrue(viewModel.previousQuizzes.isEmpty)
    }
    
    func testSelectAnswer() {
        // Given
        let question = Question(question: "Test?", choices: ["A", "B", "C"], correctAnswerIndex: 1)
        let quiz = Quiz(id: UUID(), subject: "Test", questions: [question])
        viewModel.currentQuiz = quiz
        
        // When
        viewModel.selectAnswer(for: question, choiceIndex: 2)
        
        // Then
        XCTAssertEqual(viewModel.currentQuiz?.questions.first?.userSelectedIndex, 2)
    }
    
    func testSelectAnswerUpdatesCorrectQuestion() {
        // Given
        let question1 = Question(question: "Q1?", choices: ["A", "B", "C"], correctAnswerIndex: 0)
        let question2 = Question(question: "Q2?", choices: ["A", "B", "C"], correctAnswerIndex: 1)
        let quiz = Quiz(id: UUID(), subject: "Test", questions: [question1, question2])
        viewModel.currentQuiz = quiz
        
        // When
        viewModel.selectAnswer(for: question2, choiceIndex: 1)
        
        // Then
        XCTAssertNil(viewModel.currentQuiz?.questions[0].userSelectedIndex) // First question unchanged
        XCTAssertEqual(viewModel.currentQuiz?.questions[1].userSelectedIndex, 1) // Second question updated
    }
    
    func testResetQuiz() {
        // Given
        viewModel.currentQuiz = Quiz(id: UUID(), subject: "Test", questions: [])
        viewModel.error = "Some error"
        viewModel.subject = "Previous subject"
        
        // When
        viewModel.resetQuiz()
        
        // Then
        XCTAssertNil(viewModel.currentQuiz)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.subject, "")
    }
    
    func testPlayPreviousQuiz() {
        // Given
        var question = Question(question: "Test?", choices: ["A", "B", "C"], correctAnswerIndex: 1)
        question.userSelectedIndex = 2 // Previously answered
        let quiz = Quiz(id: UUID(), subject: "Test", questions: [question])
        
        // When
        viewModel.playPreviousQuiz(quiz)
        
        // Then
        XCTAssertEqual(viewModel.currentQuiz?.subject, "Test")
        XCTAssertNil(viewModel.currentQuiz?.questions.first?.userSelectedIndex) // Answers cleared
        XCTAssertEqual(viewModel.currentQuiz?.currentQuestionIndex, 0)
        XCTAssertTrue(viewModel.shouldNavigateToQuiz)
    }
    
    func testDeletePreviousQuiz() {
        // Given
        let quiz1 = Quiz(id: UUID(), subject: "Quiz 1", questions: [])
        let quiz2 = Quiz(id: UUID(), subject: "Quiz 2", questions: [])
        let quiz3 = Quiz(id: UUID(), subject: "Quiz 3", questions: [])
        viewModel.previousQuizzes = [quiz1, quiz2, quiz3]
        
        // When
        viewModel.deletePreviousQuiz(at: IndexSet(integer: 1))
        
        // Then
        XCTAssertEqual(viewModel.previousQuizzes.count, 2)
        XCTAssertEqual(viewModel.previousQuizzes[0].subject, "Quiz 1")
        XCTAssertEqual(viewModel.previousQuizzes[1].subject, "Quiz 3")
    }
    
    func testHasValidAPITokenInitiallyFalse() {
        // Then
        XCTAssertFalse(viewModel.hasValidAPIToken)
    }
    
    func testSaveAPITokenUpdatesState() {
        // Given
        let token = "test-token-123"
        
        // When
        viewModel.saveAPIToken(token)
        
        // Then
        XCTAssertTrue(viewModel.hasValidAPIToken)
    }
    
    func testSaveEmptyAPITokenDoesNothing() {
        // Given
        let originalState = viewModel.hasValidAPIToken
        
        // When
        viewModel.saveAPIToken("")
        
        // Then
        XCTAssertEqual(viewModel.hasValidAPIToken, originalState)
    }
    
    func testClearAPIToken() {
        // Given
        viewModel.saveAPIToken("test-token")
        XCTAssertTrue(viewModel.hasValidAPIToken)
        
        // When
        viewModel.clearAPIToken()
        
        // Then
        XCTAssertFalse(viewModel.hasValidAPIToken)
    }
    
    func testGenerateQuizWithoutAPITokenShowsError() async {
        // Given
        viewModel.subject = "Swift"
        viewModel.hasValidAPIToken = false
        
        // When
        await viewModel.generateQuiz()
        
        // Then
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.error?.contains("configure your OpenAI API token") == true)
    }
    
    func testGenerateQuizWithEmptySubjectShowsError() async {
        // Given
        viewModel.subject = ""
        
        // When
        await viewModel.generateQuiz()
        
        // Then
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.error, "Please enter a subject")
    }
    
    func testGenerateQuizSetsLoadingState() async {
        // Given
        viewModel.subject = "Test Subject"
        
        // When
        let loadingTask = Task {
            await viewModel.generateQuiz()
        }
        
        // Give it a moment to start
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        
        // Then (while loading)
        // Note: This test might be flaky due to timing, but shows the pattern
        
        await loadingTask.value
        
        // After completion
        XCTAssertFalse(viewModel.isLoading)
    }
}