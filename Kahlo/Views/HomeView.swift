import SwiftUI

enum MarketFilter: String, CaseIterable {
    case all = "ALL"
    case gainers = "GAINERS"
    case losers = "LOSERS"
    case holdings = "HOLDINGS"
}

enum HomeSheetType: Identifiable {
    case coin(CoinModel)
    case sentiment
    case volume
    
    var id: String {
        switch self {
        case .coin(let coin):
            return "coin-\(coin.symbol)"
        case .sentiment:
            return "sentiment"
        case .volume:
            return "volume"
        }
    }
}

struct HomeView: View {
    @ObservedObject var engine: TradingEngine
    @State private var activeSheet: HomeSheetType?
    @State private var searchQuery: String = ""
    @State private var selectedFilter: MarketFilter = .all
    
    private var coins: [CoinModel] {
        get { engine.coins }
        nonmutating set { engine.coins = newValue }
    }
    
    // Default base data to initialize
    private let initialCoins = [
        CoinModel(symbol: "BTC", name: "Bitcoin", price: 68450.0, change24h: 3.45, marketCap: 1340.5, volume24h: 28400.0, sparkline: [67100, 67300, 66800, 67200, 67900, 68100, 68450]),
        CoinModel(symbol: "ETH", name: "Ethereum", price: 3520.0, change24h: 1.88, marketCap: 422.3, volume24h: 14200.0, sparkline: [3480, 3490, 3460, 3510, 3505, 3495, 3520]),
        CoinModel(symbol: "SOL", name: "Solana", price: 162.50, change24h: 5.62, marketCap: 75.1, volume24h: 3800.0, sparkline: [152, 155, 153, 158, 159, 161, 162.5]),
        CoinModel(symbol: "ADA", name: "Cardano", price: 0.485, change24h: -1.22, marketCap: 17.3, volume24h: 420.0, sparkline: [0.495, 0.491, 0.482, 0.487, 0.484, 0.489, 0.485]),
        CoinModel(symbol: "DOT", name: "Polkadot", price: 6.42, change24h: -0.85, marketCap: 9.2, volume24h: 180.0, sparkline: [6.51, 6.48, 6.38, 6.45, 6.40, 6.43, 6.42]),
        CoinModel(symbol: "LINK", name: "Chainlink", price: 15.35, change24h: 2.14, marketCap: 9.1, volume24h: 310.0, sparkline: [14.95, 15.10, 14.88, 15.20, 15.15, 15.25, 15.35]),
        CoinModel(symbol: "DOGE", name: "Dogecoin", price: 0.142, change24h: 12.48, marketCap: 20.5, volume24h: 1850.0, sparkline: [0.125, 0.128, 0.122, 0.131, 0.138, 0.139, 0.142])
    ]
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // MARK: - Market Stats Overview
                    marketSummaryCardsSection
                    
                    // MARK: - Search Field
                    searchBarSection

                    // MARK: - Filter Pills
                    filterPillsSection
                    
