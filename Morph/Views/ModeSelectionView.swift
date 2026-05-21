import SwiftUI

public struct ModeSelectionView: View {
    @Environment(AppStateManager.self) private var stateManager
    public let onModeSelected: () -> Void
    
    public var body: some View {
        VStack(spacing: 20) {
            // Title & Instruction
            VStack(spacing: 8) {
                Text("Select Studio Mode")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Choose how Gemini Vertex AI transforms your raw content.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 10)
            .padding(.bottom, 6)
            
            // Scrollable list of 4 options
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(ProcessingMode.allCases) { mode in
                        Button {
                            // Select mode and proceed
                            stateManager.currentMode = mode
                            onModeSelected()
                        } label: {
                            HStack(spacing: 16) {
                                // Mode Icon with visual circle frame
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.6, green: 0.3, blue: 1.0).opacity(0.18),
                                                    Color(red: 0.1, green: 0.8, blue: 1.0).opacity(0.08)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 52, height: 52)
                                    
                                    Image(systemName: mode.iconName)
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundStyle(Color(red: 0.1, green: 0.8, blue: 1.0))
                                }
                                .overlay {
                                    Circle()
                                        .stroke(Color(red: 0.1, green: 0.8, blue: 1.0).opacity(0.25), lineWidth: 1)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(mode.title)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(.white)
                                        
                                        Spacer()
                                        
                                        // Asset requirement tag
                                        Text(assetRequirementTag(for: mode))
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(Color(red: 0.6, green: 0.3, blue: 1.0))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color(red: 0.6, green: 0.3, blue: 1.0).opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                    
                                    Text(mode.description)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.5))
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.3))
                                    .padding(.leading, 4)
                            }
                            .glassCardStyle(cornerRadius: 16, borderOpacity: 0.12, backgroundOpacity: 0.25)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }
    
    private func assetRequirementTag(for mode: ProcessingMode) -> String {
        switch mode {
        case .clothingSwap: return "Outfit Reference"
        case .environmentSwap: return "Scenery + Prompt"
        case .characterSwap: return "Avatar Image"
        case .fullTransformation: return "Prompt + References"
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ModeSelectionView(onModeSelected: {})
            .environment(AppStateManager())
    }
}
