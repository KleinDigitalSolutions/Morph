import SwiftUI
import AVKit

public struct ResultPlaybackView: View {
    public let task: RenderTask
    
    @State private var showOriginal = false
    @State private var originalPlayer: AVPlayer? = nil
    @State private var resultPlayer: AVPlayer? = nil
    
    @Environment(\.dismiss) private var dismiss
    
    public var body: some View {
        ZStack {
            // Background
            Color(red: 0.05, green: 0.05, blue: 0.08)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Custom Bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Dashboard")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(red: 0.1, green: 0.8, blue: 1.0))
                    }
                    
                    Spacer()
                    
                    Text("Studio Results")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    // Share Actions
                    if let resultUrl = resolvedResultURL {
                        ShareLink(item: resultUrl) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(red: 0.1, green: 0.8, blue: 1.0))
                                .padding(8)
                                .background(.white.opacity(0.06))
                                .clipShape(Circle())
                        }
                    } else {
                        Spacer()
                            .frame(width: 44)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // Segmented Before/After Control
                HStack(spacing: 4) {
                    Button {
                        showOriginal = true
                    } label: {
                        Text("Before")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(showOriginal ? .white : .white.opacity(0.4))
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(showOriginal ? Color(red: 0.6, green: 0.3, blue: 1.0) : Color.clear)
                            .clipShape(Capsule())
                    }
                    
                    Button {
                        showOriginal = false
                    } label: {
                        Text("After (AI Swap)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(!showOriginal ? .white : .white.opacity(0.4))
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(!showOriginal ? Color(red: 0.6, green: 0.3, blue: 1.0) : Color.clear)
                            .clipShape(Capsule())
                    }
                }
                .padding(4)
                .background(.white.opacity(0.06))
                .clipShape(Capsule())
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
                
                // Video Player Stage
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.black)
                        .overlay {
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(.white.opacity(0.08), lineWidth: 1)
                        }
                    
                    if showOriginal {
                        if let player = originalPlayer {
                            VideoPlayer(player: player)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .onAppear {
                                    resultPlayer?.pause()
                                    player.play()
                                }
                        } else {
                            VStack(spacing: 8) {
                                ProgressView()
                                    .tint(.white)
                                Text("Loading original asset...")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                    } else {
                        if let player = resultPlayer {
                            VideoPlayer(player: player)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .onAppear {
                                    originalPlayer?.pause()
                                    player.play()
                                }
                        } else {
                            VStack(spacing: 8) {
                                ProgressView()
                                    .tint(.white)
                                Text("Downloading AI transformation...")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                    }
                }
                .aspectRatio(9/16, contentMode: .fit)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
                // Info Summary Card
                GlassCard(cornerRadius: 16, borderOpacity: 0.1, backgroundOpacity: 0.2) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(task.mode.title)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            Text("FastAPI + Vertex AI")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(Color(red: 0.1, green: 0.8, blue: 1.0))
                        }
                        
                        Text("Task ID: \(task.id)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                        
                        Divider()
                            .background(.white.opacity(0.08))
                            .padding(.vertical, 4)
                        
                        Text("Creations are saved locally under your profile settings feed.")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            initializePlayers()
        }
        .onDisappear {
            originalPlayer?.pause()
            resultPlayer?.pause()
        }
    }
    
    private var resolvedOriginalURL: URL? {
        guard let originalStr = task.originalVideoUrl else { return nil }
        if originalStr.hasPrefix("http") {
            return URL(string: originalStr)
        } else {
            return URL(fileURLWithPath: originalStr)
        }
    }
    
    private var resolvedResultURL: URL? {
        guard let resultStr = task.resultVideoUrl else { return nil }
        if resultStr.hasPrefix("http") {
            return URL(string: resultStr)
        } else {
            return URL(fileURLWithPath: resultStr)
        }
    }
    
    private func initializePlayers() {
        if let origUrl = resolvedOriginalURL {
            let player = AVPlayer(url: origUrl)
            self.originalPlayer = player
            loopVideo(player: player)
        }
        
        if let resUrl = resolvedResultURL {
            let player = AVPlayer(url: resUrl)
            self.resultPlayer = player
            loopVideo(player: player)
            // Default to start playing the result video
            player.play()
        }
    }
    
    private func loopVideo(player: AVPlayer) {
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
    }
}
