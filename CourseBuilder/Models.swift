//
//  Models.swift
//  CourseBuilder
//
//  Data models for course content and questions
//

import Foundation

// MARK: - Course Data Models

/// Main course information from Supabase
struct Course: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let youtubeUrl: String
    let createdAt: String
    let published: Bool
    
    // Computed properties for UI
    var videoId: String {
        return extractVideoId(from: youtubeUrl)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case youtubeUrl = "youtube_url"
        case createdAt = "created_at"
        case published
    }
    
    /// Extract YouTube video ID from various URL formats
    private func extractVideoId(from url: String) -> String {
        // Debug: Log video ID extraction
        print("🎬 Debug: Extracting video ID from: \(url)")
        
        let patterns = [
            #"(?:youtube\.com/watch\?v=|youtu\.be/|youtube\.com/embed/)([^&\n?#]+)"#,
            #"youtube\.com/watch\?.*v=([^&\n?#]+)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)),
               let range = Range(match.range(at: 1), in: url) {
                let videoId = String(url[range])
                print("✅ Debug: Extracted video ID: \(videoId)")
                return videoId
            }
        }
        
        print("⚠️ Debug: Failed to extract video ID from: \(url)")
        return ""
    }
}

/// Interactive question data from Supabase
struct Question: Codable, Identifiable {
    let id: String
    let courseId: String
    let timestamp: Int
    let question: String
    let type: String
    let options: [String]?
    let correctAnswer: String
    let explanation: String?
    let visualContext: String?
    let frameTimestamp: Int?
    let metadata: QuestionMetadata?
    
    // Computed properties for UI
    var timestampSeconds: Double {
        return Double(timestamp)
    }
    
    var correctAnswerIndex: Int {
        // For multiple choice, correct_answer should be the index
        return Int(correctAnswer) ?? 0
    }
    
    /// For sequencing questions, get the correct order as array of indices
    var correctSequence: [Int] {
        // For sequencing questions, correct_answer should be comma-separated indices
        if type.lowercased() == "sequencing" {
            return correctAnswer.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        }
        return []
    }
    
    var formattedOptions: [String] {
        // Handle true/false questions (case-insensitive)
        let lowerType = type.lowercased()
        if lowerType == "true-false" || lowerType == "true_false" {
            return ["True", "False"]
        }
        
        // For sequencing questions, get items from metadata
        if lowerType == "sequencing" {
            return sequenceItems
        }
        
        // For matching questions, combine left and right items for fallback
        if lowerType == "matching" {
            return leftItems + rightItems
        }
        
        // For multiple choice questions, return the provided options
        if lowerType == "multiple-choice" || lowerType == "multiple_choice" {
            return options ?? []
        }
        
        // Default fallback for any other supported question types
        return options ?? []
    }
    
    /// For sequencing questions, extract sequence items from metadata
    var sequenceItems: [String] {
        guard type.lowercased() == "sequencing",
              let metadata = metadata else {
            return []
        }
        
        // Try to get sequence_items from metadata
        if let sequenceItems = metadata.sequenceItems {
            print("✅ Debug: Found \(sequenceItems.count) sequence items in metadata")
            return sequenceItems
        }
        
        print("⚠️ Debug: No sequence_items found in metadata for sequencing question")
        return []
    }
    
    /// For matching questions, extract matching pairs from metadata
    var matchingPairs: [MatchingPair] {
        guard type.lowercased() == "matching",
              let metadata = metadata else {
            return []
        }
        
        // Try to get matching_pairs from metadata
        if let matchingPairs = metadata.matchingPairs {
            print("✅ Debug: Found \(matchingPairs.count) matching pairs in metadata")
            return matchingPairs
        }
        
        print("⚠️ Debug: No matching_pairs found in metadata for matching question")
        return []
    }
    
    /// For matching questions, get left side items
    var leftItems: [String] {
        return matchingPairs.map { $0.left }
    }
    
