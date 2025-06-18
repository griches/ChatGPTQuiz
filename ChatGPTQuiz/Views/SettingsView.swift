import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: QuizViewModel
    @Environment(\.dismiss) var dismiss
    @State private var apiToken: String = ""
    @State private var showingTokenAlert = false
    @State private var isTokenVisible = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // API Token Section
                    QuizCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("OpenAI API Token")
                                .font(.subheadingBold)
                                .foregroundColor(.primaryText)
                            
                            Text("Enter your OpenAI API token to generate quizzes. Your token is stored securely on your device.")
                                .font(.bodyText)
                                .foregroundColor(.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            HStack {
                                if isTokenVisible {
                                    TextField("sk-...", text: $apiToken)
                                        .font(.bodyText)
                                        .foregroundColor(.primaryText)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                } else {
                                    SecureField("sk-...", text: $apiToken)
                                        .font(.bodyText)
                                        .foregroundColor(.primaryText)
                                }
                                
                                Button(action: {
                                    isTokenVisible.toggle()
                                }) {
                                    Image(systemName: isTokenVisible ? "eye.slash" : "eye")
                                        .foregroundColor(.secondaryText)
                                }
                            }
                            .padding()
                            .background(Color.deepCharcoal)
                            .cornerRadius(12)
                            
                            if !apiToken.isEmpty {
                                PrimaryButton("Save Token") {
                                    saveAPIToken()
                                }
                            }
                        }
                    }
                    
                    // Token Status
                    if viewModel.hasValidAPIToken {
                        QuizCard {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.correctGreen)
                                Text("API Token is configured")
                                    .font(.bodyText)
                                    .foregroundColor(.primaryText)
                                Spacer()
                            }
                        }
                    }
                    
                    // Instructions
                    QuizCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How to get an API Token")
                                .font(.subheadingBold)
                                .foregroundColor(.primaryText)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Visit platform.openai.com", systemImage: "1.circle.fill")
                                Label("Sign in or create an account", systemImage: "2.circle.fill")
                                Label("Navigate to API Keys section", systemImage: "3.circle.fill")
                                Label("Create a new secret key", systemImage: "4.circle.fill")
                                Label("Copy and paste it here", systemImage: "5.circle.fill")
                            }
                            .font(.bodyText)
                            .foregroundColor(.secondaryText)
                        }
                    }
                    
                    // Clear Token Button
                    if viewModel.hasValidAPIToken {
                        Button(action: {
                            showingTokenAlert = true
                        }) {
                            Text("Clear API Token")
                                .font(.bodyText)
                                .foregroundColor(.incorrectRed)
                        }
                        .padding(.top)
                    }
                }
                .padding()
            }
            .background(Color.deepCharcoal)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.deepCharcoal, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accentBlue)
                }
            }
        }
        .alert("Clear API Token?", isPresented: $showingTokenAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                viewModel.clearAPIToken()
                apiToken = ""
            }
        } message: {
            Text("This will remove your stored API token. You'll need to enter it again to generate new quizzes.")
        }
        .onAppear {
            // Don't show the actual token for security
            if viewModel.hasValidAPIToken {
                apiToken = ""
            }
        }
    }
    
    private func saveAPIToken() {
        viewModel.saveAPIToken(apiToken)
        // Clear the field after saving for security
        apiToken = ""
    }
}