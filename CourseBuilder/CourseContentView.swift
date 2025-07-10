//
//  CourseContentView.swift
//  CourseBuilder
//
//  Main course content view for displaying course info, questions, and progress
//

import SwiftUI

/// Main course content view that replaces the transcript area
struct CourseContentView: View {
    
    // MARK: - Properties
    
    let viewModel: CourseViewModel
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Content based on loading/error state
            if viewModel.isLoading {
                LoadingView(message: viewModel.course == nil ? "Loading course content..." : "Loading next course...")
            } else if let error = viewModel.error {
                ErrorView(error: error) {
                    Task {
                        await viewModel.loadCourseData()
                    }
                }
            } else if let question = viewModel.currentQuestion, viewModel.showQuestion {
                // Show question overlay when question is active
                QuestionOverlay(
                    question: question,
                    onAnswer: viewModel.handleAnswer,
                    onContinue: viewModel.continueVideo
                )
                .id(question.id) // Force new view instance for each question
                .transition(.scale.combined(with: .opacity))
            } else {
                // Show course content and progress
                CourseInfoView(viewModel: viewModel)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showQuestion)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    let message: String
    
    init(message: String = "Loading course content...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Error View

struct ErrorView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Failed to load course")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .padding()
    }
}

// MARK: - Course Info View

struct CourseInfoView: View {
    let viewModel: CourseViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Questions Overview
                if !viewModel.questions.isEmpty {
                    QuestionsOverviewView(
                        questions: viewModel.questions,
                        answeredQuestions: viewModel.answeredQuestions,
                        questionResults: viewModel.questionResults,
                        currentTime: viewModel.currentTime
                    )
                }                
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
    }
}


// MARK: - Questions Overview View

struct QuestionsOverviewView: View {
    let questions: [Question]
    let answeredQuestions: Set<Int>
    let questionResults: [String: Bool]
    let currentTime: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Interactive Questions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 8) {
                ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                    QuestionItemView(
                        question: question,
                        index: index,
                        isAnswered: answeredQuestions.contains(index),
                        isCorrect: questionResults["0-\(index)"],
                        isPending: currentTime >= question.timestampSeconds && !answeredQuestions.contains(index)
                    )
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Question Item View

struct QuestionItemView: View {
    let question: Question
    let index: Int
    let isAnswered: Bool
    let isCorrect: Bool?
    let isPending: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.title3)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                // Timestamp and question type
                HStack {
                    Text(SupabaseService.formatTimestamp(question.timestampSeconds))
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    
                    Text(question.type.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                // Question preview
                Text(question.question)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(itemBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: borderWidth)
        )
    }
    
    // MARK: - Computed Properties
    
    private var statusIcon: String {
        if isPending {
            return "clock.fill"
        } else if isAnswered {
            return isCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill"
        } else {
            return "circle"
        }
    }
    
    private var statusColor: Color {
        if isPending {
            return .orange
        } else if isAnswered {
            return isCorrect == true ? .green : .red
        } else {
            return .gray
        }
    }
    
    private var itemBackground: Color {
        if isPending {
            return Color.orange.opacity(0.1)
        } else if isAnswered {
            return isCorrect == true ? Color.green.opacity(0.1) : Color.red.opacity(0.1)
        } else {
            return Color(.systemBackground)
        }
    }
    
    private var borderColor: Color {
        if isPending {
            return .orange
        } else if isAnswered {
            return isCorrect == true ? .green : .red
        } else {
            return Color(.systemGray4)
        }
    }
    
    private var borderWidth: Double {
        return isPending || isAnswered ? 1.5 : 0.5
    }
}


// MARK: - Stat Badge View

struct StatBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Preview

#Preview {
    let viewModel = CourseViewModel()
    CourseContentView(viewModel: viewModel)
} 