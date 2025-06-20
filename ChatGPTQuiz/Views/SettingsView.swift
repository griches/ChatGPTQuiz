import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: QuizViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var systemColorScheme
    @State private var apiToken: String = ""
    @State private var showingTokenAlert = false
    @State private var isTokenVisible = false
    @State private var tokenPlaceholder: String = "sk-..."
    @State private var showingThemeSelection = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Show API Token section first if no token exists
                    if !viewModel.hasValidAPIToken {
                        apiTokenSection
                        
                        // Instructions for getting API token
                        VStack(alignment: .leading, spacing: 16) {
                            Text("How to get an API Token")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                StepLabel(number: "1", text: "Visit platform.openai.com")
                                StepLabel(number: "2", text: "Sign in or create an account")
                                StepLabel(number: "3", text: "Navigate to API Keys section")
                                StepLabel(number: "4", text: "Create a new secret key")
                                StepLabel(number: "5", text: "Copy and paste it here")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(24)
                        .glassmorphic()
                    }
                    
                    // Theme Selection Section
                    VStack {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Theme")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("Choose your preferred color theme")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 18), count: 2), spacing: 18) {
                                ForEach(Array(AppTheme.allCases.prefix(4)), id: \.self) { theme in
                                    ThemeCard(theme: theme, isSelected: themeManager.currentTheme == theme) {
                                        themeManager.setTheme(theme)
                                    }
                                }
                            }
                            
                            Button(action: {
                                showingThemeSelection = true
                            }) {
                                HStack {
                                    Image(systemName: "paintpalette.fill")
                                        .font(.system(size: 18))
                                    Text("More Themes")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(themeManager.currentTheme.accentColor)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager.currentTheme.accentColor.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(themeManager.currentTheme.accentColor.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(24)
                    .glassmorphic()
                    
                    // Color Scheme Section
                    VStack {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Appearance")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("Choose your preferred color scheme")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 8) {
                                ForEach(ColorSchemePreference.allCases, id: \.self) { preference in
                                    ColorSchemeRow(
                                        preference: preference,
                                        isSelected: themeManager.colorSchemePreference == preference,
                                        accentColor: themeManager.currentTheme.accentColor
                                    ) {
                                        themeManager.setColorSchemePreference(preference)
                                    }
                                }
                            }
                        }
                    }
                    .padding(24)
                    .glassmorphic()
                    
                    // Show API Token section lower down if token exists
                    if viewModel.hasValidAPIToken {
                        apiTokenSection
                    }
                    
                    // Token Status
                    if viewModel.hasValidAPIToken {
                        VStack {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("API Token is configured")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                        .padding(24)
                        .glassmorphic()
                    }
                    
                    
                    // Clear Token Button
                    if viewModel.hasValidAPIToken {
                        AnimatedPrimaryButton(
                            title: "Clear API Token",
                            isLoading: false,
                            accentColor: .red
                        ) {
                            showingTokenAlert = true
                        }
                    }
                }
                .padding()
            }
            .background(Color.clear)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
        }
        .preferredColorScheme(themeManager.effectiveColorScheme)
        .animation(.easeInOut(duration: 0.6), value: themeManager.colorSchemePreference)
        .onAppear {
            themeManager.refreshSystemColorScheme()
        }
        .sheet(isPresented: $showingThemeSelection) {
            ThemeSelectionView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.effectiveColorScheme)
                .animation(.easeInOut(duration: 0.6), value: themeManager.colorSchemePreference)
        }
        .alert("Clear API Token?", isPresented: $showingTokenAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                viewModel.clearAPIToken()
                apiToken = ""
                tokenPlaceholder = "sk-..."
            }
        } message: {
            Text("This will remove your stored API token. You'll need to enter it again to generate new quizzes.")
        }
        .onAppear {
            // Don't show the actual token for security
            if viewModel.hasValidAPIToken {
                apiToken = ""
                tokenPlaceholder = "Token saved (hidden for security)"
            } else {
                tokenPlaceholder = "sk-..."
            }
        }
    }
    
    private func saveAPIToken() {
        viewModel.saveAPIToken(apiToken)
        // Clear the field after saving for security
        apiToken = ""
    }
    
    private var apiTokenSection: some View {
        VStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("OpenAI API Token")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Enter your OpenAI API token to generate quizzes. Your token is stored securely on your device.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    if isTokenVisible {
                        TextField(tokenPlaceholder, text: $apiToken)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    } else {
                        SecureField(tokenPlaceholder, text: $apiToken)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    if !apiToken.isEmpty {
                        Button(action: {
                            isTokenVisible.toggle()
                        }) {
                            Image(systemName: isTokenVisible ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                if !apiToken.isEmpty {
                    AnimatedPrimaryButton(
                        title: "Save Token",
                        isLoading: false,
                        accentColor: themeManager.currentTheme.accentColor
                    ) {
                        saveAPIToken()
                    }
                }
            }
        }
        .padding(24)
        .glassmorphic()
    }
}

struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Theme preview
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.accentColor)
                    .frame(height: 30)
                
                Text(theme.rawValue)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isSelected ? 0.2 : 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? theme.accentColor : Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ThemeSelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 18), count: 2), spacing: 18) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            ThemeCard(theme: theme, isSelected: themeManager.currentTheme == theme) {
                                themeManager.setTheme(theme)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.clear)
            .navigationTitle("Choose Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
        }
    }
}

struct ColorSchemeRow: View {
    let preference: ColorSchemePreference
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(accentColor)
                    .frame(width: 24)
                
                Text(preference.rawValue)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(accentColor)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isSelected ? 0.15 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? accentColor.opacity(0.5) : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconName: String {
        switch preference {
        case .dark:
            return "moon.fill"
        case .light:
            return "sun.max.fill"
        case .device:
            return "iphone"
        }
    }
}

struct StepLabel: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue)
                .frame(width: 24, height: 24)
                .overlay(
                    Text(number)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                )
            
            Text(text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
    }
}
