import SwiftUI

struct ContentView: View {
    @StateObject private var engine = TradingEngine()
    
    var body: some View {
        TabView {
            MonitorView(engine: engine)
                .tabItem {
                    Label("Terminal", systemImage: "terminal.fill")
                }
            
            BrainView(engine: engine)
                .tabItem {
                    Label("AI Brain", systemImage: "brain")
                }
            
            PortfolioView(engine: engine)
                .tabItem {
                    Label("Portfolio", systemImage: "chart.pie.fill")
                }
            
            SettingsView(engine: engine)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        // Use dark accent color to match the premium dark mode look
        .accentColor(.cyan)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
