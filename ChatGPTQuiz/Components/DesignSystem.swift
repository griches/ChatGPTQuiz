import SwiftUI

// MARK: - Color Extensions
extension Color {
    static let deepCharcoal = Color(hex: "0C0C0F")
    static let cardBackground = Color(hex: "1C1C20")
    static let primaryText = Color.white
    static let secondaryText = Color(hex: "AFAFB3")
    static let accentBlue = Color(hex: "0A84FF")
    static let correctGreen = Color(hex: "32D74B")
    static let incorrectRed = Color(hex: "FF453A")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Font Extensions
extension Font {
    static let titleBold = Font.system(size: 28, weight: .bold, design: .rounded)
    static let subheadingBold = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let bodyText = Font.system(size: 16, weight: .regular, design: .default)
    static let buttonText = Font.system(size: 17, weight: .bold, design: .rounded)
    static let scoreText = Font.system(size: 48, weight: .bold, design: .default)
}

// MARK: - Reusable Components

struct QuizCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let isLoading: Bool
    
    init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text(title.uppercased())
                        .font(.buttonText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.accentBlue)
            .foregroundColor(.white)
            .cornerRadius(14)
        }
        .disabled(isLoading)
    }
}

struct AnswerButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.bodyText)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if let isCorrect = isCorrect {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isCorrect ? .correctGreen : .incorrectRed)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentBlue)
                }
            }
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
            )
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.accentBlue.opacity(0.15)
        }
        return Color.cardBackground
    }
    
    private var textColor: Color {
        return .primaryText
    }
    
    private var borderColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? .correctGreen : .incorrectRed
        }
        return isSelected ? .accentBlue : .clear
    }
}

struct ScoreDisplay: View {
    let score: Int
    let total: Int
    
    var percentage: Int {
        Int((Double(score) / Double(total)) * 100)
    }
    
    var scoreColor: Color {
        switch Double(score) / Double(total) {
        case 0.8...1.0:
            return .correctGreen
        case 0.6..<0.8:
            return .orange
        default:
            return .incorrectRed
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Quiz Results")
                .font(.titleBold)
                .foregroundColor(.primaryText)
            
            Text("\(score) out of \(total) correct")
                .font(.subheadingBold)
                .foregroundColor(.secondaryText)
            
            Text("\(percentage)%")
                .font(.scoreText)
                .foregroundColor(scoreColor)
        }
    }
}

struct IncorrectAnswerCard: View {
    let question: String
    let userAnswer: String
    let correctAnswer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.subheadingBold)
                .foregroundColor(.primaryText)
            
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.incorrectRed)
                Text("Your answer: \(userAnswer)")
                    .font(.bodyText)
                    .foregroundColor(.secondaryText)
            }
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.correctGreen)
                Text("Correct answer: \(correctAnswer)")
                    .font(.bodyText)
                    .foregroundColor(.secondaryText)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

struct PreviousQuizRow: View {
    let subject: String
    let questionCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(subject)
                    .font(.bodyText)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Text("\(questionCount) Qs")
                    .font(.bodyText)
                    .foregroundColor(.secondaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .background(Color.cardBackground)
            .cornerRadius(10)
        }
    }
} 