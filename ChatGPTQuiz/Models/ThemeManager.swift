import SwiftUI
import Combine

enum ColorSchemePreference: String, CaseIterable {
    case dark = "Dark"
    case light = "Light"
    case device = "Device Settings"
    
    func colorScheme(systemScheme: ColorScheme) -> ColorScheme? {
        switch self {
        case .dark:
            return .dark
        case .light:
            return .light
        case .device:
            return systemScheme
        }
    }
}

enum AppTheme: String, CaseIterable {
    case ocean = "Ocean"
    case coral = "Coral"
    case forest = "Forest"
    case space = "Space"
    case citrus = "Citrus"
    case lavender = "Lavender"
    case cherry = "Cherry"
    case mint = "Mint"
    case amber = "Amber"
    case midnight = "Midnight"
    
    var gradientColors: [Color] {
        switch self {
        case .ocean:
            return [
                Color(red: 0.02, green: 0.46, blue: 0.9),
                Color(red: 0.01, green: 0.11, blue: 0.47),
                Color(red: 0.1, green: 0.14, blue: 0.49),
                Color(red: 0.02, green: 0.46, blue: 0.9)
            ]
        case .coral:
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
        case .citrus:
            return [
                Color(red: 1.0, green: 0.65, blue: 0.2),
                Color(red: 1.0, green: 0.8, blue: 0.4),
                Color(red: 1.0, green: 0.45, blue: 0.0),
                Color(red: 1.0, green: 0.65, blue: 0.2)
            ]
        case .lavender:
            return [
                Color(red: 0.7, green: 0.6, blue: 0.9),
                Color(red: 0.85, green: 0.8, blue: 0.95),
                Color(red: 0.55, green: 0.4, blue: 0.8),
                Color(red: 0.7, green: 0.6, blue: 0.9)
            ]
        case .cherry:
            return [
                Color(red: 0.9, green: 0.2, blue: 0.4),
                Color(red: 1.0, green: 0.6, blue: 0.7),
                Color(red: 0.7, green: 0.1, blue: 0.3),
                Color(red: 0.9, green: 0.2, blue: 0.4)
            ]
        case .mint:
            return [
                Color(red: 0.4, green: 0.8, blue: 0.7),
                Color(red: 0.7, green: 0.9, blue: 0.85),
                Color(red: 0.2, green: 0.6, blue: 0.5),
                Color(red: 0.4, green: 0.8, blue: 0.7)
            ]
        case .amber:
            return [
                Color(red: 0.95, green: 0.7, blue: 0.3),
                Color(red: 1.0, green: 0.85, blue: 0.6),
                Color(red: 0.8, green: 0.5, blue: 0.1),
                Color(red: 0.95, green: 0.7, blue: 0.3)
            ]
        case .midnight:
            return [
                Color(red: 0.05, green: 0.05, blue: 0.15),
                Color(red: 0.15, green: 0.15, blue: 0.3),
                Color(red: 0.0, green: 0.0, blue: 0.1),
                Color(red: 0.05, green: 0.05, blue: 0.15)
            ]
        }
    }
    
    var accentColor: Color {
        switch self {
        case .ocean: return Color(red: 0.39, green: 0.71, blue: 0.96)
        case .coral: return Color(red: 1.0, green: 0.54, blue: 0.5)
        case .forest: return Color(red: 0.51, green: 0.78, blue: 0.52)
        case .space: return Color(red: 0.49, green: 0.3, blue: 1.0)
        case .citrus: return Color(red: 1.0, green: 0.55, blue: 0.0)
        case .lavender: return Color(red: 0.6, green: 0.4, blue: 0.9)
        case .cherry: return Color(red: 0.9, green: 0.15, blue: 0.35)
        case .mint: return Color(red: 0.3, green: 0.7, blue: 0.6)
        case .amber: return Color(red: 0.9, green: 0.6, blue: 0.2)
        case .midnight: return Color(red: 0.4, green: 0.6, blue: 1.0)
        }
    }
    
