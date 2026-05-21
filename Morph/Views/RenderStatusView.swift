import SwiftUI

public struct RenderStatusView: View {
    @Environment(AppStateManager.self) private var stateManager
    
    // Tips array to display during active render
    private let tips = [
        "Gemini Omni analyzes garment textures to ensure a hyper-realistic weave match.",
        "Ensure your source video has steady lighting for optimal environment blending.",
        "Gemini Veo generates high-fidelity frame outputs up to cinematic resolutions.",
        "Processing modes are optimized to keep original facial identity and motion intact.",
        "Your video assets are transferred securely and processed privately in Vertex AI."
    ]
    
    @State private var activeTipIndex = 0
    @State private var tipTimer: Timer? = nil
    
    public var body: some View {
        ZStack {
            // Dark Overlay Material
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            // Subtle Background Gradients
            VStack {
                Circle()
                    .fill(Color(red: 0.6, green: 0.3, blue: 1.0).opacity(0.15))
                    .frame(width: 250, height: 250)
                    .blur(radius: 60)
                    .offset(y: -50)
                Spacer()
            }
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Real-time Progress Card
                VStack(spacing: 12) {
                    if stateManager.isUploading {
                        StatusProgressView(
                            progress: stateManager.uploadProgress,
                            stageDescription: "Uploading source content & references...",
                            status: .queued
                        )
                    } else if let activeTask = stateManager.activeTask {
                        StatusProgressView(
                            progress: activeTask.progress,
                            stageDescription: activeTask.progressStage,
                            status: activeTask.status
                        )
                    } else {
                        // Fallback fallback
                        StatusProgressView(
                            progress: 0.05,
                            stageDescription: "Initializing secure connection...",
                            status: .queued
                        )
                    }
                }
                .padding(.vertical, 20)
                
                // Tips Carousel
                VStack(spacing: 8) {
                    Text("Creator Pro Tip")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(red: 0.1, green: 0.8, blue: 1.0))
                        .textCase(.uppercase)
                        .tracking(1.5)
                    
                    Text(tips[activeTipIndex])
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 40)
                        .frame(height: 50)
                        .id(activeTipIndex) // Trigger transition animation
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Cancel Action
                Button {
                    stateManager.resetWorkspace()
                } label: {
                    Text("Cancel Task")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.08))
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startTipTimer()
        }
        .onDisappear {
            stopTipTimer()
        }
    }
    
    private func startTipTimer() {
        tipTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                activeTipIndex = (activeTipIndex + 1) % tips.count
            }
        }
    }
    
    private func stopTipTimer() {
        tipTimer?.invalidate()
        tipTimer = nil
    }
}

#Preview {
    let state = AppStateManager()
    state.isUploading = false
    state.activeTask = RenderTask(
        id: "abc",
        mode: .clothingSwap,
        status: .processing,
        progress: 0.68,
        progressStage: "Synthesizing cloth flow dynamics..."
    )
    return RenderStatusView()
        .environment(state)
}
