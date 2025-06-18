import Foundation

class ChatGPTService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func generateQuiz(subject: String, questionCount: Int) async throws -> Quiz {
        let prompt = """
        Generate a multiple-choice quiz about \(subject) with \(questionCount) questions. For each question, provide exactly 3 answer choices: 1 correct answer and 2 clearly incorrect answers. The correct answer must be unambiguously correct, and the incorrect answers must be clearly wrong and not open to interpretation. Do not use trick questions or answers that could be considered correct. Format the response as JSON with the following structure: { \"questions\": [ { \"question\": \"Question text\", \"choices\": [\"Choice 1\", \"Choice 2\", \"Choice 3\"], \"correctAnswerIndex\": 0 } ] }
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
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
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