    /// For matching questions, get right side items (shuffled)
    var rightItems: [String] {
        return matchingPairs.map { $0.right }.shuffled()
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case courseId = "course_id"
        case timestamp
        case question
        case type
        case options
        case correctAnswer = "correct_answer"
        case explanation
        case visualContext = "visual_context"
        case frameTimestamp = "frame_timestamp"
        case metadata
    }
}

/// Additional question metadata
struct QuestionMetadata: Codable {
    let requiresVideoOverlay: Bool?
    let boundingBoxes: [BoundingBox]?
    let detectedObjects: [DetectedObject]?
    
    // Sequencing question specific metadata
    let sequenceItems: [String]?
    let sequenceType: String?
    let videoOverlay: Bool?
    
    // Matching question specific metadata
    let matchingPairs: [MatchingPair]?
    let relationshipType: String?
    
    enum CodingKeys: String, CodingKey {
        case requiresVideoOverlay = "requires_video_overlay"
        case boundingBoxes = "bounding_boxes"
        case detectedObjects = "detected_objects"
        case sequenceItems = "sequence_items"
        case sequenceType = "sequence_type"
        case videoOverlay = "video_overlay"
        case matchingPairs = "matching_pairs"
        case relationshipType = "relationship_type"
    }
}

/// Matching pair for matching questions
struct MatchingPair: Codable, Identifiable {
    let id = UUID()
    let left: String
    let right: String
    
    enum CodingKeys: String, CodingKey {
        case left, right
    }
}

struct BoundingBox: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let label: String
    let isCorrectAnswer: Bool?
    
    enum CodingKeys: String, CodingKey {
        case x, y, width, height, label
        case isCorrectAnswer = "is_correct_answer"
    }
}

struct DetectedObject: Codable {
    let name: String
    let confidence: Double
}

// MARK: - User Progress Models

/// User enrollment in a course
struct UserCourseEnrollment: Codable {
    let id: String
    let userId: String
    let courseId: String
    let enrolledAt: String
    let progressPercentage: Int
    let currentQuestionIndex: Int
    let totalQuestionsAnswered: Int
    let totalQuestionsCorrect: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case courseId = "course_id"
        case enrolledAt = "enrolled_at"
        case progressPercentage = "progress_percentage"
        case currentQuestionIndex = "current_question_index"
        case totalQuestionsAnswered = "total_questions_answered"
        case totalQuestionsCorrect = "total_questions_correct"
    }
}

/// User response to a specific question
struct QuestionResponse: Codable {
    let questionId: String
    let selectedAnswer: String
    let isCorrect: Bool
    let responseTimeMs: Int?
    
    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case selectedAnswer = "selected_answer"
        case isCorrect = "is_correct"
        case responseTimeMs = "response_time_ms"
    }
}

/// Internal model for parsing Supabase question responses
struct SupabaseQuestionData: Codable {
    let id: String
    let courseId: String
    let timestamp: Int
    let question: String
    let type: String
    let options: [String]?
    let correctAnswer: String
    let explanation: String?
    let visualContext: String?
    let frameTimestamp: Int?
    let metadata: QuestionMetadata?
    
    enum CodingKeys: String, CodingKey {
        case id
        case courseId = "course_id"
        case timestamp
        case question
        case type
        case options
        case correctAnswer = "correct_answer"
        case explanation
        case visualContext = "visual_context"
        case frameTimestamp = "frame_timestamp"
        case metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        courseId = try container.decode(String.self, forKey: .courseId)
        timestamp = try container.decode(Int.self, forKey: .timestamp)
        question = try container.decode(String.self, forKey: .question)
        type = try container.decode(String.self, forKey: .type)
        correctAnswer = try container.decode(String.self, forKey: .correctAnswer)
        explanation = try container.decodeIfPresent(String.self, forKey: .explanation)
        visualContext = try container.decodeIfPresent(String.self, forKey: .visualContext)
        frameTimestamp = try container.decodeIfPresent(Int.self, forKey: .frameTimestamp)
        
