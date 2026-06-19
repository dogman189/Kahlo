import SwiftUI

enum Tab: String, CaseIterable {
    case markets, trade, terminal, brain, report, portfolio, settings

    var label: String {
        switch self {
        case .markets: return "Markets"
        case .trade: return "Trade"
        case .terminal: return "Terminal"
        case .brain: return "AI Brain"
        case .report: return "AI Report"
        case .portfolio: return "Portfolio"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .markets: return "chart.bar.xaxis"
        case .trade: return "arrow.left.arrow.right.circle.fill"
        case .terminal: return "terminal.fill"
        case .brain: return "brain"
        case .report: return "doc.text.magnifyingglass"
        case .portfolio: return "chart.pie.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct ContentView: View {
    @ObservedObject var engine: TradingEngine
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("showTabMarkets") private var showTabMarkets = true
    @AppStorage("showTabTrade") private var showTabTrade = true
    @AppStorage("showTabTerminal") private var showTabTerminal = true
    @AppStorage("showTabBrain") private var showTabBrain = true
    @AppStorage("showTabReport") private var showTabReport = true
    @AppStorage("showTabPortfolio") private var showTabPortfolio = true
    @AppStorage("showTabSettings") private var showTabSettings = true

    @State private var selectedTab: Tab = .markets

    private var visibleTabs: [Tab] {
        Tab.allCases.filter { tab in
            switch tab {
            case .markets: return showTabMarkets
            case .trade: return showTabTrade
            case .terminal: return showTabTerminal
            case .brain: return showTabBrain
            case .report: return showTabReport
            case .portfolio: return showTabPortfolio
            case .settings: return showTabSettings
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            if showTabMarkets {
                HomeView(engine: engine)
                    .tabItem {
                        Label(Tab.markets.label, systemImage: Tab.markets.icon)
                    }
                    .tag(Tab.markets)
            }

            if showTabTrade {
                TradeView(engine: engine)
                    .tabItem {
                        Label(Tab.trade.label, systemImage: Tab.trade.icon)
                    }
                    .tag(Tab.trade)
            }

            if showTabTerminal {
                MonitorView(engine: engine)
                    .tabItem {
                        Label(Tab.terminal.label, systemImage: Tab.terminal.icon)
                    }
                    .tag(Tab.terminal)
            }

            if showTabBrain {
                BrainView(engine: engine)
                    .tabItem {
                        Label(Tab.brain.label, systemImage: Tab.brain.icon)
                    }
                    .tag(Tab.brain)
            }

            if showTabReport {
                ReportView(engine: engine)
                    .tabItem {
                        Label(Tab.report.label, systemImage: Tab.report.icon)
                    }
                    .tag(Tab.report)
            }

            if showTabPortfolio {
                PortfolioView(engine: engine)
                    .tabItem {
                        Label(Tab.portfolio.label, systemImage: Tab.portfolio.icon)
                    }
                    .tag(Tab.portfolio)
            }

            if showTabSettings {
                SettingsView(engine: engine)
                    .tabItem {
                        Label(Tab.settings.label, systemImage: Tab.settings.icon)
                    }
                    .tag(Tab.settings)
            }
        }
        .accentColor(.cyan)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            NotificationManager.shared.requestAuthorization()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .background:
                engine.handleDidEnterBackground()
            case .active:
                engine.handleWillEnterForeground()
            default:
                break
            }
        }
        .simultaneousGesture(
            DragGesture()
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = value.translation.height

                    guard abs(horizontalAmount) > abs(verticalAmount) * 1.5,
                          abs(horizontalAmount) > 50 else { return }

                    if horizontalAmount < 0 {
                        moveToNextTab()
                    } else {
                        moveToPreviousTab()
                    }
                }
        )
    }

    private func moveToNextTab() {
        let tabs = visibleTabs
        guard let currentIndex = tabs.firstIndex(of: selectedTab),
              currentIndex + 1 < tabs.count else { return }
        withAnimation { selectedTab = tabs[currentIndex + 1] }
    }

    private func moveToPreviousTab() {
        let tabs = visibleTabs
        guard let currentIndex = tabs.firstIndex(of: selectedTab),
              currentIndex - 1 >= 0 else { return }
        withAnimation { selectedTab = tabs[currentIndex - 1] }
    }
}

#Preview {
    ContentView(engine: TradingEngine())
}
