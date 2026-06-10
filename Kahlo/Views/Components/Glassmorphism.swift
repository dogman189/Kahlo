import SwiftUI

struct GlassBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            if colorScheme == .light {
                Color(red: 245/255, green: 247/255, blue: 250/255).ignoresSafeArea()
            } else {
                Color(red: 3/255, green: 7/255, blue: 18/255).ignoresSafeArea()
            }
            
            // Orb A: Cyan
            Circle()
                .fill(RadialGradient(gradient: Gradient(colors: [Color.cyan.opacity(colorScheme == .light ? 0.18 : 0.35), Color.clear]), center: .center, startRadius: 0, endRadius: 200))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: -150, y: -250)
            
            // Orb B: Violet
            Circle()
                .fill(RadialGradient(gradient: Gradient(colors: [Color.purple.opacity(colorScheme == .light ? 0.14 : 0.3), Color.clear]), center: .center, startRadius: 0, endRadius: 180))
                .frame(width: 350, height: 350)
                .blur(radius: 80)
                .offset(x: 180, y: 250)
            
            // Orb C: Green
            Circle()
                .fill(RadialGradient(gradient: Gradient(colors: [Color.green.opacity(colorScheme == .light ? 0.10 : 0.2), Color.clear]), center: .center, startRadius: 0, endRadius: 150))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -50, y: 150)
        }
        .ignoresSafeArea()
    }
}
 
struct GlassPanelModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(colorScheme == .light ? Color.white.opacity(0.5) : Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.45))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(LinearGradient(colors: [colorScheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.12), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
            .shadow(color: colorScheme == .light ? Color.black.opacity(0.05) : Color.black.opacity(0.37), radius: 20, x: 0, y: 8)
    }
}
 
extension View {
    func glassPanel() -> some View {
        self.modifier(GlassPanelModifier())
    }
}
