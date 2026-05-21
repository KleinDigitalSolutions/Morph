import SwiftUI

public struct DashboardView: View {
    @Environment(AppStateManager.self) private var stateManager
    
    // Grid columns configuration
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    public var body: some View {
        @Bindable var stateManager = stateManager
        NavigationStack(path: $stateManager.activeNavigationPath) {
            ZStack {
                // Background Dark Obsidian Glows
                Color(red: 0.05, green: 0.05, blue: 0.08)
                    .ignoresSafeArea()
                
                // Neon Ambient Blurs
                VStack {
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color(red: 0.5, green: 0.1, blue: 0.9).opacity(0.18))
                            .frame(width: 300, height: 300)
                            .blur(radius: 80)
                            .offset(x: 100, y: -50)
                    }
                    Spacer()
                    HStack {
                        Circle()
                            .fill(Color(red: 0.0, green: 0.7, blue: 0.9).opacity(0.12))
                            .frame(width: 250, height: 250)
                            .blur(radius: 60)
                            .offset(x: -80, y: 100)
                        Spacer()
                    }
                }
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("OmniStudio AI")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(red: 0.8, green: 0.6, blue: 1.0)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text("FastAPI + Gemini Omni Veo Studio")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.6, green: 0.3, blue: 1.0), Color(red: 0.1, green: 0.8, blue: 1.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .textCase(.uppercase)
                                .tracking(1)
                        }
                        
                        Spacer()
                        
                        // Create New Floating-style header button
                        Button {
                            // Launch selection flow
                            stateManager.resetWorkspace()
                            stateManager.showWorkspace = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.6, green: 0.3, blue: 1.0), Color(red: 0.1, green: 0.8, blue: 1.0)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color(red: 0.6, green: 0.3, blue: 1.0).opacity(0.4), radius: 6)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Primary Banner / Start Button
                            Button {
                                stateManager.resetWorkspace()
                                stateManager.showWorkspace = true
                            } label: {
                                GlassCard(cornerRadius: 20, borderOpacity: 0.22, backgroundOpacity: 0.3) {
                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("AI Video Engine")
                                                .font(.system(size: 11, weight: .black))
                                                .foregroundStyle(Color(red: 0.1, green: 0.8, blue: 1.0))
                                                .textCase(.uppercase)
                                                .tracking(1.5)
                                            
                                            Text("Start Transformation")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundStyle(.white)
                                            
                                            Text("Swap outfit, environment, or characters instantly using AI guidance.")
                                                .font(.system(size: 13))
                                                .foregroundStyle(.white.opacity(0.6))
                                                .multilineTextAlignment(.leading)
                                                .lineLimit(2)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        
                                        Spacer()
                                        
                                        // Visual wand icon with pulsing glow
                                        ZStack {
                                            Circle()
                                                .fill(Color(red: 0.6, green: 0.3, blue: 1.0).opacity(0.15))
                                                .frame(width: 56, height: 56)
                                            
                                            Image(systemName: "wand.and.stars")
                                                .font(.system(size: 24))
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        colors: [Color(red: 0.6, green: 0.3, blue: 1.0), Color(red: 0.1, green: 0.8, blue: 1.0)],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                        }
                                        .shadow(color: Color(red: 0.6, green: 0.3, blue: 1.0).opacity(0.5), radius: 8)
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 20)
                            
                            // History Grid
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Recent Creations")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 20)
                                
                                if stateManager.taskHistory.isEmpty {
                                    // Empty state
                                    VStack(spacing: 16) {
                                        Image(systemName: "video.badge.plus")
                                            .font(.system(size: 44))
                                            .foregroundStyle(.white.opacity(0.2))
                                            .padding(.top, 40)
                                        
                                        Text("No renders completed yet")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(.white.opacity(0.4))
                                        
                                        Text("Tap above to record your first content piece and apply a swap style.")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.white.opacity(0.3))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 40)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, 60)
                                } else {
                                    // Visual Grid of history
                                    LazyVGrid(columns: columns, spacing: 16) {
                                        ForEach(stateManager.taskHistory) { task in
                                            NavigationLink(value: task) {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    // Thumbnail frame with glass aesthetics
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(.white.opacity(0.04))
                                                            .aspectRatio(0.8, contentMode: .fit)
                                                            .overlay {
                                                                RoundedRectangle(cornerRadius: 12)
                                                                    .stroke(.white.opacity(0.08), lineWidth: 1)
                                                            }
                                                        
                                                        // Accent graphic
                                                        LinearGradient(
                                                            colors: [
                                                                Color(red: 0.6, green: 0.3, blue: 1.0).opacity(0.12),
                                                                Color(red: 0.1, green: 0.8, blue: 1.0).opacity(0.06)
                                                            ],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                                        
                                                        VStack(spacing: 8) {
                                                            Image(systemName: task.mode.iconName)
                                                                .font(.system(size: 28))
                                                                .foregroundStyle(Color(red: 0.1, green: 0.8, blue: 1.0))
                                                                .shadow(color: Color(red: 0.1, green: 0.8, blue: 1.0).opacity(0.4), radius: 6)
                                                            
                                                            Image(systemName: "play.fill")
                                                                .font(.system(size: 16))
                                                                .foregroundStyle(.white)
                                                                .padding(8)
                                                                .background(.white.opacity(0.12))
                                                                .clipShape(Circle())
                                                        }
                                                    }
                                                    
                                                    // Task Metadata
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(task.mode.title)
                                                            .font(.system(size: 13, weight: .bold))
                                                            .foregroundStyle(.white)
                                                        
                                                        Text(task.createdAt, style: .date)
                                                            .font(.system(size: 10))
                                                            .foregroundStyle(.white.opacity(0.4))
                                                    }
                                                    .padding(.horizontal, 4)
                                                }
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 40)
                                }
                            }
                        }
                    }
                }
            }
            .navigationDestination(for: RenderTask.self) { task in
                // Result View
                ResultPlaybackView(task: task)
            }
        }
    }
}

#Preview {
    let state = AppStateManager()
    state.taskHistory = [
        RenderTask(id: "1", mode: .clothingSwap, status: .completed, progress: 1.0, progressStage: "Done", originalVideoUrl: "https://example.com/a.mp4", resultVideoUrl: "https://example.com/b.mp4"),
        RenderTask(id: "2", mode: .environmentSwap, status: .completed, progress: 1.0, progressStage: "Done", originalVideoUrl: "https://example.com/a.mp4", resultVideoUrl: "https://example.com/b.mp4")
    ]
    return DashboardView()
        .environment(state)
}
