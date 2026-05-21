import SwiftUI

public struct GlassCard<Content: View>: View {
    public let cornerRadius: CGFloat
    public let borderOpacity: CGFloat
    public let backgroundOpacity: CGFloat
    public let content: () -> Content
    
    public init(
        cornerRadius: CGFloat = 16,
        borderOpacity: CGFloat = 0.15,
        backgroundOpacity: CGFloat = 0.2,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.borderOpacity = borderOpacity
        self.backgroundOpacity = backgroundOpacity
        self.content = content
    }
    
    public var body: some View {
        content()
            .padding()
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(backgroundOpacity)
            }
            .background {
                // Outer subtle colored glow to elevate visual premium feel
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.5, green: 0.2, blue: 0.9, opacity: 0.05),
                                Color(red: 0.1, green: 0.7, blue: 0.9, opacity: 0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(borderOpacity * 1.5),
                                .white.opacity(borderOpacity * 0.3),
                                Color(red: 0.6, green: 0.3, blue: 1.0, opacity: borderOpacity * 0.8),
                                Color(red: 0.1, green: 0.8, blue: 1.0, opacity: borderOpacity * 0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            }
            .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 5)
    }
}

// Reusable ViewModifier for convenience
public struct GlassCardModifier: ViewModifier {
    public let cornerRadius: CGFloat
    public let borderOpacity: CGFloat
    public let backgroundOpacity: CGFloat
    
    public func body(content: Content) -> some View {
        GlassCard(
            cornerRadius: cornerRadius,
            borderOpacity: borderOpacity,
            backgroundOpacity: backgroundOpacity
        ) {
            content
        }
    }
}

public extension View {
    func glassCardStyle(
        cornerRadius: CGFloat = 16,
        borderOpacity: CGFloat = 0.15,
        backgroundOpacity: CGFloat = 0.2
    ) -> some View {
        self.modifier(
            GlassCardModifier(
                cornerRadius: cornerRadius,
                borderOpacity: borderOpacity,
                backgroundOpacity: backgroundOpacity
            )
        )
    }
}
