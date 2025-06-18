import Foundation

class ChatGPTService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func generateQuiz(subject: String, questionCount: Int) async throws -> Quiz {
        let prompt = """
        Generate a multiple-choice quiz about \(subject) with \(questionCount) questions. Follow these strict rules:
        1. Each question must be about a completely different aspect or fact of the subject - no rephrasing or asking the same thing differently
        2. Each question must have exactly 3 answer choices that are:
           - Completely unique from each other (no similar or partially correct answers)
           - Only ONE can be correct, and it must be unambiguously correct
           - The two incorrect answers must be clearly wrong and not open to interpretation
        3. Ensure answers don't give hints about other questions
        4. No trick questions or "all/none of the above" options
        
        Format the response as JSON with the following structure: { \"questions\": [ { \"question\": \"Question text\", \"choices\": [\"Choice 1\", \"Choice 2\", \"Choice 3\"], \"correctAnswerIndex\": 0 } ] }
        """
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw QuizError.networkError
        }
        
        // Check for authentication errors
        if httpResponse.statusCode == 401 {
            throw QuizError.apiError("Invalid API key. Please check your settings.")
        }
        
        if httpResponse.statusCode == 429 {
            throw QuizError.apiError("Rate limit exceeded. Please wait and try again.")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw QuizError.networkError
        }
        
        // Parse the response and create Quiz object
        struct ChatGPTResponse: Decodable {
            struct Choice: Decodable {
                let message: Message
            }
            struct Message: Decodable {
                let content: String
            }
            let choices: [Choice]
        }
        
        let chatResponse = try JSONDecoder().decode(ChatGPTResponse.self, from: data)
        guard let content = chatResponse.choices.first?.message.content else {
            throw QuizError.invalidResponse
        }
        
        // Remove code block markers if present
        let cleanedContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonStart = cleanedContent.firstIndex(of: "{"),
              let jsonEnd = cleanedContent.lastIndex(of: "}") else {
            throw QuizError.invalidResponse
        }

        let jsonString = String(cleanedContent[jsonStart...jsonEnd])
        let jsonData = Data(jsonString.utf8)
        
        struct QuestionsWrapper: Decodable {
            let questions: [QuestionJSON]
        }
        struct QuestionJSON: Decodable {
            let question: String
            let choices: [String]
            let correctAnswerIndex: Int
        }
        
        let questionsWrapper = try JSONDecoder().decode(QuestionsWrapper.self, from: jsonData)
        let questions = questionsWrapper.questions.map { q in
            Question(question: q.question, choices: q.choices, correctAnswerIndex: q.correctAnswerIndex)
        }
        
        // TODO: Add robust error handling if the response is not as expected
        return Quiz(id: UUID(), subject: subject, questions: questions)
    }
} 