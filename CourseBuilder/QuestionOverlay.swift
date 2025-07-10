//
//  QuestionOverlay.swift
//  CourseBuilder
//
//  Interactive question overlay component for course videos
//

import SwiftUI

/// Interactive question overlay that appears during video playback
struct QuestionOverlay: View {
    
    // MARK: - Properties
    
    let question: Question
    let onAnswer: (Bool, String) -> Void
    let onContinue: () -> Void
    
    @State private var selectedAnswerIndex: Int? = nil
    @State private var showExplanation = false
    @State private var hasAnswered = false
    @State private var questionStartTime = Date()
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Question Card
            VStack(alignment: .leading, spacing: 16) {
                // Video pause indicator and continue button
                HStack {
                    Image(systemName: "pause.circle.fill")
                        .foregroundColor(.orange)
                    Text("Video Paused")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    // Continue Video button (shown after answering)
                    if hasAnswered {
                        Button("Continue Video") {
                            print("▶️ Debug: Continuing video after question")
                            onContinue()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                    }
                }
                .padding(.bottom, 4)
                
                // Question text
                Text(question.question)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .padding(.vertical, 8)
                
                // Answer options
                if !question.formattedOptions.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(Array(question.formattedOptions.enumerated()), id: \.offset) { index, option in
                            AnswerOptionView(
                                option: option,
                                index: index,
                                isSelected: selectedAnswerIndex == index,
                                isCorrect: hasAnswered ? index == question.correctAnswerIndex : nil,
                                hasAnswered: hasAnswered
                            ) {
                                handleAnswerSelection(index: index, option: option)
                            }
                        }
                    }
                }
                
                // Explanation (shown after answering)
                if showExplanation, let explanation = question.explanation {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.orange)
                            Text("Explanation")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        Text(explanation)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.leading, 24)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }
                
                // Action buttons
                HStack(spacing: 12) {
                    if hasAnswered {
                        if question.explanation != nil {
                            Button(showExplanation ? "Hide Explanation" : "Show Explanation") {
                                showExplanation.toggle()
                                print("💡 Debug: Toggled explanation visibility: \(showExplanation)")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                    } else {
                        Button("Skip Question") {
                            handleSkip()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        
                        Spacer()
                    }
                }
                .padding(.top, 8)
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 16)
        }
        .onAppear {
            questionStartTime = Date()
            print("❓ Debug: Question appeared: \(question.question)")
            print("⏸️ Debug: Video automatically paused for question")
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleAnswerSelection(index: Int, option: String) {
        guard !hasAnswered else { return }
        
        selectedAnswerIndex = index
        hasAnswered = true
        
        let isCorrect = index == question.correctAnswerIndex
        let responseTime = Int(Date().timeIntervalSince(questionStartTime) * 1000)
        
        print("✏️ Debug: Answer selected - Index: \(index), Correct: \(isCorrect), Time: \(responseTime)ms")
        
        // Show explanation automatically if available
        if question.explanation != nil {
            showExplanation = true
        }
        
        // Call the answer handler
        onAnswer(isCorrect, option)
    }
    
    private func handleSkip() {
        print("⏭️ Debug: Question skipped")
        hasAnswered = true
        onAnswer(false, "skipped")
    }
}

/// Individual answer option view
struct AnswerOptionView: View {
    
    let option: String
    let index: Int
    let isSelected: Bool
    let isCorrect: Bool?
    let hasAnswered: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Option letter/number
                Text("\(Character(UnicodeScalar(65 + index)!))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(width: 24, height: 24)
                    .background(optionBackground)
                    .foregroundColor(optionForeground)
                    .clipShape(Circle())
                
                // Option text
                Text(option)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(optionTextColor)
                
                Spacer()
                
                // Feedback icon (after answering)
                if hasAnswered {
                    Image(systemName: feedbackIcon)
                        .foregroundColor(feedbackColor)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(optionCardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(optionBorderColor, lineWidth: optionBorderWidth)
            )
            .cornerRadius(8)
        }
        .disabled(hasAnswered)
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Computed Properties
    
    private var optionBackground: Color {
        if hasAnswered {
            if isCorrect == true {
                return .green
            } else if isSelected {
                return .red
            }
        }
        return isSelected ? .blue : Color(.systemGray5)
    }
    
    private var optionForeground: Color {
        if hasAnswered && (isCorrect == true || isSelected) {
            return .white
        }
        return isSelected ? .white : .primary
    }
    
    private var optionCardBackground: Color {
        if hasAnswered {
            if isCorrect == true {
                return Color.green.opacity(0.1)
            } else if isSelected {
                return Color.red.opacity(0.1)
            }
        }
        return isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6)
    }
    
    private var optionBorderColor: Color {
        if hasAnswered {
            if isCorrect == true {
                return .green
            } else if isSelected {
                return .red
            }
        }
        return isSelected ? .blue : Color(.systemGray4)
    }
    
    private var optionBorderWidth: Double {
        return isSelected || hasAnswered ? 2.0 : 1.0
    }
    
    private var optionTextColor: Color {
        return .primary
    }
    
    private var feedbackIcon: String {
        if isCorrect == true {
            return "checkmark.circle.fill"
        } else if isSelected {
            return "xmark.circle.fill"
        }
        return ""
    }
    
    private var feedbackColor: Color {
        if isCorrect == true {
            return .green
        } else if isSelected {
            return .red
        }
        return .clear
    }
}

// MARK: - Preview

#Preview {
    let sampleQuestion = Question(
        id: "sample-1",
        courseId: "course-1",
        timestamp: 30,
        question: "What is the primary purpose of SwiftUI's @State property wrapper?",
        type: "multiple-choice",
        options: [
            "To create immutable state",
            "To manage local view state that can trigger UI updates",
            "To share data between views",
            "To connect to external APIs"
        ],
        correctAnswer: "1",
        explanation: "The @State property wrapper is used to manage local state within a view that can change over time and trigger UI updates when modified.",
        visualContext: nil,
        frameTimestamp: nil,
        metadata: nil
    )
    
    QuestionOverlay(
        question: sampleQuestion,
        onAnswer: { isCorrect, answer in
            print("Answer: \(answer), Correct: \(isCorrect)")
        },
        onContinue: {
            print("Continue tapped")
        }
    )
    .padding()
} 