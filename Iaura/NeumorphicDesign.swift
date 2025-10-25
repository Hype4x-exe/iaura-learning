import SwiftUI

struct NeumorphicColors {
    static let background = Color(red: 0.88, green: 0.88, blue: 0.88) // #e0e0e0
    static let primary = Color(red: 0.95, green: 0.95, blue: 0.95)
    static let secondary = Color(red: 0.75, green: 0.75, blue: 0.75)
    static let text = Color(red: 0.2, green: 0.2, blue: 0.2)
    static let textSecondary = Color(red: 0.4, green: 0.4, blue: 0.4)
    static let accent = Color(red: 0.3, green: 0.6, blue: 1.0)
    static let glass = Color.white.opacity(0.1)
    static let glassBorder = Color.white.opacity(0.2)
}

struct NeumorphicStyle: ViewModifier {
    let isPressed: Bool
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(NeumorphicColors.primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: isPressed ? 
                                        [Color.black.opacity(0.2), Color.clear] : 
                                        [Color.white.opacity(0.8), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: isPressed ? 
                                        [Color.clear, Color.black.opacity(0.1)] : 
                                        [Color.clear, Color.black.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: isPressed ? Color.black.opacity(0.1) : Color.black.opacity(0.2),
                        radius: isPressed ? 2 : 8,
                        x: isPressed ? 1 : 4,
                        y: isPressed ? 1 : 4
                    )
                    .shadow(
                        color: Color.white.opacity(0.8),
                        radius: isPressed ? 1 : 4,
                        x: isPressed ? -1 : -2,
                        y: isPressed ? -1 : -2
                    )
            )
    }
}

struct GlassNeumorphicStyle: ViewModifier {
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
    }
}

extension View {
    func neumorphic(isPressed: Bool = false, cornerRadius: CGFloat = 16) -> some View {
        modifier(NeumorphicStyle(isPressed: isPressed, cornerRadius: cornerRadius))
    }
    
    func glassNeumorphic(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassNeumorphicStyle(cornerRadius: cornerRadius))
    }
}

struct NeumorphicButton<Content: View>: View {
    let action: () -> Void
    let content: Content
    @State private var isPressed = false
    
    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: action) {
            content
                .neumorphic(isPressed: isPressed)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                isPressed = pressing
            },
            perform: {}
        )
    }
}

struct NeumorphicTextField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(NeumorphicColors.primary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 2, y: 2)
            .shadow(color: Color.white.opacity(0.7), radius: 4, x: -2, y: -2)
    }
}