import SwiftUI

// MARK: - Curated Color Palette

extension Color {
    /// Primary accent — a soft electric blue-cyan
    static let accentTeal = Color(hue: 0.52, saturation: 0.78, brightness: 0.92)
    /// Secondary accent — muted lavender
    static let accentLavender = Color(hue: 0.72, saturation: 0.45, brightness: 0.82)
    /// Positive / bullish
    static let positive = Color(hue: 0.40, saturation: 0.72, brightness: 0.78)
    /// Negative / bearish
    static let negative = Color(hue: 0.0, saturation: 0.62, brightness: 0.82)
    /// Warning / caution
    static let caution = Color(hue: 0.10, saturation: 0.75, brightness: 0.90)
    /// Card surface (dark)
    static let cardSurface = Color(red: 14/255, green: 18/255, blue: 32/255)
    /// Deep background
    static let deepBg = Color(red: 5/255, green: 8/255, blue: 20/255)
    /// Muted label
    static let mutedLabel = Color.white.opacity(0.45)
    /// Subtle border
    static let subtleBorder = Color.white.opacity(0.07)
    /// Faint background fill
    static let faintFill = Color.white.opacity(0.025)
    /// Card border stroke
    static let cardStroke = Color.white.opacity(0.10)
    /// Glass highlight edge
    static let glassHighlight = Color.white.opacity(0.08)
    /// Tab bar background
    static let tabBarBg = Color(red: 10/255, green: 14/255, blue: 28/255)
}

// MARK: - Shadow Presets

extension View {
    func shadowSm() -> some View {
        self.shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
    }

    func shadowMd() -> some View {
        self.shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 8)
    }

    func shadowLg() -> some View {
        self.shadow(color: Color.black.opacity(0.45), radius: 24, x: 0, y: 12)
    }
}

// MARK: - Typography Helpers

extension Font {
    /// Heading for section titles
    static let sectionHeader = Font.system(size: 11, weight: .semibold, design: .monospaced)
    /// Large numeric displays
    static let bigNumber = Font.system(size: 36, weight: .bold, design: .rounded)
    /// Medium numeric displays
    static let medNumber = Font.system(size: 22, weight: .bold, design: .rounded)
    /// Mono label for data values
    static let monoValue = Font.system(size: 14, weight: .semibold, design: .monospaced)
    /// Small mono label
    static let monoSmall = Font.system(size: 11, weight: .medium, design: .monospaced)
    /// Pill/badge text
    static let pillText = Font.system(size: 9, weight: .bold, design: .monospaced)
}

// MARK: - Design Constants

enum DesignConstant {
    static let cornerRadiusSm: CGFloat = 10
    static let cornerRadiusMd: CGFloat = 16
    static let cornerRadiusLg: CGFloat = 20
    static let paddingSm: CGFloat = 12
    static let paddingMd: CGFloat = 16
    static let paddingLg: CGFloat = 24
    static let spacingSm: CGFloat = 8
    static let spacingMd: CGFloat = 16
    static let spacingLg: CGFloat = 24
}

// MARK: - Section Header View

struct SectionLabel: View {
    let text: String
    var color: Color = .mutedLabel

    var body: some View {
        Text(text)
            .font(.sectionHeader)
            .foregroundColor(color)
            .tracking(1.2)
    }
}

// MARK: - Accent Gradient

extension LinearGradient {
    static let accentGradient = LinearGradient(
        colors: [.accentTeal, .accentLavender],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let positiveGradient = LinearGradient(
        colors: [Color.positive, Color(hue: 0.45, saturation: 0.6, brightness: 0.7)],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let negativeGradient = LinearGradient(
        colors: [Color.negative, Color(hue: 0.97, saturation: 0.5, brightness: 0.7)],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Glow Effect

extension View {
    func glow(color: Color, radius: CGFloat = 10) -> some View {
        self.overlay(
            self
                .blur(radius: radius)
                .opacity(0.4)
        )
        .shadow(color: color.opacity(0.3), radius: radius)
    }
}