                    // MARK: - Coins List
                    coinsListSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(GlassBackgroundView())
            .navigationTitle("Markets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("MONÉT")
                        .font(.system(.subheadline, design: .monospaced))
                        .bold()
                        .tracking(3)
                        .foregroundColor(.accentTeal)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.spring()) {
                            updatePricesFromEngine()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.accentTeal)
                    }
                }
            }
            .sheet(item: $activeSheet) { sheetType in
                switch sheetType {
                case .coin(let coin):
                    CoinDetailView(coin: coin, engine: engine) { updatedCoin in
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            engine.symbol = updatedCoin.symbol
                            if engine.isRunning {
                                engine.stop()
                                engine.start()
                            } else {
                                engine.start()
                            }
                        }
                    }
                case .sentiment:
                    SentimentDetailView(coins: coins)
                case .volume:
                    VolumeDetailView(coins: coins, engine: engine)
                }
            }
            .onAppear {
                initializeCoins()
                updatePricesFromEngine()
            }
            .onChange(of: engine.lastMarketRefresh) { _ in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    syncCoinsFromEngine()
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private var filteredCoins: [CoinModel] {
        var baseCoins = coins
        
        switch selectedFilter {
        case .all:
            break
        case .gainers:
            baseCoins = baseCoins.filter { $0.change24h > 0 }
        case .losers:
            baseCoins = baseCoins.filter { $0.change24h < 0 }
        case .holdings:
            baseCoins = baseCoins.filter {
                $0.symbol == engine.symbol || (engine.portfolio.holdings[$0.symbol] ?? 0.0) > 0
            }
        }
        
        if searchQuery.isEmpty {
            return baseCoins
        } else {
            return baseCoins.filter {
                $0.name.lowercased().contains(searchQuery.lowercased()) ||
                $0.symbol.lowercased().contains(searchQuery.lowercased())
            }
        }
    }

    private var filterPillsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MarketFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            selectedFilter = filter
                        }
                    }) {
                        Text(filter.rawValue)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(selectedFilter == filter ? .white : .gray)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                selectedFilter == filter
                                    ? Color.cyan.opacity(0.85)
                                    : Color.white.opacity(0.04)
                            )
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        selectedFilter == filter ? Color.cyan.opacity(0.5) : Color.white.opacity(0.05),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 2)
        }
    }
    
    private func initializeCoins() {
        if coins.isEmpty {
            coins = initialCoins
        }
        syncActiveEnginePrice()
    }
    
    private func syncActiveEnginePrice() {
        if let idx = coins.firstIndex(where: { $0.symbol == engine.symbol }) {
            if engine.price > 0 {
                coins[idx].price = engine.price
                if coins[idx].sparkline.count > 10 {
                    coins[idx].sparkline.removeFirst()
                }
                coins[idx].sparkline.append(engine.price)
            }
        }
    }
    
    private func updatePricesFromEngine() {
        updatePrices()
    }

    /// Syncs the local coins array using a full fetch to get all metadata.
    private func syncCoinsFromEngine() {
        updatePrices()
    }
    
    private func updatePrices() {
        Task {
            if let results = await engine.fetchTop100Coins() {
                await MainActor.run {
                    var newCoins: [CoinModel] = []
                    for rc in results {
                        let sym = rc.symbol.uppercased()
                        var spark = [rc.price]
                        if let existing = self.coins.first(where: { $0.symbol.uppercased() == sym }) {
                            spark = existing.sparkline
                            if spark.count > 14 {
                                spark.removeFirst()
                            }
                            spark.append(rc.price)
                        } else {
                            // Seed a realistic sparkline for new coins
                            for _ in 1...6 {
                                let variation = Double.random(in: -0.01...0.01)
                                spark.insert(rc.price * (1.0 + variation), at: 0)
                            }
                        }
                        
                        let model = CoinModel(
                            symbol: sym,
                            name: rc.name,
                            price: rc.price,
                            change24h: rc.change24h,
                            marketCap: rc.marketCap,
                            volume24h: rc.volume24h,
                            sparkline: spark
                        )
                        newCoins.append(model)
                    }
                    self.coins = newCoins
                    updateActiveEngine()
                }
            } else {
                await MainActor.run {
                    runMockUpdate()
                }
            }
        }
    }
    
    private func updateActiveEngine() {
        if engine.isRunning && engine.price > 0 {
            if let idx = coins.firstIndex(where: { $0.symbol == engine.symbol }) {
                coins[idx].price = engine.price
            }
        }
    }
    
    private func runMockUpdate() {
        for i in 0..<coins.count {
            let changePercent = Double.random(in: -0.5...0.6)
            let delta = coins[i].price * (changePercent / 100.0)
            coins[i].price += delta
            coins[i].change24h += changePercent / 3.0
            
            if coins[i].sparkline.count > 14 {
                coins[i].sparkline.removeFirst()
            }
            coins[i].sparkline.append(coins[i].price)
        }
        updateActiveEngine()
    }
    
    // MARK: - View Components

    // MARK: - Summary Card Helpers

    private var topGainer: CoinModel? {
        coins.max(by: { $0.change24h < $1.change24h })
    }

    private var topLoser: CoinModel? {
        coins.min(by: { $0.change24h < $1.change24h })
    }

    private var gainersCount: Int {
        coins.filter { $0.change24h >= 0 }.count
    }

    private var losersCount: Int {
        coins.filter { $0.change24h < 0 }.count
    }

    private var total24hVolume: Double {
        coins.reduce(0) { $0 + $1.volume24h }
    }

    private var totalMarketCap: Double {
        coins.reduce(0) { $0 + $1.marketCap }
    }

    // MARK: - Market Summary Cards

    private var marketSummaryCardsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {

                // Top Gainer
                Button(action: {
                    if let coin = topGainer {
                        activeSheet = .coin(coin)
                    }
                }) {
                    MarketSummaryCard(
                        label: "TOP GAINER",
                        icon: "arrow.up.right",
                        iconColor: .positive,
                        primary: topGainer?.symbol ?? "--",
                        secondary: topGainer.map { String(format: "%+.2f%%", $0.change24h) } ?? "--",
                        secondaryColor: .positive
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(topGainer == nil)

                // Top Loser
                Button(action: {
                    if let coin = topLoser {
                        activeSheet = .coin(coin)
                    }
                }) {
                    MarketSummaryCard(
                        label: "TOP LOSER",
                        icon: "arrow.down.right",
                        iconColor: .negative,
                        primary: topLoser?.symbol ?? "--",
                        secondary: topLoser.map { String(format: "%+.2f%%", $0.change24h) } ?? "--",
                        secondaryColor: .negative
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(topLoser == nil)

                // Gainers / Losers ratio (Sentiment)
                Button(action: {
                    activeSheet = .sentiment
                }) {
                    MarketSummaryCard(
                        label: "SENTIMENT",
                        icon: "chart.bar.fill",
                        iconColor: gainersCount >= losersCount ? .positive : .negative,
                        primary: "\(gainersCount)↑  \(losersCount)↓",
                        secondary: coins.isEmpty ? "" : String(format: "%.0f%% up", Double(gainersCount) / Double(coins.count) * 100),
                        secondaryColor: gainersCount >= losersCount ? .positive : .negative
                    )
                }
                .buttonStyle(ScaleButtonStyle())

                // Total 24h Volume
                Button(action: {
                    activeSheet = .volume
                }) {
                    MarketSummaryCard(
                        label: "24H VOLUME",
                        icon: "dollarsign.circle",
                        iconColor: .accentTeal,
                        primary: String(format: "$%.1fB", total24hVolume / 1000),
                        secondary: String(format: "MCap $%.1fT", totalMarketCap / 1000),
                        secondaryColor: .mutedLabel
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
        .padding(.top, 8)
    }
    
    private var searchBarSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 14))
            TextField("Search assets...", text: $searchQuery)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .autocorrectionDisabled()
                .autocapitalization(.allCharacters)
            if !searchQuery.isEmpty {
                Button(action: { searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
    }
    
    private var coinsListSection: some View {
        VStack(spacing: 8) {
            ForEach(filteredCoins) { coin in
                Button(action: {
                    activeSheet = .coin(coin)
                }) {
                    HStack(spacing: 0) {
                        // Coin Icon & Info
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 8) {
                                Text(coin.symbol)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                if engine.symbol == coin.symbol {
                                    Text("AUTO-TRADING")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.12))
                                        .cornerRadius(4)
                                }
                            }
                            Text(coin.name)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 110, alignment: .leading)
                        
                        Spacer()
                        
                        // Sparkline View
                        MiniSparkline(data: coin.sparkline, isPositive: coin.change24h >= 0)
                            .frame(height: 24)
                            .padding(.horizontal, 10)
                        
                        Spacer()
                        
                        // Price & Valuation info
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(engine.selectedCurrency.format(coin.price, decimalPlaces: coin.price >= 1.0 ? 2 : 4))
                                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                .foregroundColor(.primary)
                            
                            Text(String(format: "%+.2f%%", coin.change24h))
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(coin.change24h >= 0 ? .green : .red)
                        }
                        .frame(width: 95, alignment: .trailing)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Color.white.opacity(0.015))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.03), lineWidth: 0.5)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: filteredCoins)
    }
}