    var cardBackground: Color {
        switch self {
        case .ocean: return Color.white.opacity(0.1)
        case .coral: return Color.white.opacity(0.15)
        case .forest: return Color.white.opacity(0.1)
        case .space: return Color.white.opacity(0.08)
        case .citrus: return Color.white.opacity(0.12)
        case .lavender: return Color.white.opacity(0.12)
        case .cherry: return Color.white.opacity(0.1)
        case .mint: return Color.white.opacity(0.12)
        case .amber: return Color.white.opacity(0.12)
        case .midnight: return Color.white.opacity(0.06)
        }
    }
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .space
    @Published var isAnimating = false
    @Published var colorSchemePreference: ColorSchemePreference = .dark
    @Published var systemColorScheme: ColorScheme = .dark
    
    private var timer: Timer?
    private let userDefaults = UserDefaults.standard
    private let themeKey = "selectedTheme"
    private let autoThemeKey = "autoThemeEnabled"
    private let colorSchemeKey = "colorSchemePreference"
    
    init() {
        loadTheme()
        loadColorSchemePreference()
        detectSystemColorScheme()
        setupAutoTheme()
    }
    
    private func detectSystemColorScheme() {
        let detectedScheme: ColorScheme = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
        systemColorScheme = detectedScheme
    }
    
    func refreshSystemColorScheme() {
        let detectedScheme: ColorScheme = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
        systemColorScheme = detectedScheme
    }
    
    var effectiveColorScheme: ColorScheme? {
        colorSchemePreference.colorScheme(systemScheme: systemColorScheme)
    }
    
    func updateSystemColorScheme(_ scheme: ColorScheme) {
        systemColorScheme = scheme
    }
    
    func setTheme(_ theme: AppTheme) {
        withAnimation(.easeInOut(duration: 0.8)) {
            isAnimating = true
            currentTheme = theme
        }
        
        // Save theme and disable auto-theme when user manually selects
        saveTheme(theme)
        userDefaults.set(false, forKey: autoThemeKey)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.isAnimating = false
        }
    }
    
    private func setupAutoTheme() {
        // Only setup auto-theme if enabled and no manual theme is saved
        if userDefaults.bool(forKey: autoThemeKey) && userDefaults.string(forKey: themeKey) == nil {
            updateThemeBasedOnTime()
            
            timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
                self.updateThemeBasedOnTime()
            }
        }
    }
    
    private func updateThemeBasedOnTime() {
        // Only auto-update if auto-theme is enabled
        guard userDefaults.bool(forKey: autoThemeKey) else { return }
        
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 6..<12:
            currentTheme = .ocean
        case 12..<17:
            currentTheme = .forest
        case 17..<20:
            currentTheme = .coral
        default:
            currentTheme = .space
        }
    }
    
    private func loadTheme() {
        if let savedThemeString = userDefaults.string(forKey: themeKey),
           let savedTheme = AppTheme(rawValue: savedThemeString) {
            currentTheme = savedTheme
        }
    }
    
    private func saveTheme(_ theme: AppTheme) {
        userDefaults.set(theme.rawValue, forKey: themeKey)
    }
    
    func setColorSchemePreference(_ preference: ColorSchemePreference) {
        withAnimation(.easeInOut(duration: 0.6)) {
            colorSchemePreference = preference
        }
        saveColorSchemePreference(preference)
    }
    
    private func loadColorSchemePreference() {
        if let savedPreferenceString = userDefaults.string(forKey: colorSchemeKey),
           let savedPreference = ColorSchemePreference(rawValue: savedPreferenceString) {
            colorSchemePreference = savedPreference
        } else {
            colorSchemePreference = .dark
        }
    }
    
    private func saveColorSchemePreference(_ preference: ColorSchemePreference) {
        userDefaults.set(preference.rawValue, forKey: colorSchemeKey)
    }
    
    deinit {
        timer?.invalidate()
    }
}