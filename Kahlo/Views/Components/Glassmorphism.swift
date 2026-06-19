import SwiftUI

// MARK: - Animated Background with Floating Orbs

struct GlassBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var orbOffsetA: CGSize = .zero
    @State private var orbOffsetB: CGSize = .zero
    @State private var orbOffsetC: CGSize = .zero

    var body: some View {
        ZStack {
            if colorScheme == .light {
                Color(red: 245/255, green: 247/255, blue: 250/255).ignoresSafeArea()
            } else {
                Color(red: 3/255, green: 7/255, blue: 18/255).ignoresSafeArea()
            }

            // Orb A: Cyan — top-left
            Circle()
                .fill(RadialGradient(
                    gradient: Gradient(colors: [Color.cyan.opacity(colorScheme == .light ? 0.18 : 0.40), Color.clear]),
                    center: .center, startRadius: 0, endRadius: 200))
                .frame(width: 400, height: 400)
                .blur(radius: 90)
                .offset(x: -150 + orbOffsetA.width, y: -250 + orbOffsetA.height)

            // Orb B: Violet — bottom-right
            Circle()
                .fill(RadialGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(colorScheme == .light ? 0.14 : 0.35), Color.clear]),
                    center: .center, startRadius: 0, endRadius: 180))
                .frame(width: 350, height: 350)
                .blur(radius: 90)
                .offset(x: 180 + orbOffsetB.width, y: 250 + orbOffsetB.height)

            // Orb C: Green — center-right
            Circle()
                .fill(RadialGradient(
                    gradient: Gradient(colors: [Color.green.opacity(colorScheme == .light ? 0.10 : 0.22), Color.clear]),
                    center: .center, startRadius: 0, endRadius: 150))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -50 + orbOffsetC.width, y: 150 + orbOffsetC.height)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                orbOffsetA = CGSize(width: 25, height: -15)
            }
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true).delay(1)) {
                orbOffsetB = CGSize(width: -20, height: 20)
            }
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true).delay(2)) {
                orbOffsetC = CGSize(width: 15, height: -10)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Glass Panel Modifier

struct GlassPanelModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(
                colorScheme == .light
                    ? Color.white.opacity(0.5)
                    : Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.55)
            )
            .cornerRadius(DesignConstant.cornerRadiusMd)
            .overlay(
                RoundedRectangle(cornerRadius: DesignConstant.cornerRadiusMd)
                    .stroke(
                        LinearGradient(
                            colors: [
                                colorScheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.12),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .overlay(
                // Inner edge highlight
                RoundedRectangle(cornerRadius: DesignConstant.cornerRadiusMd)
                    .stroke(Color.white.opacity(0.03), lineWidth: 1)
                    .padding(2)
            )
            .shadow(color: colorScheme == .light ? Color.black.opacity(0.05) : Color.black.opacity(0.40), radius: 20, x: 0, y: 8)
    }
}

extension View {
    func glassPanel() -> some View {
        self.modifier(GlassPanelModifier())
    }
}

// MARK: - Glass Button Style

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension View {
    func glassButton() -> some View {
        self.buttonStyle(GlassButtonStyle())
    }
}
