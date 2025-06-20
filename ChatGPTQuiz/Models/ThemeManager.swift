import SwiftUI
import Combine

enum AppTheme: String, CaseIterable {
    case ocean = "Ocean"
    case sunset = "Sunset"
    case forest = "Forest"
    case space = "Space"
    
    var gradientColors: [Color] {
        switch self {
        case .ocean:
            return [
                Color(red: 0.02, green: 0.46, blue: 0.9),
                Color(red: 0.01, green: 0.11, blue: 0.47),
                Color(red: 0.1, green: 0.14, blue: 0.49),
                Color(red: 0.02, green: 0.46, blue: 0.9)
            ]
        case .sunset:
            return [
                Color(red: 0.93, green: 0.61, blue: 0.65),
                Color(red: 1.0, green: 0.87, blue: 0.88),
                Color(red: 1.0, green: 0.42, blue: 0.42),
                Color(red: 0.93, green: 0.61, blue: 0.65)
            ]
        case .forest:
            return [
                Color(red: 0.07, green: 0.6, blue: 0.56),
                Color(red: 0.22, green: 0.94, blue: 0.49),
                Color(red: 0.18, green: 0.45, blue: 0.2),
                Color(red: 0.07, green: 0.6, blue: 0.56)
            ]
        case .space:
            return [
                Color(red: 0.08, green: 0.12, blue: 0.19),
                Color(red: 0.14, green: 0.23, blue: 0.33),
                Color(red: 0.1, green: 0.1, blue: 0.18),
                Color(red: 0.08, green: 0.12, blue: 0.19)
            ]
        }
    }
    
    var accentColor: Color {
        switch self {
        case .ocean: return Color(red: 0.39, green: 0.71, blue: 0.96)
        case .sunset: return Color(red: 1.0, green: 0.54, blue: 0.5)
        case .forest: return Color(red: 0.51, green: 0.78, blue: 0.52)
        case .space: return Color(red: 0.49, green: 0.3, blue: 1.0)
        }
    }
    
    var cardBackground: Color {
        switch self {
        case .ocean: return Color.white.opacity(0.1)
        case .sunset: return Color.white.opacity(0.15)
        case .forest: return Color.white.opacity(0.1)
        case .space: return Color.white.opacity(0.08)
        }
    }
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .space
    @Published var isAnimating = false
    
    private var timer: Timer?
    
    init() {
        setupAutoTheme()
    }
    
    func setTheme(_ theme: AppTheme) {
        withAnimation(.easeInOut(duration: 0.8)) {
            isAnimating = true
            currentTheme = theme
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.isAnimating = false
        }
    }
    
    private func setupAutoTheme() {
        updateThemeBasedOnTime()
        
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            self.updateThemeBasedOnTime()
        }
    }
    
    private func updateThemeBasedOnTime() {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 6..<12:
            setTheme(.ocean)
        case 12..<17:
            setTheme(.forest)
        case 17..<20:
            setTheme(.sunset)
        default:
            setTheme(.space)
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}