//
//  VideoControlsView.swift
//  CourseBuilder
//
//  Video controls display for showing current YouTube player status
//

import SwiftUI

/// Compact video controls for displaying video playback status
struct VideoControlsView: View {
    
    // MARK: - Properties
    
    let currentTime: Double
    let duration: Double
    let isPlaying: Bool
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 4) {
            // Compact progress bar
            VStack(spacing: 2) {
                HStack {
                    Text(formatTime(currentTime))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Playing status indicator
                    HStack(spacing: 4) {
                        Image(systemName: statusIcon)
                            .font(.caption2)
                            .foregroundColor(statusColor)
                        
                        Text(statusText)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(formatTime(duration))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                // Read-only progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 3)
                        
                        // Progress indicator
                        Rectangle()
                            .fill(progressColor)
                            .frame(width: max(0, geometry.size.width * progress), height: 3)
                            .animation(.linear(duration: 0.1), value: progress)
                    }
                    .cornerRadius(1.5)
                }
                .frame(height: 3)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .cornerRadius(6)
        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
    
    // MARK: - Computed Properties
    
    private var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(currentTime / duration, 0), 1)
    }
    
    private var statusIcon: String {
        if duration == 0 && currentTime == 0 {
            return "clock.fill"
        }
        return isPlaying ? "play.fill" : "pause.fill"
    }
    
    private var statusColor: Color {
        if duration == 0 && currentTime == 0 {
            return .orange
        }
        return isPlaying ? .green : .orange
    }
    
    private var statusText: String {
        if duration == 0 && currentTime == 0 {
            return "Loading..."
        }
        return isPlaying ? "Playing" : "Paused"
    }
    
    private var progressColor: Color {
        if duration == 0 && currentTime == 0 {
            return .orange
        }
        return .blue
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "00:00" }
        
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        VideoControlsView(
            currentTime: 45,
            duration: 300,
            isPlaying: true
        )
        
        VideoControlsView(
            currentTime: 0,
            duration: 0,
            isPlaying: false
        )
        
        VideoControlsView(
            currentTime: 150,
            duration: 300,
            isPlaying: false
        )
    }
    .padding()
} 