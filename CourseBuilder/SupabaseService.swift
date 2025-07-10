//
//  SupabaseService.swift
//  CourseBuilder
//
//  Service for handling all Supabase data operations
//

import Foundation
import Supabase

/// Main service for interacting with Supabase backend
@Observable
final class SupabaseService {
    
    // MARK: - Properties
    
    static let shared = SupabaseService()
    
    private var client: SupabaseClient
    
    // MARK: - Initialization
    
    private init() {
        // Debug: Log Supabase initialization
        print("🔌 Debug: Initializing Supabase service...")
        print("🔧 Debug: \(SupabaseConfig.statusMessage)")
        
        guard let supabaseURL = URL(string: SupabaseConfig.supabaseURL) else {
            fatalError("Invalid Supabase URL in SupabaseConfig. Please check your configuration.")
        }
        
        // Initialize Supabase client with default configuration
        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: SupabaseConfig.supabaseAnonKey)
        
        if SupabaseConfig.isConfigured {
            print("✅ Debug: Supabase service initialized successfully")
            print("🌐 Debug: URL: \(supabaseURL)")
            print("🔑 Debug: Using configured API key")
        } else {
            print("⚠️ Debug: Supabase service initialized with placeholder credentials - please update SupabaseConfig.swift")
        }
        
