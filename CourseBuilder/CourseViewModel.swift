//
//  CourseViewModel.swift
//  CourseBuilder
//
//  View model for managing course content and user interactions
//

import Foundation
import SwiftUI

/// Main view model for course content and interactions
@Observable
final class CourseViewModel {
    
    // MARK: - Properties
    
    // Course data
    var course: Course?
    var questions: [Question] = []
    var courseData: CourseData?
    
    // UI state
    var isLoading = false
    var error: String?
    var showQuestion = false
    var currentQuestionIndex = 0
    
    // Progress tracking
    var answeredQuestions: Set<Int> = []
    var correctAnswers = 0
    var questionResults: [String: Bool] = [:]
    
    // Video state (will be updated from video player)
    var currentTime: Double = 0
    var duration: Double = 0
    
    // Constants
    private let courseId = "635ac9eb-8876-42fb-a25e-3411b1a68c49" // Hardcoded as requested
    private let supabaseService = SupabaseService.shared
    
    // MARK: - Initialization
    
    init() {
        print("🎓 Debug: CourseViewModel initialized")
        Task {
            await loadCourseData()
        }
    }
    
    // MARK: - Data Loading
    
    /// Load course and questions from Supabase
    @MainActor
    func loadCourseData() async {
        print("📚 Debug: Loading course data for ID: \(courseId)")
        isLoading = true
        error = nil
        
        do {
            // Load course and questions in parallel
            async let courseTask = supabaseService.fetchCourse(courseId: courseId)
            async let questionsTask = supabaseService.fetchQuestions(courseId: courseId)
            
            let (loadedCourse, loadedQuestions) = try await (courseTask, questionsTask)
            
            // Update state on main thread
            course = loadedCourse
            questions = loadedQuestions
            courseData = CourseData(course: loadedCourse, questions: loadedQuestions)
            
            print("✅ Debug: Successfully loaded course '\(loadedCourse.title)' with \(loadedQuestions.count) questions")
            
        } catch {
            print("❌ Debug: Failed to load course data: \(error.localizedDescription)")
            self.error = getErrorMessage(for: error)
        }
        
        isLoading = false
    }
    
    /// Retry loading course data
    @MainActor
    func retryLoadCourseData() async {
        print("🔄 Debug: Retrying course data load")
        await loadCourseData()
    }
    
    /// Check connection status for debugging
    @MainActor
    func checkConnectionStatus() async -> Bool {
        print("🔍 Debug: Checking connection status")
        let isConnected = await supabaseService.checkConnectionStatus()
        print(isConnected ? "✅ Debug: Connection OK" : "❌ Debug: Connection failed")
        return isConnected
    }
    
    // MARK: - Question Management
    
    /// Check if any questions should be shown at current time
    func checkForQuestions() {
        guard !showQuestion && !questions.isEmpty && currentTime > 0 else { return }
        
        // Find next unanswered question at current timestamp
        if let nextQuestion = questions.enumerated().first(where: { index, question in
            !answeredQuestions.contains(index) && currentTime >= question.timestampSeconds
        }) {
            print("❓ Debug: Showing question at timestamp \(currentTime)s: \(nextQuestion.element.question)")
            currentQuestionIndex = nextQuestion.offset
            showQuestion = true
        }
    }
    
    /// Handle user's answer to a question
    func handleAnswer(isCorrect: Bool, selectedAnswer: String) {
        guard currentQuestionIndex < questions.count else { return }
        
        let question = questions[currentQuestionIndex]
        
        print("✏️ Debug: Answer submitted - Correct: \(isCorrect), Answer: \(selectedAnswer)")
        
        // Update progress
        if isCorrect {
            correctAnswers += 1
        }
        
        // Track result for UI feedback
        let questionId = "0-\(currentQuestionIndex)" // Using segment 0 format
        questionResults[questionId] = isCorrect
        
        // Mark as answered
        answeredQuestions.insert(currentQuestionIndex)
        
        // Track in Supabase (fire and forget for better UX)
        Task {
            do {
                // Note: In a real app, you'd get userId from authentication
                let userId = "anonymous-user" // Placeholder
                try await supabaseService.trackQuestionResponse(
                    userId: userId,
                    questionId: question.id,
                    courseId: courseId,
                    selectedAnswer: selectedAnswer,
                    isCorrect: isCorrect,
                    responseTimeMs: nil
                )
            } catch {
                print("⚠️ Debug: Failed to track question response: \(error)")
            }
        }
    }
    
    /// Continue video after answering question
    func continueVideo() {
        print("▶️ Debug: Continuing video after question")
        showQuestion = false
    }
    
    // MARK: - Video Integration
    
    /// Update current video time and check for questions
    func updateVideoTime(_ time: Double) {
        currentTime = time
        checkForQuestions()
    }
    
    /// Update video duration
    func updateVideoDuration(_ newDuration: Double) {
        duration = newDuration
        print("🎬 Debug: Video duration updated: \(formatTime(newDuration))")
    }
    
    // MARK: - Helper Methods
    
    /// Get user-friendly error message
    private func getErrorMessage(for error: Error) -> String {
        if let courseError = error as? CourseError {
            switch courseError {
            case .timeoutError:
                return "The request timed out. Please check your internet connection and try again."
            case .connectionError:
                return "Unable to connect to the server. Please check your internet connection and try again."
            case .serviceUnavailable:
                return "The service is temporarily unavailable. Please try again in a few minutes."
            case .invalidCourseId:
                return "Invalid course. Please try a different course."
            case .noQuestionsFound:
                return "No questions available for this course."
            case .decodingError:
                return "There was an issue loading the course content. Please try again."
            case .networkError(let message):
                return "Network error: \(message)"
            }
        }
        
        // Fallback for other error types
        return "An unexpected error occurred. Please try again later."
    }
    
    /// Get current question if one is being shown
    var currentQuestion: Question? {
        guard showQuestion && currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    /// Format time in MM:SS format
    func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    /// Get progress percentage
    var progressPercentage: Double {
        guard duration > 0 else { return 0 }
        return (currentTime / duration) * 100
    }
    
    /// Get answered questions count
    var totalQuestionsAnswered: Int {
        return answeredQuestions.count
    }
    
    /// Get success rate
    var successRate: Double {
        guard totalQuestionsAnswered > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestionsAnswered) * 100
    }
    
    // MARK: - Course Statistics
    
    /// Get course statistics for display
    var courseStats: CourseStatistics {
        return CourseStatistics(
            totalQuestions: questions.count,
            answeredQuestions: totalQuestionsAnswered,
            correctAnswers: correctAnswers,
            duration: formatTime(duration),
            progress: progressPercentage
        )
    }
    
    /// Reset course progress (for testing/debugging)
    func resetProgress() {
        print("🔄 Debug: Resetting course progress")
        answeredQuestions.removeAll()
        correctAnswers = 0
        questionResults.removeAll()
        showQuestion = false
        currentQuestionIndex = 0
        currentTime = 0
    }
}

// MARK: - Supporting Types

/// Course statistics for UI display
struct CourseStatistics {
    let totalQuestions: Int
    let answeredQuestions: Int
    let correctAnswers: Int
    let duration: String
    let progress: Double
    
    var successRate: Double {
        guard answeredQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(answeredQuestions) * 100
    }
    
    var hasQuestions: Bool {
        return totalQuestions > 0
    }
} 