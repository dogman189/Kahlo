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

    var selectedIcon: String {
        icon
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
        ZStack(alignment: .bottom) {
            tabContent
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Color.clear.frame(height: 48)
                }

            customTabBar
        }
        .ignoresSafeArea(.keyboard)
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

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .markets:
            HomeView(engine: engine)
        case .trade:
            TradeView(engine: engine)
        case .terminal:
            MonitorView(engine: engine)
        case .brain:
            BrainView(engine: engine)
        case .report:
            ReportView(engine: engine)
        case .portfolio:
            PortfolioView(engine: engine)
        case .settings:
            SettingsView(engine: engine)
        }
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        VStack(spacing: 0) {
            Divider()
                .frame(height: 0.5)
                .background(Color.white.opacity(0.06))

            HStack(spacing: 0) {
                ForEach(visibleTabs, id: \.self) { tab in
                    Button(action: {
                        HapticManager.light()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 3) {
                            ZStack {
                                if selectedTab == tab {
                                    Capsule()
                                        .fill(Color.cyan.opacity(0.15))
                                        .frame(width: 32, height: 22)
                                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                                }
                                Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                                    .font(.system(size: 18, weight: selectedTab == tab ? .bold : .regular))
                                    .foregroundColor(selectedTab == tab ? .cyan : .gray.opacity(0.6))
                            }

                            Text(tab.label)
                                .font(.system(size: 9, weight: selectedTab == tab ? .bold : .medium, design: .monospaced))
                                .foregroundColor(selectedTab == tab ? .cyan : .gray.opacity(0.6))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 0)
            .background(
                .ultraThinMaterial
            )
            .background(Color.tabBarBg.opacity(0.85))
        }
    }

    // MARK: - Navigation

    private func moveToNextTab() {
        let tabs = visibleTabs
        guard let currentIndex = tabs.firstIndex(of: selectedTab),
              currentIndex + 1 < tabs.count else { return }
        HapticManager.light()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            selectedTab = tabs[currentIndex + 1]
        }
    }

    private func moveToPreviousTab() {
        let tabs = visibleTabs
        guard let currentIndex = tabs.firstIndex(of: selectedTab),
              currentIndex - 1 >= 0 else { return }
        HapticManager.light()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            selectedTab = tabs[currentIndex - 1]
        }
    }
}

#Preview {
    ContentView(engine: TradingEngine())
}
