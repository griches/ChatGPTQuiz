//
//  ContentView.swift
//  ChatGPTQuiz
//
//  Created by Gary Riches on 17/06/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = QuizViewModel()
    @StateObject private var themeManager = ThemeManager()
    @State private var path = NavigationPath()
    @State private var showingSettings = false
    
    var body: some View {
        ZStack {
            ThemedGradientBackground(theme: themeManager.currentTheme)
            
            NavigationStack(path: $path) {
                HomeView(viewModel: viewModel, path: $path)
                    .navigationDestination(for: String.self) { destination in
                        if destination == "QuizView" {
                            QuizView(viewModel: viewModel, path: $path)
                        }
                    }
            }
        }
        .environmentObject(themeManager)
        .onChange(of: viewModel.shouldNavigateToQuiz) { _, shouldNavigate in
            if shouldNavigate {
                path.append("QuizView")
                viewModel.shouldNavigateToQuiz = false
            }
        }
    }
}

struct ThemedGradientBackground: View {
    let theme: AppTheme
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: theme.gradientColors,
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

struct HomeView: View {
    @ObservedObject var viewModel: QuizViewModel
    @Binding var path: NavigationPath
    @State private var showingSettings = false
    @EnvironmentObject var themeManager: ThemeManager
    @State private var titleScale: CGFloat = 0.8
    @State private var cardOffset: CGFloat = 50
    @State private var cardOpacity: Double = 0
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title Section
                HStack {
                    Text("InfiniQuiz")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [themeManager.currentTheme.accentColor, themeManager.currentTheme.accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(titleScale)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: titleScale)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            showingSettings = true
                        }
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                            .rotationEffect(.degrees(showingSettings ? 180 : 0))
                    }
                }
                .padding(.top, 20)
                
                // Quiz Input Section
                VStack(spacing: 20) {
                        TextField("Enter a subject", text: $viewModel.subject)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .padding()
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(themeManager.currentTheme.accentColor.opacity(0.3), lineWidth: 1)
                            )
                            .focused($isTextFieldFocused)
                        
                        Picker("Number of Questions", selection: $viewModel.questionCount) {
                            Text("10").tag(10)
                            Text("20").tag(20)
                        }
                        .pickerStyle(.segmented)
                        .background(themeManager.currentTheme.cardBackground)
                        .cornerRadius(8)
                        
                        if let error = viewModel.error {
                            Text(error)
                                .font(.bodyText)
                                .foregroundColor(.incorrectRed)
                                .padding(.horizontal)
                        }
                        
                        AnimatedPrimaryButton(
                            title: "Generate Quiz",
                            isLoading: viewModel.isLoading,
                            accentColor: themeManager.currentTheme.accentColor
                        ) {
                            Task {
                                await viewModel.generateQuiz()
                            }
                        }
                    }
                .padding(24)
                .glassmorphic()
                .offset(y: cardOffset)
                .opacity(cardOpacity)
                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: cardOffset)
                
                // Previous Quizzes Section
                if !viewModel.previousQuizzes.isEmpty {
                    VStack {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Previous Quizzes")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            List {
                                ForEach(viewModel.previousQuizzes) { quiz in
                                    AnimatedQuizRow(
                                        subject: quiz.subject,
                                        questionCount: quiz.totalQuestions,
                                        accentColor: themeManager.currentTheme.accentColor
                                    ) {
                                        viewModel.playPreviousQuiz(quiz)
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            // Add haptic feedback for deletion
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                                            impactFeedback.impactOccurred()
                                            
                                            if let index = viewModel.previousQuizzes.firstIndex(where: { $0.id == quiz.id }) {
                                                viewModel.deletePreviousQuiz(at: IndexSet(integer: index))
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                                .onDelete { offsets in
                                    // Add haptic feedback for swipe delete
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                                    impactFeedback.impactOccurred()
                                    
                                    viewModel.deletePreviousQuiz(at: offsets)
                                }
                            }
                            .listStyle(PlainListStyle())
                            .scrollDisabled(viewModel.previousQuizzes.count <= 5)
                            .frame(height: CGFloat(min(viewModel.previousQuizzes.count, 5) * 80))
                            .padding(.bottom, 2)
                        }
                    }
                    .padding(24)
                    .glassmorphic()
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .navigationBarHidden(true)
        .overlay(
            // Invisible overlay for tap-to-dismiss keyboard when text field is focused
            isTextFieldFocused ? 
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    isTextFieldFocused = false
                }
                .allowsHitTesting(true)
            : nil
        )
        .sheet(isPresented: $showingSettings) {
            SettingsView(viewModel: viewModel)
                .environmentObject(themeManager)
        }
        .onAppear {
            withAnimation {
                titleScale = 1.0
                cardOffset = 0
                cardOpacity = 1
            }
        }
    }
}


#Preview {
    ContentView()
}
