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
    @Binding var currentTime: Double
    @Binding var duration: Double
    @Binding var isPlaying: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Add script message handler for YouTube player updates
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "videoUpdate")
        configuration.userContentController = userContentController
        
        // Force inline media playback - prevent fullscreen
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
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
        
        // Set up the coordinator with bindings immediately
        context.coordinator.updateBindings(currentTime: $currentTime, duration: $duration, isPlaying: $isPlaying)
        
        print("🎥 Debug: WKWebView configured for inline playback with JavaScript API")
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Update bindings on every update
        context.coordinator.updateBindings(currentTime: $currentTime, duration: $duration, isPlaying: $isPlaying)
        
        // Only load HTML if it hasn't been loaded yet or if the video URL changed
        let videoID = extractVideoID(from: videoURL)
        
        // Check if we need to reload (avoid unnecessary reloads)
        if context.coordinator.currentVideoID != videoID {
            context.coordinator.currentVideoID = videoID
            loadYouTubePlayer(in: uiView, videoID: videoID)
        }
    }
    
    private func loadYouTubePlayer(in webView: WKWebView, videoID: String) {
        // Create HTML with proper YouTube iframe API implementation
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
                #player {
                    width: 100%;
                    height: 100vh;
                }
            </style>
        </head>
        <body>
            <div id="player"></div>
            
            <script>
                var player;
                var updateInterval;
                
                // Load YouTube iframe API
                var tag = document.createElement('script');
                tag.src = "https://www.youtube.com/iframe_api";
                var firstScriptTag = document.getElementsByTagName('script')[0];
                firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
                
                // YouTube API ready callback
                function onYouTubeIframeAPIReady() {
                    console.log('🎬 YouTube API Ready');
                    player = new YT.Player('player', {
                        height: '100%',
                        width: '100%',
                        videoId: '\(videoID)',
                        playerVars: {
                            'autoplay': 1,
                            'controls': 1,
                            'showinfo': 0,
                            'rel': 0,
                            'modestbranding': 1,
                            'fs': 0,
                            'cc_load_policy': 0,
                            'iv_load_policy': 3,
                            'playsinline': 1,
                            'enablejsapi': 1,
                            'origin': window.location.origin
                        },
                        events: {
                            'onReady': onPlayerReady,
                            'onStateChange': onPlayerStateChange
                        }
                    });
                }
                
                function onPlayerReady(event) {
                    console.log('🎯 Player Ready');
                    // Send initial state immediately
                    updatePlayerInfo();
                    startUpdateLoop();
                }
                
                function onPlayerStateChange(event) {
                    console.log('🔄 Player State Changed:', event.data);
                    updatePlayerInfo();
                }
                
                function startUpdateLoop() {
                    // Clear any existing interval
                    if (updateInterval) {
                        clearInterval(updateInterval);
                    }
                    // Update every 500ms for smooth progress
                    updateInterval = setInterval(updatePlayerInfo, 500);
                }
                
                function updatePlayerInfo() {
                    if (player && player.getCurrentTime && player.getDuration && player.getPlayerState) {
                        try {
                            var currentTime = player.getCurrentTime() || 0;
                            var duration = player.getDuration() || 0;
                            var playerState = player.getPlayerState();
                            
                            // YouTube player states: -1 (unstarted), 0 (ended), 1 (playing), 2 (paused), 3 (buffering), 5 (video cued)
                            var isPlaying = playerState === 1;
                            
                            console.log('⏱️ Sending update - Time:', currentTime, 'Duration:', duration, 'State:', playerState, 'Playing:', isPlaying);
                            
                            // Send to Swift
                            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.videoUpdate) {
                                window.webkit.messageHandlers.videoUpdate.postMessage({
                                    type: 'progress',
                                    currentTime: currentTime,
                                    duration: duration,
                                    playerState: playerState,
                                    isPlaying: isPlaying
                                });
                            } else {
                                console.log('❌ Message handler not available');
                            }
                        } catch (error) {
                            console.log('❌ Error getting player info:', error);
                        }
                    } else {
                        console.log('⚠️ Player not ready yet');
                    }
                }
                
                // Cleanup on page unload
                window.addEventListener('beforeunload', function() {
                    if (updateInterval) {
                        clearInterval(updateInterval);
                    }
                });
            </script>
        </body>
        </html>
        """
        
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
        print("🎬 Debug: Loading YouTube player with video ID: \(videoID)")
    }
    
    // Extract video ID from various YouTube URL formats
    private func extractVideoID(from originalURL: String) -> String {
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
                // Already embed format - extract ID
                let pathComponents = url.pathComponents
                if pathComponents.count > 2 {
                    videoID = pathComponents[2].components(separatedBy: "?").first ?? ""
                }
            }
        }
        
        print("🆔 Debug: Extracted video ID: \(videoID)")
        return videoID
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        // Keep track of bindings
        private var currentTimeBinding: Binding<Double>?
        private var durationBinding: Binding<Double>?
        private var isPlayingBinding: Binding<Bool>?
        
        // Keep track of current video to avoid unnecessary reloads
        var currentVideoID: String = ""
        
        func updateBindings(currentTime: Binding<Double>, duration: Binding<Double>, isPlaying: Binding<Bool>) {
            self.currentTimeBinding = currentTime
            self.durationBinding = duration
            self.isPlayingBinding = isPlaying
            print("🔗 Debug: Bindings updated in coordinator")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("🎯 Debug: YouTube video finished loading")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ Debug: WebView navigation failed: \(error)")
        }
        
        // Handle messages from JavaScript
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            print("📨 Debug: Received message from JavaScript: \(message.body)")
            
            guard message.name == "videoUpdate",
                  let body = message.body as? [String: Any],
                  let type = body["type"] as? String else {
                print("❌ Debug: Invalid message format")
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                switch type {
                case "progress":
                    if let currentTime = body["currentTime"] as? Double {
                        self.currentTimeBinding?.wrappedValue = currentTime
                        print("⏱️ Debug: Updated currentTime to: \(String(format: "%.1f", currentTime))s")
                    }
                    if let duration = body["duration"] as? Double {
                        self.durationBinding?.wrappedValue = duration
                        print("⏰ Debug: Updated duration to: \(String(format: "%.1f", duration))s")
                    }
                    if let isPlaying = body["isPlaying"] as? Bool {
                        self.isPlayingBinding?.wrappedValue = isPlaying
                        print("▶️ Debug: Updated playing state to: \(isPlaying)")
                    }
                    if let playerState = body["playerState"] as? Int {
                        print("🎮 Debug: Player state: \(playerState)")
                    }
                default:
                    print("🔍 Debug: Unknown message type: \(type)")
                }
            }
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Course view model for Supabase integration
    let courseViewModel = CourseViewModel()
    
    // Real video time from YouTube player
    @State private var realCurrentTime: Double = 0
    @State private var realDuration: Double = 0
    @State private var realIsPlaying: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // MARK: - Top Half - YouTube Video
                VStack(spacing: 4) {
                    YouTubeVideoView(
                        videoURL: courseViewModel.course?.youtubeUrl ?? "https://www.youtube.com/watch?v=iSPzVzxF4Cc",
                        currentTime: $realCurrentTime,
                        duration: $realDuration,
                        isPlaying: $realIsPlaying
                    )
                    .frame(height: geometry.size.height / 2 - 60)
                    .background(Color.black)
                    .cornerRadius(12)
                    
                    // Smaller video controls
                    VideoControlsView(
                        currentTime: realCurrentTime,
                        duration: realDuration,
                        isPlaying: realIsPlaying
                    )
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                
                // MARK: - Bottom Half - Scrollable Course Content
                ScrollView(.vertical, showsIndicators: true) {
                    CourseContentView(viewModel: courseViewModel)
                        .padding(.horizontal, 8)
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
            print("🚀 Debug: ContentView appeared with real video time tracking")
        }
        .onChange(of: realCurrentTime) { _, newTime in
            // Update course view model with real video time
            courseViewModel.updateVideoTime(newTime)
        }
        .onChange(of: realDuration) { _, newDuration in
            courseViewModel.updateVideoDuration(newDuration)
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
