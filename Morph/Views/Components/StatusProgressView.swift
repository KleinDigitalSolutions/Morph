import SwiftUI

public struct StatusProgressView: View {
    public let progress: Double // 0.0 to 1.0
    public let stageDescription: String
    public let status: RenderTask.Status
    
    @State private var rotationDegrees: Double = 0.0
    @State private var shimmerOffset: CGFloat = -150
    
    private var baseColor: Color {
        switch status {
        case .queued: return .blue
        case .processing: return Color(red: 0.6, green: 0.3, blue: 1.0)
        case .completed: return .green
        case .failed: return .red
        }
    }
    
    public var body: some View {
        VStack(spacing: 28) {
            // Circular Progress Indicator
            ZStack {
                // Background Glow Ring
                Circle()
                    .stroke(baseColor.opacity(0.12), lineWidth: 14)
                    .frame(width: 140, height: 140)
                    .blur(radius: 2)
                
                // Track Ring
                Circle()
                    .stroke(.white.opacity(0.06), lineWidth: 10)
                    .frame(width: 140, height: 140)
                
                // Active Colored Progress Ring
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(max(progress, 0.0), 1.0)))
                    .stroke(
                        LinearGradient(
                            colors: [
                                baseColor,
                                Color(red: 0.1, green: 0.8, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                
                // Interactive Glow Dot at leading edge of progress
                if progress > 0 && progress < 1 {
                    Circle()
                        .fill(Color(red: 0.1, green: 0.8, blue: 1.0))
                        .frame(width: 14, height: 14)
                        .shadow(color: Color(red: 0.1, green: 0.8, blue: 1.0), radius: 6)
                        .offset(y: -70)
                        .rotationEffect(.degrees(progress * 360))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
                
                // Inner percentage label
                VStack(spacing: 4) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(status.displayLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .textCase(.uppercase)
                }
            }
            .frame(width: 160, height: 160)
            
            // Sub-steps visual feedback
            VStack(spacing: 8) {
                Text(stageDescription)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .id(stageDescription) // Force redraw transition
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity
                    ))
                    .animation(.easeInOut(duration: 0.3), value: stageDescription)
                
                // Glassmorphic status bar
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.05))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.6, green: 0.3, blue: 1.0), Color(red: 0.1, green: 0.8, blue: 1.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, min(CGFloat(progress) * 280, 280)), height: 6)
                        .shadow(color: Color(red: 0.6, green: 0.3, blue: 1.0).opacity(0.5), radius: 4, x: 0, y: 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
                .frame(width: 280)
                .padding(.top, 4)
            }
        }
        .padding()
        .onAppear {
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                rotationDegrees = 360
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        StatusProgressView(
            progress: 0.45,
            stageDescription: "Extracting outfit mask & segmenting model...",
            status: .processing
        )
    }
}
