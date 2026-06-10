import SwiftUI

struct ContentView: View {
    @StateObject private var engine = TradingEngine()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("isDarkMode") private var isDarkMode = true
    
    var body: some View {
        TabView {
            HomeView(engine: engine)
                .tabItem {
                    Label("Markets", systemImage: "chart.bar.xaxis")
                }
            
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
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            NotificationManager.shared.requestAuthorization()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                if engine.isRunning {
                    NotificationManager.shared.sendAlgoRunningInBackgroundNotification(symbol: engine.symbol)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
