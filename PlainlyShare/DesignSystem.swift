import SwiftUI

// MARK: - App Constants
struct AppLayout {
    static let padding: CGFloat = 24
    static let cornerRadius: CGFloat = 24
    static let smallCornerRadius: CGFloat = 12
    static let iconSize: CGFloat = 44
}

// MARK: - Colors
struct AppColors {
    // Ethereal Gradients
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(hex: "F4F1EA"), // Soft cream/white
            Color(hex: "E6EBF5"), // Soft blueish highlight
            Color(hex: "F0E6EF")  // Soft pinkish highlight
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let darkBackgroundGradient = LinearGradient(
        colors: [
            Color(hex: "0F172A"), // Deep indigo/slate
            Color(hex: "1E293B"), // Lighter slate
            Color(hex: "334155")  // Slate highlight
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Semantic
    static let accent = Color.indigo
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    
    // Glass
    static let glassBorder = Color.white.opacity(0.4)
    static let glassSurface = Color.white.opacity(0.3)
}

// MARK: - Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
struct GlassModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(.thinMaterial)
            .cornerRadius(AppLayout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.6),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Background View
struct AppBackground: View {
    var body: some View {
        ZStack {
            // Adaptive background based on system theme
            GeometryReader { _ in
                Color.clear
                    .background(.background) // System background base
                    .overlay(
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 300, height: 300)
                                .blur(radius: 80)
                                .offset(x: -100, y: -200)
                            
                            Circle()
                                .fill(Color.purple.opacity(0.15))
                                .frame(width: 300, height: 300)
                                .blur(radius: 80)
                                .offset(x: 100, y: 200)
                        }
                    )
            }
        }
        .ignoresSafeArea()
    }
}

extension View {
    func glassCard() -> some View {
        self.modifier(GlassModifier())
    }
    
    /// Applies the animated ethereal background to the view.
    func appBackground() -> some View {
        self.background(AppBackground())
    }
}
