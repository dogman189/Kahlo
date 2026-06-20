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
