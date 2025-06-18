import Foundation

class ChatGPTService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func generateQuiz(subject: String, questionCount: Int) async throws -> Quiz {
        let prompt = """
        You are an assessment generator.

        TASK
        Generate a multiple-choice quiz about **\(subject)** containing **\(questionCount)** questions.

        QUESTION RULES
        1. Cover a *different* facet of \(subject) in each question (e.g. terminology, history, applications, key figures, recent developments).
        2. Each question must have exactly **three** answer choices:
           • Exactly **one** is correct and unambiguously so.  
           • The **two distractors** must be plausible yet factually wrong—no partial credit.  
           • Choices must not overlap in meaning.
        3. Choices or wording in one question must not reveal answers to any other question.
        4. No trick questions, and never use “all/none of the above”.

        OUTPUT RULES
        • **Return ONLY valid JSON** – no markdown, comments, or code fences.  
        • **Do not add, remove, or rename keys. Keep this exact order.**

        EXAMPLE
        {
          "questions": [
            {
              "question": "Sample question text",
              "choices": ["Option A", "Option B", "Option C"],
              "correctAnswerIndex": 1
            }
          ]
        }

        BEGIN.
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