        // Handle options as flexible JSON - can be array, JSON string, or null
        if container.contains(.options) {
            if let optionsArray = try? container.decode([String].self, forKey: .options) {
                options = optionsArray
            } else if let optionsString = try? container.decode(String.self, forKey: .options) {
                // Try to parse JSON string into array
                if let jsonData = optionsString.data(using: .utf8),
                   let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [String] {
                    options = jsonArray
                } else {
                    options = nil
                }
            } else {
                options = nil
            }
        } else {
            options = nil
        }
        
        // Handle metadata as flexible JSON - can be object, JSON string, or null
        if container.contains(.metadata) {
            print("🔍 Debug: Metadata field present for question \(id)")
            if let metadataObject = try? container.decode(QuestionMetadata.self, forKey: .metadata) {
                print("✅ Debug: Successfully decoded metadata as object")
                metadata = metadataObject
            } else if let metadataString = try? container.decode(String.self, forKey: .metadata) {
                print("🔍 Debug: Metadata is a string, attempting to parse: \(metadataString.prefix(100))...")
                // Try to parse JSON string into QuestionMetadata object
                if let jsonData = metadataString.data(using: .utf8),
                   let metadataObject = try? JSONDecoder().decode(QuestionMetadata.self, from: jsonData) {
                    print("✅ Debug: Successfully parsed metadata JSON string")
                    metadata = metadataObject
                } else {
                    print("⚠️ Debug: Failed to parse metadata JSON string: \(metadataString)")
                    metadata = nil
                }
            } else {
                print("⚠️ Debug: Metadata field exists but couldn't decode as object or string")
                metadata = nil
            }
        } else {
            print("ℹ️ Debug: No metadata field for question \(id)")
            metadata = nil
        }
    }
}

// MARK: - UI State Models

/// Represents a course segment for UI organization
struct CourseSegment: Identifiable {
    let id = UUID()
    let title: String
    let timestamp: String
    let timestampSeconds: Double
    let concepts: [String]
    let questions: [Question]
}

/// Complete course data for UI presentation
struct CourseData {
    let course: Course
    let questions: [Question]
    let segments: [CourseSegment]
    
    var duration: String {
        // This will be populated from video player
        return "Variable"
    }
    
    init(course: Course, questions: [Question]) {
        self.course = course
        self.questions = questions
        
        // Create a single segment for simplicity (matching React implementation)
        self.segments = [
            CourseSegment(
                title: "Course Content",
                timestamp: "00:00",
                timestampSeconds: 0,
                concepts: [],
                questions: questions
            )
        ]
        
        // Debug: Log course data initialization
        print("📚 Debug: Initialized CourseData with \(questions.count) questions")
    }
}

// MARK: - Error Handling

enum CourseError: Error, LocalizedError {
    case invalidCourseId
    case networkError(String)
    case timeoutError
    case connectionError
    case decodingError(String)
    case noQuestionsFound
    case serviceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidCourseId:
            return "Invalid course ID provided"
        case .networkError(let message):
            return "Network error: \(message)"
        case .timeoutError:
            return "Request timed out. Please check your internet connection and try again."
        case .connectionError:
            return "Unable to connect to the server. Please check your internet connection."
        case .decodingError(let message):
            return "Data parsing error: \(message)"
        case .noQuestionsFound:
            return "No questions found for this course"
        case .serviceUnavailable:
            return "Service is currently unavailable. Please try again later."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .timeoutError, .connectionError:
            return "Check your internet connection and try again. If the problem persists, the server may be experiencing issues."
        case .networkError:
            return "Please try again. If the problem continues, contact support."
        case .serviceUnavailable:
            return "The service is temporarily unavailable. Please try again in a few minutes."
        default:
            return nil
        }
    }
} 