// MARK: - Mini Sparkline Component
struct MiniSparkline: View {
    let data: [Double]
    let isPositive: Bool
    
    var body: some View {
        GeometryReader { geo in
            if data.count < 2 {
                EmptyView()
            } else {
                ZStack {
                    // Gradient Fill Area
                    Path { path in
                        let minVal = data.min() ?? 0
                        let maxVal = data.max() ?? 1
                        let range = maxVal - minVal
                        
                        let firstVal = data.first!
                        let yFirst = geo.size.height - (geo.size.height * CGFloat((firstVal - minVal) / (range > 0 ? range : 1.0)))
                        path.move(to: CGPoint(x: 0, y: geo.size.height))
                        path.addLine(to: CGPoint(x: 0, y: yFirst))
                        
                        for i in 1..<data.count {
                            let x = geo.size.width * (CGFloat(i) / CGFloat(data.count - 1))
                            let y = geo.size.height - (geo.size.height * CGFloat((data[i] - minVal) / (range > 0 ? range : 1.0)))
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [
                                isPositive ? Color.green.opacity(0.08) : Color.red.opacity(0.08),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Fine stroke line
                    Path { path in
                        let minVal = data.min() ?? 0
                        let maxVal = data.max() ?? 1
                        let range = maxVal - minVal
                        
                        let firstVal = data.first!
                        let yFirst = geo.size.height - (geo.size.height * CGFloat((firstVal - minVal) / (range > 0 ? range : 1.0)))
                        path.move(to: CGPoint(x: 0, y: yFirst))
                        
                        for i in 1..<data.count {
                            let x = geo.size.width * (CGFloat(i) / CGFloat(data.count - 1))
                            let y = geo.size.height - (geo.size.height * CGFloat((data[i] - minVal) / (range > 0 ? range : 1.0)))
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    .stroke(
                        isPositive ? Color.green.opacity(0.8) : Color.red.opacity(0.8),
                        style: StrokeStyle(lineWidth: 1.25, lineCap: .round, lineJoin: .round)
                    )
                }
            }
        }
    }
}

// MARK: - Coin Detail View Sheet
struct CoinDetailView: View {
    let coin: CoinModel
    @ObservedObject var engine: TradingEngine
    @Environment(\.dismiss) var dismiss
    
    var onSelectTrading: (CoinModel) -> Void
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // Header Price Section
                    VStack(spacing: 6) {
                        Text(coin.name.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        Text(engine.selectedCurrency.format(coin.price, decimalPlaces: coin.price >= 1.0 ? 2 : 4))
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(String(format: "%+.2f%%", coin.change24h))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(coin.change24h >= 0 ? .green : .red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(coin.change24h >= 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.top, 20)
                    
                    // Valuations card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("ASSET METRICS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        Divider().background(Color.white.opacity(0.06))
                        
                        MetricRow(title: "Market Capitalization", value: "\(engine.selectedCurrency.symbol)\(String(format: "%.1f", engine.selectedCurrency.convert(coin.marketCap)))B")
                        MetricRow(title: "24h Trading Volume", value: "\(engine.selectedCurrency.symbol)\(String(format: "%.1f", engine.selectedCurrency.convert(coin.volume24h)))M")
                        
                        let holdings = engine.portfolio.holdings[coin.symbol] ?? 0.0
                        let valuation = holdings * coin.price
                        MetricRow(title: "Your Holdings", value: "\(String(format: "%.4f", holdings)) \(coin.symbol)")
                        MetricRow(title: "Holdings Value", value: engine.selectedCurrency.format(valuation), valueColor: .cyan)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.04), lineWidth: 1)
                    )
                    
                    // Action controls
                    VStack {
                        if engine.symbol == coin.symbol {
                            HStack(spacing: 8) {
                                Image(systemName: "circle.badge.ellipsis")
                                    .foregroundColor(.green)
                                Text("Active Engine Target")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green.opacity(0.08))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.2), lineWidth: 1)
                            )
                        } else {
                            Button(action: {
                                onSelectTrading(coin)
                                dismiss()
                            }) {
                                Text("START ENGINE ON \(coin.symbol)")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.cyan)
                                    .cornerRadius(12)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(GlassBackgroundView())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.cyan)
                }
            }
        }
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Market Summary Card

struct MarketSummaryCard: View {
    let label: String
    let icon: String
    let iconColor: Color
    let primary: String
    let secondary: String
    var secondaryColor: Color = .mutedLabel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Label + icon row
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(iconColor)
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.mutedLabel)
                    .tracking(0.8)
            }

            // Primary value
            Text(primary)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Secondary value / subtitle
            if !secondary.isEmpty {
                Text(secondary)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(secondaryColor)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(width: 140, alignment: .leading)
        .background(.ultraThinMaterial)
        .background(Color.white.opacity(0.025))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(iconColor.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: iconColor.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Sentiment Detail View
struct SentimentDetailView: View {
    let coins: [CoinModel]
    @Environment(\.dismiss) var dismiss
    
    private var gainers: [CoinModel] {
        coins.filter { $0.change24h >= 0 }.sorted(by: { $0.change24h > $1.change24h })
    }
    
    private var losers: [CoinModel] {
        coins.filter { $0.change24h < 0 }.sorted(by: { $0.change24h < $1.change24h })
    }
    
    private var gainerPercentage: Double {
        coins.isEmpty ? 0 : (Double(gainers.count) / Double(coins.count)) * 100
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Title section
                    VStack(spacing: 8) {
                        Text("MARKET SENTIMENT")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        Text(gainerPercentage >= 50 ? "BULLISH" : "BEARISH")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(gainerPercentage >= 50 ? .green : .red)
                        
                        Text("Based on price action of top \(coins.count) assets over the past 24 hours.")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)
                    
                    // Visual progress bar
                    VStack(spacing: 8) {
                        HStack {
                            Text("\(gainers.count) Gainers")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.green)
                            Spacer()
                            Text("\(losers.count) Losers")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.red)
                        }
                        
                        GeometryReader { geo in
                            HStack(spacing: 0) {
                                Color.green
                                    .frame(width: geo.size.width * CGFloat(gainerPercentage / 100))
                                Color.red
                                    .frame(width: geo.size.width * CGFloat((100 - gainerPercentage) / 100))
                            }
                            .cornerRadius(6)
                        }
                        .frame(height: 12)
                        
                        Text(String(format: "%.0f%% of assets are gaining", gainerPercentage))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.04), lineWidth: 1)
                    )
                    
                    // Lists of Gainers & Losers
                    VStack(alignment: .leading, spacing: 16) {
                        Text("TOP GAINERS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                        
                        VStack(spacing: 10) {
                            ForEach(gainers.prefix(3)) { coin in
                                HStack {
                                    Text(coin.symbol)
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    Text(coin.name)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text(String(format: "%+.2f%%", coin.change24h))
                                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.green)
                                }
                                if coin != gainers.prefix(3).last {
                                    Divider().background(Color.white.opacity(0.04))
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.green.opacity(0.03))
                        .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("TOP LOSERS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.red)
                        
                        VStack(spacing: 10) {
                            ForEach(losers.prefix(3)) { coin in
                                HStack {
                                    Text(coin.symbol)
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    Text(coin.name)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text(String(format: "%+.2f%%", coin.change24h))
                                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.red)
                                }
                                if coin != losers.prefix(3).last {
                                    Divider().background(Color.white.opacity(0.04))
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.03))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(GlassBackgroundView())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.cyan)
                }
            }
        }
    }
}

