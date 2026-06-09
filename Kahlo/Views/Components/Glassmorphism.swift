import SwiftUI

struct GlassBackgroundView: View {
    var body: some View {
        ZStack {
            Color(red: 3/255, green: 7/255, blue: 18/255).ignoresSafeArea()
            
            // Orb A: Cyan
            Circle()
                .fill(RadialGradient(gradient: Gradient(colors: [Color.cyan.opacity(0.35), Color.clear]), center: .center, startRadius: 0, endRadius: 200))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: -150, y: -250)
            
            // Orb B: Violet
            Circle()
                .fill(RadialGradient(gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.clear]), center: .center, startRadius: 0, endRadius: 180))
                .frame(width: 350, height: 350)
                .blur(radius: 80)
                .offset(x: 180, y: 250)
            
            // Orb C: Green
            Circle()
                .fill(RadialGradient(gradient: Gradient(colors: [Color.green.opacity(0.2), Color.clear]), center: .center, startRadius: 0, endRadius: 150))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -50, y: 150)
        }
        .ignoresSafeArea()
    }
}

struct GlassPanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.45))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(LinearGradient(colors: [Color.white.opacity(0.12), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.37), radius: 20, x: 0, y: 8)
    }
}

extension View {
    func glassPanel() -> some View {
        self.modifier(GlassPanelModifier())
    }
}