        // Test basic connectivity (optional)
        Task {
            await testConnection()
        }
    }
    
    // MARK: - Connection Testing
    
    /// Test basic connectivity to Supabase
    private func testConnection() async {
        do {
            // Simple query to test connection
            let _: [Course] = try await client
                .from("courses")
                .select("id")
                .limit(1)
                .execute()
                .value
            
            print("✅ Debug: Supabase connection test successful")
        } catch {
            print("⚠️ Debug: Supabase connection test failed: \(error.localizedDescription)")
            print("💡 Debug: This might indicate network issues or incorrect configuration")
        }
    }
    
    /// Check if Supabase service is reachable
    func checkConnectionStatus() async -> Bool {
        do {
            let _: [Course] = try await client
                .from("courses")
                .select("id")
                .limit(1)
                .execute()
                .value
            
            print("✅ Debug: Connection status check: OK")
            return true
        } catch {
            print("❌ Debug: Connection status check failed: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Course Operations
    
    /// Fetch course details by ID with retry logic
    func fetchCourse(courseId: String) async throws -> Course {
        print("📚 Debug: Fetching course with ID: \(courseId)")
        
        guard !courseId.isEmpty else {
            print("❌ Debug: Invalid course ID provided")
            throw CourseError.invalidCourseId
        }
        
        return try await withRetry(maxAttempts: 3, delay: 1.0) {
            do {
                let response: Course = try await self.client
                    .from("courses")
                    .select()
                    .eq("id", value: courseId)
                    .single()
                    .execute()
                    .value
                
                print("✅ Debug: Successfully fetched course: \(response.title)")
                return response
                
            } catch let error as DecodingError {
                print("❌ Debug: Failed to decode course data: \(error)")
                throw CourseError.decodingError("Failed to parse course data")
            } catch {
                print("❌ Debug: Network error fetching course: \(error.localizedDescription)")
                // Map specific error types for better user experience
                let errorMessage = error.localizedDescription.lowercased()
                
                if errorMessage.contains("timed out") || errorMessage.contains("timeout") {
                    throw CourseError.timeoutError
                } else if errorMessage.contains("network") || errorMessage.contains("connection") {
                    throw CourseError.connectionError
                } else if errorMessage.contains("unavailable") || errorMessage.contains("502") || errorMessage.contains("503") {
                    throw CourseError.serviceUnavailable
                } else {
                    // For retryable errors, throw the original error to trigger retry
                    if errorMessage.contains("retry") || errorMessage.contains("temporary") {
                        throw error
                    } else {
                        throw CourseError.networkError(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    /// Fetch questions for a specific course with retry logic
    func fetchQuestions(courseId: String) async throws -> [Question] {
        print("❓ Debug: Fetching questions for course: \(courseId)")
        
        guard !courseId.isEmpty else {
            print("❌ Debug: Invalid course ID for questions")
            throw CourseError.invalidCourseId
        }
        
        return try await withRetry(maxAttempts: 3, delay: 1.0) {
            do {
                // Fetch questions from Supabase with proper JSON handling
                let response: [SupabaseQuestionData] = try await self.client
                    .from("questions")
                    .select("""
                        id,
                        course_id,
                        timestamp,
                        question,
                        type,
                        options,
                        correct_answer,
                        explanation,
                        visual_context,
                        frame_timestamp,
                        metadata
                    """)
                    .eq("course_id", value: courseId)
                    .order("timestamp", ascending: true)
                    .execute()
                    .value
                
                // Convert response to Question models with proper options parsing
                let questions = response.compactMap { questionData -> Question? in
                    do {
                        let question = try self.parseQuestionResponse(questionData)
                        print("✅ Debug: Successfully parsed question: \(question.id) - \(question.question.prefix(50))...")
                        return question
                    } catch {
                        print("⚠️ Debug: Failed to parse question \(questionData.id): \(error)")
                        print("🔍 Debug: Question data - Type: \(questionData.type), Options: \(String(describing: questionData.options))")
                        return nil
                    }
                }
                
                print("✅ Debug: Successfully fetched \(questions.count) questions")
                return questions
                
            } catch let error as DecodingError {
                print("❌ Debug: Failed to decode questions data: \(error)")
                throw CourseError.decodingError("Failed to parse questions data")
            } catch {
                print("❌ Debug: Network error fetching questions: \(error.localizedDescription)")
                // Map specific error types for better user experience
                let errorMessage = error.localizedDescription.lowercased()
                
                if errorMessage.contains("timed out") || errorMessage.contains("timeout") {
                    throw CourseError.timeoutError
                } else if errorMessage.contains("network") || errorMessage.contains("connection") {
                    throw CourseError.connectionError
                } else if errorMessage.contains("unavailable") || errorMessage.contains("502") || errorMessage.contains("503") {
                    throw CourseError.serviceUnavailable
                } else {
                    // For retryable errors, throw the original error to trigger retry
                    if errorMessage.contains("retry") || errorMessage.contains("temporary") {
                        throw error
                    } else {
                        throw CourseError.networkError(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    // MARK: - User Progress Operations
    
    /// Track user enrollment in a course
    func trackCourseEnrollment(userId: String, courseId: String) async throws {
        print("📝 Debug: Tracking enrollment for user \(userId) in course \(courseId)")
        
        do {
            // Check if enrollment already exists
            let existingEnrollment: [UserCourseEnrollment]? = try? await client
                .from("user_course_enrollments")
                .select()
                .eq("user_id", value: userId)
                .eq("course_id", value: courseId)
                .execute()
                .value
            
            if existingEnrollment?.isEmpty == false {
                print("ℹ️ Debug: User already enrolled in course")
                return
            }
            
            // Create new enrollment with properly typed struct
            let enrollment = UserCourseEnrollmentInsert(
                userId: userId,
                courseId: courseId,
                progressPercentage: 0,
                currentQuestionIndex: 0,
                totalQuestionsAnswered: 0,
                totalQuestionsCorrect: 0
            )
            
            try await client
                .from("user_course_enrollments")
                .insert(enrollment)
                .execute()
            
            print("✅ Debug: Successfully tracked course enrollment")
            
        } catch {
            print("❌ Debug: Failed to track enrollment: \(error.localizedDescription)")
            throw CourseError.networkError(error.localizedDescription)
        }
    }
    
    /// Track user's response to a question
    func trackQuestionResponse(
        userId: String,
        questionId: String,
        courseId: String,
        selectedAnswer: String,
        isCorrect: Bool,
        responseTimeMs: Int?
    ) async throws {
        print("📊 Debug: Tracking question response for question \(questionId)")
        
        do {
            // Convert selectedAnswer to integer if it's a numeric string, otherwise use 0
            let selectedAnswerInt = Int(selectedAnswer) ?? 0
            
            // Create properly typed struct for database insertion
            let response = UserQuestionResponseInsert(
                userId: userId,
                questionId: questionId,
                selectedAnswer: selectedAnswerInt,
                isCorrect: isCorrect,
                responseTimeMs: responseTimeMs ?? 0
            )
            
            try await client
                .from("user_question_responses")
                .insert(response)
                .execute()
            
            print("✅ Debug: Successfully tracked question response")
            
        } catch {
            print("❌ Debug: Failed to track question response: \(error.localizedDescription)")
            throw CourseError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Retry function with exponential backoff and smart error handling
    private func withRetry<T>(
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                print("⚠️ Debug: Attempt \(attempt)/\(maxAttempts) failed: \(error.localizedDescription)")
                
                // Check if this error should stop retrying
                if !shouldRetryError(error) {
                    print("🚫 Debug: Error is not retryable, stopping attempts")
                    throw error
                }
                
                if attempt < maxAttempts {
                    let backoffDelay = delay * pow(2.0, Double(attempt - 1))
                    print("🔄 Debug: Retrying in \(backoffDelay) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? CourseError.networkError("Maximum retry attempts exceeded")
    }
    
    /// Determine if an error should trigger a retry
    private func shouldRetryError(_ error: Error) -> Bool {
        // Don't retry certain types of errors
        if let courseError = error as? CourseError {
            switch courseError {
            case .invalidCourseId, .decodingError, .noQuestionsFound:
                return false // These won't be fixed by retrying
            case .timeoutError, .connectionError, .serviceUnavailable, .networkError:
                return true // These might be temporary
            }
        }
        
        // For other errors, check the description
        let errorMessage = error.localizedDescription.lowercased()
        
        // Don't retry authentication or authorization errors
        if errorMessage.contains("unauthorized") || errorMessage.contains("forbidden") || errorMessage.contains("401") || errorMessage.contains("403") {
            return false
        }
        
        // Don't retry bad request errors
        if errorMessage.contains("bad request") || errorMessage.contains("400") || errorMessage.contains("404") {
            return false
        }
        
        // Retry network, timeout, and server errors
        return errorMessage.contains("timeout") || 
               errorMessage.contains("network") || 
               errorMessage.contains("connection") ||
               errorMessage.contains("502") ||
               errorMessage.contains("503") ||
               errorMessage.contains("504") ||
               errorMessage.contains("temporary")
    }
    
    /// Parse question response from Supabase with proper options handling
    private func parseQuestionResponse(_ data: SupabaseQuestionData) throws -> Question {
        // Options are already parsed in SupabaseQuestionData
        var parsedOptions = data.options
        
        // Handle true/false questions specifically
        if data.type == "true-false" || data.type == "true_false" {
            parsedOptions = ["True", "False"]
        }
        
        return Question(
            id: data.id,
            courseId: data.courseId,
            timestamp: data.timestamp,
            question: data.question,
            type: data.type,
            options: parsedOptions,
            correctAnswer: data.correctAnswer,
            explanation: data.explanation,
            visualContext: data.visualContext,
            frameTimestamp: data.frameTimestamp,
            metadata: data.metadata
        )
    }
    
    /// Format timestamp from seconds to MM:SS
    static func formatTimestamp(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Database Insert Models

/// Data structure for inserting user question responses into Supabase
private struct UserQuestionResponseInsert: Codable {
    let userId: String
    let questionId: String
    let selectedAnswer: Int
    let isCorrect: Bool
    let responseTimeMs: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case questionId = "question_id"
        case selectedAnswer = "selected_answer"
        case isCorrect = "is_correct"
        case responseTimeMs = "response_time_ms"
    }
}

/// Data structure for inserting user course enrollments into Supabase
private struct UserCourseEnrollmentInsert: Codable {
    let userId: String
    let courseId: String
    let progressPercentage: Int
    let currentQuestionIndex: Int
    let totalQuestionsAnswered: Int
    let totalQuestionsCorrect: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case courseId = "course_id"
        case progressPercentage = "progress_percentage"
        case currentQuestionIndex = "current_question_index"
        case totalQuestionsAnswered = "total_questions_answered"
        case totalQuestionsCorrect = "total_questions_correct"
    }
}

 
