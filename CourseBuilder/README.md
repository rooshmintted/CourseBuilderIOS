# CourseBuilder iOS - Interactive Course Player

## Overview

This iOS app replicates the functionality of your React web-based course player, featuring:

- **Interactive Video Questions**: Questions appear at specific timestamps during video playback
- **Supabase Integration**: Loads course content and questions from your Supabase database
- **Progress Tracking**: Tracks user answers and provides real-time feedback
- **Modern SwiftUI UI**: Clean, responsive interface following iOS design patterns

## Architecture

### Key Components

1. **Models.swift** - Data models matching your Supabase schema
2. **SupabaseService.swift** - Service layer for all database operations
3. **CourseViewModel.swift** - Business logic and state management
4. **QuestionOverlay.swift** - Interactive question component
5. **CourseContentView.swift** - Main course display (replaces transcript area)
6. **VideoControlsView.swift** - Testing controls for video simulation

### Data Flow

```
ContentView
    ├── YouTubeVideoView (existing player)
    ├── VideoControlsView (for testing)
    └── CourseContentView
            ├── CourseViewModel (manages state)
            ├── SupabaseService (data layer)
            └── QuestionOverlay (when active)
```

## Setup Instructions

### 1. Configure Supabase

Edit `SupabaseConfig.swift` with your credentials:

```swift
static let supabaseURL = "https://your-project-id.supabase.co"
static let supabaseAnonKey = "your-actual-anon-key"
```

### 2. Database Setup

Your `tables.sql` file contains the schema. Ensure you have test data for course ID `635ac9eb-8876-42fb-a25e-3411b1a68c49`.

### 3. Test Data Example

```sql
-- Insert test course
INSERT INTO courses (id, title, description, youtube_url, published, created_at) VALUES 
('635ac9eb-8876-42fb-a25e-3411b1a68c49', 
 'SwiftUI Fundamentals', 
 'Learn the basics of SwiftUI for iOS development',
 'https://www.youtube.com/watch?v=iSPzVzxF4Cc',
 true,
 NOW());

-- Insert test questions
INSERT INTO questions (course_id, timestamp, question, type, options, correct_answer, explanation) VALUES
('635ac9eb-8876-42fb-a25e-3411b1a68c49', 30, 'What is SwiftUI?', 'multiple-choice', 
 '["A UI framework", "A programming language", "A database", "An IDE"]', '0',
 'SwiftUI is a modern UI framework for building user interfaces across Apple platforms.'),
 
('635ac9eb-8876-42fb-a25e-3411b1a68c49', 90, 'SwiftUI uses declarative syntax?', 'true-false', 
 '["True", "False"]', '0',
 'Yes, SwiftUI uses declarative syntax to describe user interfaces.');
```

## Features Implemented

### ✅ Core Features
- [x] Supabase integration for course and question loading
- [x] Interactive questions at specific timestamps
- [x] Progress tracking and answer validation
- [x] Course information display
- [x] Question results feedback
- [x] Modern SwiftUI design

### ✅ Mirrored React Functionality
- [x] Course header with stats
- [x] Question overlay with multiple choice support
- [x] Progress indicators
- [x] Answer explanations
- [x] Question timing logic

### 🔄 Testing Features
- [x] Video simulation controls (play/pause/seek)
- [x] Debug information panel
- [x] Question preview list
- [x] Progress reset functionality

## Usage

1. **Launch App**: Course data loads automatically for the hardcoded course ID
2. **Video Controls**: Use the play button to start video simulation
3. **Questions**: Questions appear automatically at their timestamps
4. **Testing**: Use the 2x/5x buttons to quickly test different questions
5. **Debug**: View real-time state in the debug section (DEBUG builds only)

## Technical Notes

### Video Player Integration
- Currently uses your existing YouTube iframe player
- Video controls simulate playback for testing interactive features
- Real YouTube API integration would require additional WebKit bridge setup

### State Management
- Uses SwiftUI's `@Observable` macro for reactive updates
- CourseViewModel manages all course-related state
- Automatic question timing based on video progress

### Error Handling
- Comprehensive error handling for network requests
- User-friendly error messages with retry functionality
- Debug logging throughout the app

### Performance
- Async/await for all network operations
- Efficient question lookup using timestamp-based filtering
- Lazy loading for question lists

## Debug Console Output

Watch for these debug messages:
- 🔌 Supabase service initialization
- 📚 Course data loading
- ❓ Question timing and display
- ✏️ Answer tracking
- 🎬 Video state changes

## Next Steps

1. **Real Video Integration**: Implement JavaScript bridge to get actual YouTube player time
2. **User Authentication**: Add Supabase auth for user-specific progress
3. **Offline Support**: Cache course content for offline viewing
4. **Analytics**: Track detailed user interaction metrics
5. **Visual Questions**: Implement hotspot and visual question types

## Rules Applied

- ✅ **Debug logs & comments**: Extensive logging throughout for easier debugging
- ✅ **Simple solutions**: Clean, straightforward architecture
- ✅ **SwiftUI frontend**: Modern SwiftUI-only implementation
- ✅ **@Observable**: Used for reactive state management
- ✅ **No duplication**: Reused existing video player component
- ✅ **Error handling**: Comprehensive error handling with user feedback 