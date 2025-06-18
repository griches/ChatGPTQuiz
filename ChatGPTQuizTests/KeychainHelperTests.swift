import XCTest
@testable import ChatGPTQuiz

final class KeychainHelperTests: XCTestCase {
    
    var keychainHelper: KeychainHelper!
    let testToken = "test-api-token-123"
    
    override func setUp() {
        super.setUp()
        keychainHelper = KeychainHelper.shared
        // Clean up any existing test data
        keychainHelper.delete()
    }
    
    override func tearDown() {
        // Clean up after each test
        keychainHelper.delete()
        keychainHelper = nil
        super.tearDown()
    }
    
    func testSaveAndRetrieveToken() {
        // When
        let saveResult = keychainHelper.save(testToken)
        let retrievedToken = keychainHelper.retrieve()
        
        // Then
        XCTAssertTrue(saveResult, "Should successfully save token")
        XCTAssertEqual(retrievedToken, testToken, "Retrieved token should match saved token")
    }
    
    func testSaveEmptyStringReturnsTrue() {
        // When
        let result = keychainHelper.save("")
        
        // Then
        XCTAssertTrue(result, "Should return true even for empty string")
    }
    
    func testRetrieveWhenNoTokenExists() {
        // When
        let retrievedToken = keychainHelper.retrieve()
        
        // Then
        XCTAssertNil(retrievedToken, "Should return nil when no token exists")
    }
    
    func testDeleteToken() {
        // Given
        _ = keychainHelper.save(testToken)
        XCTAssertNotNil(keychainHelper.retrieve(), "Token should exist before deletion")
        
        // When
        let deleteResult = keychainHelper.delete()
        let retrievedToken = keychainHelper.retrieve()
        
        // Then
        XCTAssertTrue(deleteResult, "Delete should return true")
        XCTAssertNil(retrievedToken, "Token should not exist after deletion")
    }
    
    func testDeleteWhenNoTokenExists() {
        // When
        let deleteResult = keychainHelper.delete()
        
        // Then
        XCTAssertTrue(deleteResult, "Delete should return true even when no token exists")
    }
    
    func testSaveOverwritesExistingToken() {
        // Given
        let firstToken = "first-token"
        let secondToken = "second-token"
        
        // When
        _ = keychainHelper.save(firstToken)
        _ = keychainHelper.save(secondToken)
        let retrievedToken = keychainHelper.retrieve()
        
        // Then
        XCTAssertEqual(retrievedToken, secondToken, "Second token should overwrite first")
    }
    
    func testSaveAndRetrieveSpecialCharacters() {
        // Given
        let specialToken = "sk-proj-!@#$%^&*()_+-=[]{}|;:,.<>?"
        
        // When
        let saveResult = keychainHelper.save(specialToken)
        let retrievedToken = keychainHelper.retrieve()
        
        // Then
        XCTAssertTrue(saveResult, "Should save token with special characters")
        XCTAssertEqual(retrievedToken, specialToken, "Should retrieve special characters correctly")
    }
    
    func testSaveAndRetrieveLongToken() {
        // Given
        let longToken = String(repeating: "a", count: 1000)
        
        // When
        let saveResult = keychainHelper.save(longToken)
        let retrievedToken = keychainHelper.retrieve()
        
        // Then
        XCTAssertTrue(saveResult, "Should save long token")
        XCTAssertEqual(retrievedToken, longToken, "Should retrieve long token correctly")
    }
    
    func testKeychainHelperIsSingleton() {
        // When
        let instance1 = KeychainHelper.shared
        let instance2 = KeychainHelper.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2, "KeychainHelper should be a singleton")
    }
}
