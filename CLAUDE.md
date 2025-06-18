# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI iOS app that generates and displays multiple-choice quizzes using OpenAI's ChatGPT API. Users can create quizzes on any subject, take them, and review their results.

## Architecture

### Core Components
- **Models/QuizModel.swift**: Data models for `Question` and `Quiz` objects with scoring logic
- **Services/ChatGPTService.swift**: OpenAI API integration for quiz generation
- **ViewModels/QuizViewModel.swift**: Main business logic and state management (@MainActor)
- **Views/**: SwiftUI views organized by function (QuizView, ResultsView)

### Key Patterns
- Uses MVVM architecture with SwiftUI and ObservableObject
- Navigation handled via NavigationStack with NavigationPath binding
- Persistent storage via UserDefaults for quiz history and user preferences
- Async/await for API calls with proper error handling
- Answer shuffling to prevent memorization

### Data Flow
1. User inputs subject and question count in HomeView
2. QuizViewModel calls ChatGPTService to generate quiz via OpenAI API
3. Generated quiz is stored in currentQuiz and previousQuizzes
4. QuizView displays questions with selectable answers
5. ResultsView shows score and incorrect answers with explanations

## Build Commands

```bash
# Build the project
xcodebuild -project ChatGPTQuiz.xcodeproj -scheme ChatGPTQuiz build

# Run the app (requires iOS Simulator or device)
xcodebuild -project ChatGPTQuiz.xcodeproj -scheme ChatGPTQuiz -destination 'platform=iOS Simulator,name=iPhone 15' build

# Clean build folder
xcodebuild -project ChatGPTQuiz.xcodeproj clean
```

## Important Notes

- **API Key**: Currently hardcoded in ContentView.swift:10 - should be moved to environment variables or secure storage
- **Error Handling**: ChatGPTService includes TODO for more robust error handling of malformed API responses
- **JSON Parsing**: Custom parsing logic handles ChatGPT response format variations and markdown code blocks
- **Quiz Storage**: Uses UserDefaults for persistence - not suitable for large amounts of data
- **Answer Shuffling**: Implemented to prevent answer pattern memorization

## Common Development Tasks

When modifying the app:
- Quiz generation logic is in ChatGPTService.swift:11-84
- UI state management is centralized in QuizViewModel
- All views are adaptive to dark mode using system colors
- Quiz history management is in QuizViewModel:38-50 and 104-112