import SwiftUI

struct CoinModel: Identifiable, Hashable {
    let id = UUID()
    let symbol: String
    let name: String
    var price: Double
    var change24h: Double
    var marketCap: Double // in billions
    var volume24h: Double // in millions
    var sparkline: [Double]
}

struct HomeView: View {
    @ObservedObject var engine: TradingEngine
    @State private var coins: [CoinModel] = []
    @State private var selectedCoin: CoinModel?
    @State private var searchQuery: String = ""
    @State private var timer: Timer?
    
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
                    marketOverviewSection
                    
                    // MARK: - Search Field
                    searchBarSection
                    
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
                        .foregroundColor(.cyan)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.spring()) {
                            updatePrices()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                }
            }
            .sheet(item: $selectedCoin) { coin in
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
            }
            .onAppear {
                initializeCoins()
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private var filteredCoins: [CoinModel] {
        if searchQuery.isEmpty {
            return coins
        } else {
            return coins.filter {
                $0.name.lowercased().contains(searchQuery.lowercased()) ||
                $0.symbol.lowercased().contains(searchQuery.lowercased())
            }
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
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 61.0, repeats: true) { _ in
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.updatePrices()
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updatePrices() {
        if !engine.useSimulator && !engine.apiKey.isEmpty {
            let symbols = coins.map { $0.symbol }
            Task {
                if let results = await engine.fetchMultiplePrices(symbols: symbols) {
                    await MainActor.run {
                        for i in 0..<coins.count {
                            let sym = coins[i].symbol.uppercased()
                            if let data = results[sym] {
                                coins[i].price = data.price
                                coins[i].change24h = data.change24h
                                coins[i].marketCap = data.marketCap
                                coins[i].volume24h = data.volume24h
                                
                                if coins[i].sparkline.count > 14 {
                                    coins[i].sparkline.removeFirst()
                                }
                                coins[i].sparkline.append(data.price)
                            }
                        }
                        updateActiveEngine()
                    }
                } else {
                    await MainActor.run {
                        runMockUpdate()
                    }
                }
            }
        } else {
            runMockUpdate()
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
    
    private var marketOverviewSection: some View {
        let topMover = coins.max(by: { $0.change24h < $1.change24h })
        return VStack(alignment: .leading, spacing: 4) {
            Text("TOP GAINER")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(topMover?.symbol ?? "--")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(String(format: "%+.2f%%", topMover?.change24h ?? 0.0))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor((topMover?.change24h ?? 0.0) >= 0.0 ? .green : .red)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.03))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
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
                    selectedCoin = coin
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
                            Text(coin.price >= 1.0 ? "$\(String(format: "%.2f", coin.price))" : "$\(String(format: "%.4f", coin.price))")
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
                        
                        Text(coin.price >= 1.0 ? "$\(String(format: "%.2f", coin.price))" : "$\(String(format: "%.4f", coin.price))")
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
                        
                        MetricRow(title: "Market Capitalization", value: "$\(String(format: "%.1f", coin.marketCap))B")
                        MetricRow(title: "24h Trading Volume", value: "$\(String(format: "%.1f", coin.volume24h))M")
                        
                        let holdings = engine.portfolio.holdings[coin.symbol] ?? 0.0
                        let valuation = holdings * coin.price
                        MetricRow(title: "Your Holdings", value: "\(String(format: "%.4f", holdings)) \(coin.symbol)")
                        MetricRow(title: "Holdings Value", value: "$\(String(format: "%.2f", valuation))", valueColor: .cyan)
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
