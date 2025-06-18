//
//  ContentView.swift
//  ChatGPTQuiz
//
//  Created by Gary Riches on 17/06/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = QuizViewModel()
    @State private var path = NavigationPath()
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack(path: $path) {
            HomeView(viewModel: viewModel, path: $path)
                .navigationDestination(for: String.self) { destination in
                    if destination == "QuizView" {
                        QuizView(viewModel: viewModel, path: $path)
                    }
                }
        }
        .onChange(of: viewModel.shouldNavigateToQuiz) { _, shouldNavigate in
            if shouldNavigate {
                path.append("QuizView")
                viewModel.shouldNavigateToQuiz = false
            }
        }
    }
}

struct HomeView: View {
    @ObservedObject var viewModel: QuizViewModel
    @Binding var path: NavigationPath
    @State private var showingSettings = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title Section
                HStack {
                    Text("InfiniQuiz")
                        .font(.titleBold)
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.accentBlue)
                    }
                }
                .padding(.top, 20)
                
                // Quiz Input Section
                QuizCard {
                    VStack(spacing: 20) {
                        TextField("Enter a subject", text: $viewModel.subject)
                            .font(.bodyText)
                            .padding()
                            .background(Color.textFieldBackground)
                            .foregroundColor(.primaryText)
                            .cornerRadius(12)
                        
                        Picker("Number of Questions", selection: $viewModel.questionCount) {
                            Text("10").tag(10)
                            Text("20").tag(20)
                        }
                        .pickerStyle(.segmented)
                        .accentColor(.accentBlue)
                        
                        if let error = viewModel.error {
                            Text(error)
                                .font(.bodyText)
                                .foregroundColor(.incorrectRed)
                                .padding(.horizontal)
                        }
                        
                        PrimaryButton("Generate Quiz", isLoading: viewModel.isLoading) {
                            Task {
                                await viewModel.generateQuiz()
                            }
                        }
                    }
                }
                
                // Previous Quizzes Section
                if !viewModel.previousQuizzes.isEmpty {
                    QuizCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Previous Quizzes")
                                .font(.subheadingBold)
                                .foregroundColor(.primaryText)
                            
                            List {
                                ForEach(viewModel.previousQuizzes) { quiz in
                                    PreviousQuizRow(
                                        subject: quiz.subject,
                                        questionCount: quiz.totalQuestions
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
                            .frame(height: CGFloat(min(viewModel.previousQuizzes.count, 5) * 55))
                            .padding(.bottom, 2)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.deepCharcoal)
        .navigationBarHidden(true)
        .dismissKeyboardOnTap()
        .sheet(isPresented: $showingSettings) {
            SettingsView(viewModel: viewModel)
        }
    }
}

#Preview {
    ContentView()
}