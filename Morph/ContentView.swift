import SwiftUI

struct ContentView: View {
    @Environment(AppStateManager.self) private var stateManager
    
    var body: some View {
        @Bindable var stateManager = stateManager
        
        ZStack {
            // Main Dashboard Navigation Flow
            DashboardView()
                .preferredColorScheme(.dark)
            
            // Full Screen Studio Workspace Modal
            if stateManager.showWorkspace {
                NavigationStack {
                    if stateManager.currentMode == nil {
                        // Select mode screen
                        ZStack {
                            Color(red: 0.05, green: 0.05, blue: 0.08)
                                .ignoresSafeArea()
                            
                            VStack(spacing: 0) {
                                // Simple header
                                HStack {
                                    Button {
                                        stateManager.showWorkspace = false
                                    } label: {
                                        Text("Cancel")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(Color(red: 0.1, green: 0.8, blue: 1.0))
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                                
                                ModeSelectionView {
                                    // Mode was selected, workspace shifts views automatically
                                }
                            }
                        }
                    } else {
                        // Editing / setup screen
                        WorkspaceView()
                    }
                }
                .transition(.move(edge: .bottom))
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: stateManager.showWorkspace)
            }
            
            // Active Rendering Global Glass Overlay
            if stateManager.isUploading || stateManager.isGenerating {
                RenderStatusView()
                    .transition(.opacity)
                    .zIndex(99)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: stateManager.isUploading || stateManager.isGenerating)
    }
}

#Preview {
    ContentView()
        .environment(AppStateManager())
}
