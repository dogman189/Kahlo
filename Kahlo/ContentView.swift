import SwiftUI

struct ContentView: View {
    @ObservedObject var engine: TradingEngine
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("showTabMarkets") private var showTabMarkets = true
    @AppStorage("showTabTrade") private var showTabTrade = true
    @AppStorage("showTabTerminal") private var showTabTerminal = true
    @AppStorage("showTabBrain") private var showTabBrain = true
    @AppStorage("showTabPortfolio") private var showTabPortfolio = true
    @AppStorage("showTabSettings") private var showTabSettings = true

    var body: some View {
        TabView {
            if showTabMarkets {
                HomeView(engine: engine)
                    .tabItem {
                        Label("Markets", systemImage: "chart.bar.xaxis")
                    }
            }
            
            if showTabTrade {
                TradeView(engine: engine)
                    .tabItem {
                        Label("Trade", systemImage: "arrow.left.arrow.right.circle.fill")
                    }
            }
            
            if showTabTerminal {
                MonitorView(engine: engine)
                    .tabItem {
                        Label("Terminal", systemImage: "terminal.fill")
                    }
            }
            
            if showTabBrain {
                BrainView(engine: engine)
                    .tabItem {
                        Label("AI Brain", systemImage: "brain")
                    }
            }
            
            if showTabPortfolio {
                PortfolioView(engine: engine)
                    .tabItem {
                        Label("Portfolio", systemImage: "chart.pie.fill")
                    }
            }
            
            if showTabSettings {
                SettingsView(engine: engine)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
        }
        // Use dark accent color to match the premium dark mode look
        .accentColor(.cyan)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            NotificationManager.shared.requestAuthorization()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .background:
                // App moved to background — schedule background tasks and
                // grab short-duration UIKit execution time so the current
                // bot tick finishes cleanly.
                engine.handleDidEnterBackground()
            case .active:
                // App returned to foreground — release background task token.
                engine.handleWillEnterForeground()
            default:
                break
            }
        }
    }
}

#Preview {
    ContentView(engine: TradingEngine())
}