// MARK: - Volume Detail View
struct VolumeDetailView: View {
    let coins: [CoinModel]
    @ObservedObject var engine: TradingEngine
    @Environment(\.dismiss) var dismiss
    
    private var sortedByVolume: [CoinModel] {
        coins.sorted(by: { $0.volume24h > $1.volume24h })
    }
    
    private var totalVolume: Double {
        coins.reduce(0) { $0 + $1.volume24h }
    }
    
    private var totalMarketCap: Double {
        coins.reduce(0) { $0 + $1.marketCap }
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("MARKET METRICS")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        Text(String(format: "$%.1fB", totalVolume / 1000.0))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan)
                        
                        Text("Total 24h Volume across all assets")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // Stats card
                    VStack(spacing: 14) {
                        MetricRow(title: "Total Market Capitalization", value: String(format: "$%.2fT", totalMarketCap / 1000.0), valueColor: .primary)
                        MetricRow(title: "Total 24h Trading Volume", value: String(format: "$%.2fB", totalVolume / 1000.0), valueColor: .cyan)
                        MetricRow(title: "Assets Tracked", value: "\(coins.count)", valueColor: .primary)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.04), lineWidth: 1)
                    )
                    
                    // List of assets by volume
                    VStack(alignment: .leading, spacing: 12) {
                        Text("VOLUME BREAKDOWN")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 12) {
                            ForEach(sortedByVolume.prefix(5)) { coin in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(coin.symbol)
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        Text(coin.name)
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(String(format: "$%.1fM", coin.volume24h))
                                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        let contribution = totalVolume > 0 ? (coin.volume24h / totalVolume) * 100.0 : 0.0
                                        Text(String(format: "%.1f%% of total", contribution))
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                    }
                                }
                                if coin != sortedByVolume.prefix(5).last {
                                    Divider().background(Color.white.opacity(0.04))
                                }
                            }
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.015))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.03), lineWidth: 0.5)
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(GlassBackgroundView())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.cyan)
                }
            }
        }
    }
}


