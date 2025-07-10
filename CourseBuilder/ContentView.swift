//
//  ContentView.swift
//  CourseBuilder
//
//  Created by Roosh on 7/10/25.
//

import SwiftUI
import CoreData
import WebKit

// MARK: - YouTube Video Player Component
struct YouTubeVideoView: UIViewRepresentable {
    let videoURL: String
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Force inline media playback - prevent fullscreen
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Additional configuration to prevent fullscreen
        configuration.allowsPictureInPictureMediaPlayback = false
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        // Hide scroll bars and disable scrolling for cleaner look
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        
        // Prevent zooming
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.minimumZoomScale = 1.0
        
        print("Debug: WKWebView configured for inline playback only")
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let embedURL = convertToEmbedURL(from: videoURL)
        
        // Create HTML with CSS to force inline playback and prevent fullscreen
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    background: black;
                    overflow: hidden;
                }
                iframe {
                    width: 100%;
                    height: 100vh;
                    border: none;
                    pointer-events: auto;
                }
                /* Prevent fullscreen overlay */
                .ytp-fullscreen-button {
                    display: none !important;
                }
            </style>
        </head>
        <body>
            <iframe src="\(embedURL)" 
                    allowfullscreen="false"
                    webkitallowfullscreen="false" 
                    mozallowfullscreen="false"
                    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                    frameborder="0">
            </iframe>
        </body>
        </html>
        """
        
        uiView.loadHTMLString(html, baseURL: nil)
        print("Debug: Loading YouTube embed with inline-only HTML wrapper")
    }
    
    // Convert regular YouTube URL to embed format with clean parameters
    private func convertToEmbedURL(from originalURL: String) -> String {
        // Extract video ID from various YouTube URL formats
        var videoID = ""
        
        if let url = URL(string: originalURL) {
            if originalURL.contains("youtube.com/watch") {
                // Format: https://www.youtube.com/watch?v=VIDEO_ID
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let queryItems = components.queryItems,
                   let vParam = queryItems.first(where: { $0.name == "v" }) {
                    videoID = vParam.value ?? ""
                }
            } else if originalURL.contains("youtu.be/") {
                // Format: https://youtu.be/VIDEO_ID
                videoID = url.lastPathComponent
            } else if originalURL.contains("youtube.com/embed/") {
                // Already embed format
                return originalURL
            }
        }
        
        // Build clean embed URL with parameters to hide YouTube UI elements and force inline playback
        let embedURL = "https://www.youtube.com/embed/\(videoID)" +
                      "?autoplay=1" +           // Auto-play the video
                      "&controls=1" +           // Show video controls
                      "&showinfo=0" +           // Hide video info
                      "&rel=0" +                // Don't show related videos
                      "&modestbranding=1" +     // Hide YouTube logo
                      "&fs=0" +                 // Disable fullscreen button
                      "&cc_load_policy=0" +     // Don't show captions by default
                      "&iv_load_policy=3" +     // Hide annotations
                      "&disablekb=1" +          // Disable keyboard controls
                      "&playsinline=1" +        // Force inline playback on iOS
                      "&enablejsapi=1" +        // Enable JavaScript API for better control
                      "&origin=https://localhost" // Set origin for security
        
        print("Debug: Converted URL to embed format: \(embedURL)")
        return embedURL
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("Debug: YouTube video finished loading")
        }
    }
}

// MARK: - Transcript Item Model
struct TranscriptItem: Identifiable {
    let id = UUID()
    let timestamp: String
    let text: String
    let isHighlighted: Bool = false
}

// MARK: - Main Content View
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Sample transcript data - replace with actual data later
    @State private var transcriptItems: [TranscriptItem] = [
        TranscriptItem(timestamp: "00:00", text: "Welcome to today's lesson on SwiftUI fundamentals"),
        TranscriptItem(timestamp: "00:15", text: "We'll start by exploring the basic building blocks"),
        TranscriptItem(timestamp: "00:30", text: "Understanding Views and ViewModifiers is crucial"),
        TranscriptItem(timestamp: "00:45", text: "Let's dive into state management patterns"),
        TranscriptItem(timestamp: "01:00", text: "Property wrappers make everything cleaner"),
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // MARK: - Top Half - YouTube Video
                YouTubeVideoView(videoURL: "https://www.youtube.com/watch?v=iSPzVzxF4Cc")
                    .frame(height: geometry.size.height / 2)
                    .background(Color.black)
                    .cornerRadius(12)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                
                // MARK: - Bottom Half - Transcript Area
                VStack(alignment: .leading, spacing: 0) {
                    // Transcript Header
                    HStack {
                        Text("📝 Transcript")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("Tap to jump to timestamp")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    // Transcript Items
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(transcriptItems) { item in
                                TranscriptItemView(item: item) {
                                    // Handle transcript item tap
                                    print("Debug: Tapped transcript at \(item.timestamp)")
                                    // TODO: Implement video seeking functionality
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
                .frame(height: geometry.size.height / 2)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .background(Color(.systemGray6))
        .onAppear {
            print("Debug: ContentView appeared - split screen layout initialized")
        }
    }
}

// MARK: - Transcript Item View Component
struct TranscriptItemView: View {
    let item: TranscriptItem
    let onTap: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timestamp Badge
            Text(item.timestamp)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(6)
            
            // Transcript Text
            Text(item.text)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
