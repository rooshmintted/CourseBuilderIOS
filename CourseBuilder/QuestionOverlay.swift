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
    
    // Sequencing-specific state
    @State private var sequencingItems: [SequencingItem] = []
    @State private var draggedItem: SequencingItem?
    
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
                
                // Answer options based on question type
                if question.type.lowercased() == "sequencing" {
                    SequencingQuestionView(
                        items: $sequencingItems,
                        draggedItem: $draggedItem,
                        hasAnswered: hasAnswered,
                        correctSequence: question.correctSequence
                    ) { userSequence in
                        handleSequencingAnswer(userSequence: userSequence)
                    }
                } else if !question.formattedOptions.isEmpty {
                    // Existing multiple choice/true-false UI
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
            
            // Initialize sequencing items if it's a sequencing question
            if question.type.lowercased() == "sequencing" {
                initializeSequencingItems()
            }
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
    
    /// Initialize sequencing items with shuffled order
    private func initializeSequencingItems() {
        let options = question.formattedOptions
        print("🔍 Debug: Sequencing question initialization")
        print("📋 Debug: Question type: \(question.type)")
        print("📊 Debug: Metadata exists: \(question.metadata != nil)")
        print("🔢 Debug: Found \(options.count) sequence items: \(options)")
        
        var items: [SequencingItem] = []
        
        for (index, option) in options.enumerated() {
            items.append(SequencingItem(
                id: UUID(),
                originalIndex: index,
                content: option,
                currentPosition: index
            ))
            print("➕ Debug: Added item \(index): \(option.prefix(50))...")
        }
        
        // Shuffle the items for the user to reorder
        sequencingItems = items.shuffled()
        
        // Update current positions after shuffling
        for (index, _) in sequencingItems.enumerated() {
            sequencingItems[index].currentPosition = index
        }
        
        print("🔀 Debug: Initialized \(sequencingItems.count) sequencing items")
        if sequencingItems.isEmpty {
            print("❌ Debug: No sequencing items found! Check metadata parsing.")
        }
    }
    
    /// Handle sequencing question answer submission
    private func handleSequencingAnswer(userSequence: [Int]) {
        guard !hasAnswered else { return }
        
        hasAnswered = true
        
        let correctSequence = question.correctSequence
        let isCorrect = userSequence == correctSequence
        let responseTime = Int(Date().timeIntervalSince(questionStartTime) * 1000)
        
        print("📝 Debug: Sequencing answer submitted")
        print("✅ Debug: User sequence: \(userSequence)")
        print("🎯 Debug: Correct sequence: \(correctSequence)")
        print("✏️ Debug: Answer correct: \(isCorrect), Time: \(responseTime)ms")
        
        // Show explanation automatically if available
        if question.explanation != nil {
            showExplanation = true
        }
        
        // Convert user sequence to string for storage
        let sequenceString = userSequence.map { String($0) }.joined(separator: ",")
        
        // Call the answer handler
        onAnswer(isCorrect, sequenceString)
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

// MARK: - Sequencing Item Model

/// Model for individual sequencing items
struct SequencingItem: Identifiable, Equatable {
    let id: UUID
    let originalIndex: Int
    let content: String
    var currentPosition: Int
    
    static func == (lhs: SequencingItem, rhs: SequencingItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sequencing Question View

/// Drag-and-drop sequencing question interface
struct SequencingQuestionView: View {
    @Binding var items: [SequencingItem]
    @Binding var draggedItem: SequencingItem?
    let hasAnswered: Bool
    let correctSequence: [Int]
    let onSubmit: ([Int]) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Instructions
            if !hasAnswered {
                HStack {
                    Image(systemName: "hand.tap.fill")
                        .foregroundColor(.blue)
                    Text("Tap and hold any item to drag and reorder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
            }
            
            // Sequencing items
            LazyVStack(spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    SequencingItemView(
                        item: item,
                        position: index + 1,
                        hasAnswered: hasAnswered,
                        isCorrectPosition: hasAnswered ? isItemInCorrectPosition(item: item, atIndex: index) : nil,
                        draggedItem: $draggedItem
                    )
                    .onDrop(of: [.text], delegate: SequencingDropDelegate(
                        item: item,
                        items: $items,
                        draggedItem: $draggedItem,
                        hasAnswered: hasAnswered
                    ))
                }
            }
            
            // Submit button for sequencing
            if !hasAnswered {
                Button("Submit Answer") {
                    let userSequence = items.map { $0.originalIndex }
                    onSubmit(userSequence)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 8)
    }
    
    /// Check if an item is in the correct position
    private func isItemInCorrectPosition(item: SequencingItem, atIndex index: Int) -> Bool {
        guard index < correctSequence.count else { return false }
        return correctSequence[index] == item.originalIndex
    }
}

// MARK: - Sequencing Item View

/// Individual sequencing item with drag handle
struct SequencingItemView: View {
    let item: SequencingItem
    let position: Int
    let hasAnswered: Bool
    let isCorrectPosition: Bool?
    @Binding var draggedItem: SequencingItem?
    
    @State private var isDragging = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Position indicator
            Text("\(position)")
                .font(.headline)
                .fontWeight(.bold)
                .frame(width: 28, height: 28)
                .background(positionBackground)
                .foregroundColor(positionForeground)
                .clipShape(Circle())
            
            // Item content
            Text(item.content)
                .font(.body)
                .multilineTextAlignment(.leading)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Drag handle or feedback icon
            if hasAnswered {
                Image(systemName: feedbackIcon)
                    .foregroundColor(feedbackColor)
                    .font(.title3)
            } else {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.secondary)
                    .font(.title3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(itemBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .cornerRadius(8)
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .opacity(isDragging ? 0.8 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isDragging)
        .onDrag {
            guard !hasAnswered else {
                return NSItemProvider()
            }
            
            // Provide stronger haptic feedback when drag starts
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.prepare()
            impact.impactOccurred()
            
            isDragging = true
            draggedItem = item
            print("🎯 Debug: Started dragging item: \(item.content.prefix(50))...")
            
            return NSItemProvider(object: item.id.uuidString as NSString)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 5, coordinateSpace: .global)
                .onChanged { _ in
                    guard !hasAnswered && !isDragging else { return }
                    
                    // Start visual feedback immediately when drag starts
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isDragging = true
                    }
                    
                    // Provide immediate haptic feedback
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.prepare()
                    impact.impactOccurred()
                    
                    print("🚀 Debug: Fast drag detection triggered")
                }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.1)
                .onEnded { _ in
                    guard !hasAnswered else { return }
                    
                    // Provide haptic feedback for long press (indicates draggable)
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.prepare()
                    impact.impactOccurred()
                    
                    print("🤏 Debug: Long press detected on item")
                }
        )
        .onTapGesture {
            // Provide haptic feedback when tapping (to indicate it's draggable)
            if !hasAnswered {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.prepare()
                impact.impactOccurred()
                print("👆 Debug: Tap detected on item")
            }
        }
        .onChange(of: draggedItem) { _, newValue in
            // Reset dragging state when drag ends
            if newValue?.id != item.id {
                isDragging = false
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var positionBackground: Color {
        if hasAnswered {
            return isCorrectPosition == true ? .green : .red
        }
        return .blue
    }
    
    private var positionForeground: Color {
        return .white
    }
    
    private var itemBackground: Color {
        if hasAnswered {
            return isCorrectPosition == true ? Color.green.opacity(0.1) : Color.red.opacity(0.1)
        }
        return Color(.systemGray6)
    }
    
    private var borderColor: Color {
        if hasAnswered {
            return isCorrectPosition == true ? .green : .red
        }
        return Color(.systemGray4)
    }
    
    private var borderWidth: Double {
        return hasAnswered ? 2.0 : 1.0
    }
    
    private var feedbackIcon: String {
        if isCorrectPosition == true {
            return "checkmark.circle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    private var feedbackColor: Color {
        return isCorrectPosition == true ? .green : .red
    }
}

// MARK: - Drop Delegate

/// Drop delegate for handling drag and drop reordering
struct SequencingDropDelegate: DropDelegate {
    let item: SequencingItem
    @Binding var items: [SequencingItem]
    @Binding var draggedItem: SequencingItem?
    let hasAnswered: Bool
    
    func performDrop(info: DropInfo) -> Bool {
        guard !hasAnswered else { return false }
        
        print("🎯 Debug: Drop completed")
        
        // Reset dragged item with a slight delay to allow animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            draggedItem = nil
        }
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard !hasAnswered else { return }
        
        guard let draggedItem = draggedItem else { return }
        
        if draggedItem != item {
            let fromIndex = items.firstIndex(of: draggedItem) ?? 0
            let toIndex = items.firstIndex(of: item) ?? 0
            
            if fromIndex != toIndex {
                withAnimation(.spring()) {
                    items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
                }
                
                print("🔄 Debug: Reordered item from position \(fromIndex + 1) to \(toIndex + 1)")
            }
        }
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