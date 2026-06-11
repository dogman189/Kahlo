import Foundation
import Combine

public struct Portfolio: Codable {
    public var usd: Double
    public var holdings: [String: Double]
}

public struct HistoryPoint: Codable, Identifiable {
    public var id = UUID()
    public var price: Double
    public var sma: Double?
    public var upper: Double?
    public var lower: Double?
    public var rsi: Double?
    public var timestamp: String
    public var trade: String? // "BUY", "SELL", "STOP_LOSS", "TAKE_PROFIT"
}

@MainActor
public final class TradingEngine: ObservableObject {
    // Basic settings
    @Published public var isRunning: Bool = false
    @Published public var symbol: String = "BTC"
    @Published public var interval: Int = 10 // seconds for mobile testing, instead of 300
    @Published public var tradeAmt: Double = 500.0
    @Published public var apiKey: String = ""
    @Published public var useSimulator: Bool = true // Simulator mode by default so users can run it instantly
    @Published public var cachedPrices: [String: Double] = [:]
    @Published public var availableSymbols: [String] = ["BTC", "ETH", "SOL", "ADA", "DOT", "LINK", "DOGE"]
    @Published public var lastMarketRefresh: Date = Date()

    // Market / Indicators state
    @Published public var price: Double = 0.0
    @Published public var sma: Double?
    @Published public var upper: Double?
    @Published public var lower: Double?
    @Published public var rsi: Double?
    @Published public var bandwidth: Double?

    // Portfolio
    @Published public var portfolio = Portfolio(usd: 10000.0, holdings: [:])
    @Published public var startingWallet: Double = 10000.0
    @Published public var avgBuyPrice: Double?

    // Bot settings
    @Published public var positionMode: String = "percent" // "percent" or "fixed"
    @Published public var buyRiskPct: Double = 0.20
    @Published public var stopLossPct: Double = 0.07
    @Published public var takeProfitPct: Double = 0.10
    @Published public var aiLearningRate: Double = 0.005
    @Published public var bbWindow: Int = 20
    @Published public var bbStdDev: Double = 2.0
    @Published public var rsiPeriod: Int = 14
    @Published public var rsiOversold: Double = 35
    @Published public var rsiOverbought: Double = 65

    // AI & Performance Stats
    @Published public var totalTrades: Int = 0
    @Published public var totalBuys: Int = 0
    @Published public var totalSells: Int = 0
    @Published public var stopLossesHit: Int = 0
    @Published public var aiPrediction: Double = 0.0
    @Published public var aiAccuracyScore: Double = 0.0
    @Published public var nnTrainLoss: Double = 0.0
    @Published public var nnLayerNorms: [Double] = []
    @Published public var nnActivations: [[Double]] = []

    // Historical tracking (max 50)
    @Published public var history: [HistoryPoint] = []
    @Published public var logs: [String] = []

    // Prices queue
    private var priceHistory: [Double] = []

    // Neural Network
    public var neuralNet: NeuralNetwork?
    private var task: Task<Void, Never>?
    private var marketRefreshTimer: Timer?

    // Constants
    private let minBandwidth: Double = 0.0002
    private let tradeCooldown: Int = 3
    private var intervalCount: Int = 0
    private var lastTradeInterval: Int = 0
    private var wasBelowLower: Bool = false
    private var wasAboveUpper: Bool = false
    private var lastTickTrade: String?
    
    // Simulator helper state
    private var simTrend: Double = 0.0
    private var basePrice: Double = 60000.0

    public init() {
        // Load default config or saved values if preferred.
        // For simplicity, we initialize with defaults.
        loadConfig()
        startMarketRefreshTimer()
    }

    /// Centralized 61-second timer that refreshes market prices for all views.
    /// Runs continuously regardless of which tab is active.
    private func startMarketRefreshTimer() {
        marketRefreshTimer?.invalidate()
        Task { @MainActor in
            await self.refreshMarketData()
        }
        marketRefreshTimer = Timer.scheduledTimer(withTimeInterval: 61.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.refreshMarketData()
            }
        }
    }

    /// Fetches top 100 coins and updates lastMarketRefresh so observing views refresh.
    public func refreshMarketData() async {
        _ = await fetchTop100Coins()
        lastMarketRefresh = Date()
    }

    public func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        let entry = "[\(timestamp)] \(message)"
        logs.append(entry)
        if logs.count > 200 {
            logs.removeFirst()
        }
        print(entry)
    }

    public func start() {
        guard !isRunning else { return }
        
        // Save configurations to UserDefaults
        saveConfig()

        // Reset runtime values
        intervalCount = 0
        lastTradeInterval = 0
        wasBelowLower = false
        wasAboveUpper = false
        priceHistory.removeAll()
        history.removeAll()
        logs.removeAll()

        log("System: Data stream initialized for \(symbol)")
        let arch = [8, 16, 8, 4, 1]
        neuralNet = NeuralNetwork(layerSizes: arch, learningRate: aiLearningRate)
        log("System: Neural Network online — arch \(arch), lr=\(aiLearningRate)")


        // Configure simulator base price according to symbol
        switch symbol.uppercased() {
        case "ETH":
            basePrice = 3000.0
        case "SOL":
            basePrice = 150.0
        default:
            basePrice = 60000.0
        }
        simTrend = 0.0

        isRunning = true

        task = Task {
            while isRunning {
                await botTick()
                do {
                    try await Task.sleep(nanoseconds: UInt64(interval) * 1_000_000_000)
                } catch {
                    break
                }
            }
        }
    }

    public func stop() {
        guard isRunning else { return }
        isRunning = false
        task?.cancel()
        task = nil
        log("System: Trading Bot stopped.")
    }

    // MARK: - Background Execution

    /// Public wrapper around botTick so BackgroundTaskManager can call it
    /// from a BGTask handler.  Marked nonisolated so it can be called from
    /// any context; it immediately hops to MainActor via the await chain.
    public func botTickBackground() async {
        await botTick()
    }

    /// Called by ContentView when the app enters the background.
    public func handleDidEnterBackground() {
        guard isRunning else { return }
        BackgroundTaskManager.shared.beginUIBackgroundTask()
        BackgroundTaskManager.shared.scheduleAppRefresh()
        BackgroundTaskManager.shared.scheduleProcessingTask()
        log("System: Background execution scheduled — bot will continue running.")
        NotificationManager.shared.sendAlgoRunningInBackgroundNotification(symbol: symbol)
    }

    /// Called by ContentView when the app returns to the foreground.
    public func handleWillEnterForeground() {
        BackgroundTaskManager.shared.endUIBackgroundTask()
        log("System: App returned to foreground — background tasks released.")
    }

    // MARK: - Manual Trading

    /// Manually buy `symbol` using `usdAmount` of USD at the current price.
    /// Returns a human-readable result string.
    @discardableResult
    public func manualBuy(symbol targetSymbol: String, usdAmount: Double) -> String {
        let currentPrice = priceForSymbol(targetSymbol)
        guard currentPrice > 0 else {
            let msg = "Manual BUY failed — no price available for \(targetSymbol)."
            log(msg)
            return msg
        }
        guard usdAmount > 0, usdAmount <= portfolio.usd else {
            let msg = "Manual BUY failed — invalid amount ($\(String(format: "%.2f", usdAmount))) or insufficient balance ($\(String(format: "%.2f", portfolio.usd)))."
            log(msg)
            return msg
        }

        let qty = usdAmount / currentPrice
        portfolio.usd -= usdAmount

        let prev = portfolio.holdings[targetSymbol] ?? 0.0
        portfolio.holdings[targetSymbol] = prev + qty

        // Update average buy price for the active symbol
        if targetSymbol == symbol {
            let prevAvg = avgBuyPrice ?? currentPrice
            if prev > 0 {
                avgBuyPrice = ((prevAvg * prev) + (currentPrice * qty)) / (prev + qty)
            } else {
                avgBuyPrice = currentPrice
            }
        }

        totalTrades += 1
        totalBuys += 1

        let msg = "Manual BUY: \(String(format: "%.6f", qty)) \(targetSymbol) @ $\(String(format: "%.2f", currentPrice)) for $\(String(format: "%.2f", usdAmount))"
        log("Execution: \(msg)")
        NotificationManager.shared.sendTradeNotification(side: "BUY", symbol: targetSymbol, price: currentPrice, amount: qty)
        saveConfig()
        return msg
    }

    /// Manually sell `quantity` of `symbol` at the current price.
    /// Returns a human-readable result string.
    @discardableResult
    public func manualSell(symbol targetSymbol: String, quantity: Double) -> String {
        let currentPrice = priceForSymbol(targetSymbol)
        guard currentPrice > 0 else {
            let msg = "Manual SELL failed — no price available for \(targetSymbol)."
            log(msg)
            return msg
        }
        let owned = portfolio.holdings[targetSymbol] ?? 0.0
        guard quantity > 0, quantity <= owned else {
            let msg = "Manual SELL failed — invalid quantity (\(String(format: "%.6f", quantity))) or insufficient holdings (\(String(format: "%.6f", owned)))."
            log(msg)
            return msg
        }

        let proceeds = quantity * currentPrice
        portfolio.usd += proceeds
        portfolio.holdings[targetSymbol] = owned - quantity

        var pnlStr = ""
        if targetSymbol == symbol, let entry = avgBuyPrice {
            let pnl = ((currentPrice - entry) / entry) * 100.0
            pnlStr = " | PnL: \(String(format: "%+.2f", pnl))%"
        }

        if (portfolio.holdings[targetSymbol] ?? 0.0) < 1e-8 {
            portfolio.holdings[targetSymbol] = 0.0
            if targetSymbol == symbol { avgBuyPrice = nil }
        }

        totalTrades += 1
        totalSells += 1

        let msg = "Manual SELL: \(String(format: "%.6f", quantity)) \(targetSymbol) @ $\(String(format: "%.2f", currentPrice)) for $\(String(format: "%.2f", proceeds))\(pnlStr)"
        log("Execution: \(msg)")
        NotificationManager.shared.sendTradeNotification(side: "SELL", symbol: targetSymbol, price: currentPrice, amount: quantity)
        saveConfig()
        return msg
    }

    /// Manually sell ALL holdings of `symbol` at the current price.
    @discardableResult
    public func manualSellAll(symbol targetSymbol: String) -> String {
        let owned = portfolio.holdings[targetSymbol] ?? 0.0
        guard owned > 0 else {
            let msg = "Manual SELL ALL failed — no \(targetSymbol) holdings."
            log(msg)
            return msg
        }
        return manualSell(symbol: targetSymbol, quantity: owned)
    }

    /// Manually add USD funds to the portfolio balance.
    public func addFunds(_ usdAmount: Double) {
        guard usdAmount > 0 else { return }
        portfolio.usd += usdAmount
        startingWallet += usdAmount
        saveConfig()
        log("System: Manually added $\(String(format: "%.2f", usdAmount)) USD to portfolio.")
    }

    /// Manually remove USD funds from the portfolio balance.
    public func removeFunds(_ usdAmount: Double) {
        guard usdAmount > 0 else { return }
        let amountToRemove = min(usdAmount, portfolio.usd)
        guard amountToRemove > 0 else { return }
        portfolio.usd -= amountToRemove
        startingWallet = max(0.0, startingWallet - amountToRemove)
        saveConfig()
        log("System: Manually removed $\(String(format: "%.2f", amountToRemove)) USD from portfolio.")
    }

    /// Resets the portfolio and trading stats to startingWallet and zero holdings/stats.
    public func resetPortfolio() {
        portfolio = Portfolio(usd: startingWallet, holdings: [:])
        avgBuyPrice = nil
        totalTrades = 0
        totalBuys = 0
        totalSells = 0
        stopLossesHit = 0
        saveConfig()
        log("System: Portfolio and trade statistics manually reset.")
    }


    /// Returns the current price for a symbol.  Uses the live engine price
    /// if the symbol matches, otherwise returns a rough default (useful for
    /// multi-coin manual trading when the engine is watching one symbol).
    public func priceForSymbol(_ sym: String) -> Double {
        let cleanSym = sym.uppercased()
        if cleanSym == symbol.uppercased() && price > 0 {
            return price
        }
        if let cached = cachedPrices[cleanSym] {
            return cached
        }
        // Fallback prices for symbols not actively tracked by the engine.
        let fallbacks: [String: Double] = [
            "BTC": 68450.0, "ETH": 3520.0, "SOL": 162.50,
            "ADA": 0.485, "DOT": 6.42, "LINK": 15.35, "DOGE": 0.142
        ]
        return fallbacks[cleanSym] ?? 0.0
    }

    private func botTick() async {
        // Fetch or simulate price
        guard let priceFetched = await fetchPrice() else {
            stop()
            return
        }

        self.price = priceFetched
        priceHistory.append(priceFetched)
        intervalCount += 1

        let (smaComputed, upperComputed, lowerComputed) = computeBollinger()
        let rsiComputed = computeRSI()
        let bandwidthComputed = computeBandwidth(sma: smaComputed, upper: upperComputed, lower: lowerComputed)

        self.sma = smaComputed
        self.upper = upperComputed
        self.lower = lowerComputed
        self.rsi = rsiComputed
        self.bandwidth = bandwidthComputed

        guard let currentSma = smaComputed, let currentRsi = rsiComputed else {
            let needed = max(bbWindow, rsiPeriod + 1) - priceHistory.count
            log("Calibrating: $\(String(format: "%.2f", priceFetched)) — \(needed) more sample(s) needed")
            saveHistoryPoint(price: priceFetched, sma: nil, upper: nil, lower: nil, rsi: nil)
            return
        }

        // Feature engineering
        let features = computeFeatures(price: priceFetched, sma: currentSma, upper: upperComputed ?? priceFetched, lower: lowerComputed ?? priceFetched, rsi: currentRsi, bandwidth: bandwidthComputed ?? 0.0)

        // 1. Neural Network Training (online backpropagation)
        if let nn = neuralNet, let lastPriceVal = nn.lastPrice {
            let actualPct = ((priceFetched - lastPriceVal) / lastPriceVal) * 100.0
            let predicted = nn.lastPrediction

            nn.updateAccuracy(predicted: predicted, actual: actualPct)

            // Clamp target to tanh output range [-1.0, 1.0] after scaling
            let targetClamped = max(-1.0, min(1.0, actualPct * 10.0))
            if let lastFeatures = nn.lastActivations?.first {
                nn.train(inputs: lastFeatures, target: targetClamped)
            }

            self.aiAccuracyScore = nn.accuracy
            self.nnTrainLoss = nn.trainLoss
            self.nnLayerNorms = nn.getLayerNorms()
            self.nnActivations = nn.lastActivations ?? []
        }

        // 2. Neural Network Prediction
        var pred = 0.0
        if let nn = neuralNet, let upperVal = upperComputed, let lowerVal = lowerComputed, (upperVal - lowerVal) != 0 {
            pred = nn.predict(inputs: features)
            nn.lastPrice = priceFetched
            self.aiPrediction = pred
            self.nnActivations = nn.lastActivations ?? []
        } else {
            self.aiPrediction = 0.0
        }

        let predStr = String(format: "%+.4f", pred)
        log("Signal: $\(String(format: "%.2f", priceFetched)) | RSI=\(String(format: "%.1f", currentRsi)) | NN output: \(predStr) (Acc: \(String(format: "%.1f", aiAccuracyScore))%)")

        // Trailing calculations / Cooldown & Risk
        let intervalsSinceTrade = intervalCount - lastTradeInterval
        let onCooldown = intervalsSinceTrade < tradeCooldown
        let holdings = portfolio.holdings[symbol] ?? 0.0

        // Stop-loss check
        if let entry = avgBuyPrice, holdings > 0.0, priceFetched < entry * (1.0 - stopLossPct) {
            if executeTrade(side: "SELL", price: priceFetched, reason: "stop-loss") {
                stopLossesHit += 1
                lastTradeInterval = intervalCount
                wasAboveUpper = false
                wasBelowLower = false
            }
            saveHistoryPoint(price: priceFetched, sma: smaComputed, upper: upperComputed, lower: lowerComputed, rsi: rsiComputed)
            return
        }

        // Take-profit check
        if let entry = avgBuyPrice, holdings > 0.0, priceFetched > entry * (1.0 + takeProfitPct) {
            if executeTrade(side: "SELL", price: priceFetched, reason: "take-profit") {
                lastTradeInterval = intervalCount
                wasAboveUpper = false
                wasBelowLower = false
            }
            saveHistoryPoint(price: priceFetched, sma: smaComputed, upper: upperComputed, lower: lowerComputed, rsi: rsiComputed)
            return
        }

        // Bandwidth squeeze check
        if let bwVal = bandwidthComputed, bwVal < minBandwidth {
            saveHistoryPoint(price: priceFetched, sma: smaComputed, upper: upperComputed, lower: lowerComputed, rsi: rsiComputed)
            return
        }

        // Band tracking
        if let lowerVal = lowerComputed, priceFetched < lowerVal {
            wasBelowLower = true
        } else if let upperVal = upperComputed, priceFetched > upperVal {
            wasAboveUpper = true
        }
        
        // Buy Conditions
        else if wasBelowLower, let lowerVal = lowerComputed, priceFetched >= lowerVal {
            wasBelowLower = false
            if onCooldown {
                log("Risk: BUY skipped — cooldown")
            } else if currentRsi > rsiOversold {
                log("Filter: BUY skipped — RSI \(String(format: "%.1f", currentRsi)) not oversold")
            } else if pred < 0.0 {
                log("NN Filter: BUY vetoed — network predicts drop (\(predStr))")
            } else {
                if executeTrade(side: "BUY", price: priceFetched, reason: "BB re-entry + RSI + NN Appv") {
                    lastTradeInterval = intervalCount
                }
            }
        }

        // Sell Conditions
        else if wasAboveUpper, let upperVal = upperComputed, priceFetched <= upperVal {
            wasAboveUpper = false
            if onCooldown {
                log("Risk: SELL skipped — cooldown")
            } else if currentRsi < rsiOverbought {
                log("Filter: SELL skipped — RSI \(String(format: "%.1f", currentRsi)) not overbought")
            } else if pred > 0.0 {
                log("NN Filter: SELL vetoed — network predicts pump (\(predStr))")
            } else {
                if executeTrade(side: "SELL", price: priceFetched, reason: "BB re-entry + RSI + NN Appv") {
                    lastTradeInterval = intervalCount
                }
            }
        }

        saveHistoryPoint(price: priceFetched, sma: smaComputed, upper: upperComputed, lower: lowerComputed, rsi: rsiComputed)
    }

    private func executeTrade(side: String, price: Double, reason: String) -> Bool {
        if side == "BUY" {
            var tradeAmount = positionMode == "fixed" ? tradeAmt : portfolio.usd * buyRiskPct
            if tradeAmount > portfolio.usd {
                tradeAmount = portfolio.usd
            }

            if tradeAmount < 1.0 {
                log("Risk: Skipped BUY — insufficient USD balance ($\(String(format: "%.2f", portfolio.usd)))")
                return false
            }

            let bought = tradeAmount / price
            portfolio.usd -= tradeAmount

            let prevHoldings = portfolio.holdings[symbol] ?? 0.0
            let prevAvg = avgBuyPrice ?? price
            portfolio.holdings[symbol] = prevHoldings + bought

            if prevHoldings > 0 {
                avgBuyPrice = ((prevAvg * prevHoldings) + (price * bought)) / (prevHoldings + bought)
            } else {
                avgBuyPrice = price
            }

            totalTrades += 1
            totalBuys += 1
            lastTickTrade = "BUY"
            log("Execution: Filled BUY \(String(format: "%.6f", bought)) \(symbol) @ $\(String(format: "%.2f", price)) | Risked: $\(String(format: "%.2f", tradeAmount)) | Reason: \(reason)")
            // Notify user about the trade (useful when app is in background)
            NotificationManager.shared.sendTradeNotification(side: "BUY", symbol: symbol, price: price, amount: bought)
            saveConfig()
            return true
        } else if side == "SELL" {
            let owned = portfolio.holdings[symbol] ?? 0.0
            if owned <= 0 {
                log("Risk: Skipped SELL — no \(symbol) holdings")
                return false
            }

            let sellPct = reason == "stop-loss" ? 1.0 : 0.50
            let sellQty = owned * sellPct
            let proceeds = sellQty * price
            portfolio.usd += proceeds
            portfolio.holdings[symbol] = owned - sellQty

            var pnlStr = ""
            if let entry = avgBuyPrice {
                let pnl = ((price - entry) / entry) * 100.0
                pnlStr = String(format: " | PnL: %+.2f%%", pnl)
            }

            if (portfolio.holdings[symbol] ?? 0.0) < 1e-8 {
                portfolio.holdings[symbol] = 0.0
                avgBuyPrice = nil
            }

            totalTrades += 1
            totalSells += 1
            lastTickTrade = reason == "stop-loss" ? "STOP_LOSS" : "SELL"
            log("Execution: Filled SELL \(String(format: "%.6f", sellQty)) \(symbol) @ $\(String(format: "%.2f", price)) | Proceeds: $\(String(format: "%.2f", proceeds))\(pnlStr) | Reason: \(reason)")
            // Notify user about the trade (useful when app is in background)
            if reason == "stop-loss" || reason == "take-profit" {
                let pnlVal = avgBuyPrice.map { ((price - $0) / $0) * 100.0 } ?? 0.0
                NotificationManager.shared.sendRiskNotification(event: reason, symbol: symbol, price: price, pnl: pnlVal)
            } else {
                NotificationManager.shared.sendTradeNotification(side: "SELL", symbol: symbol, price: price, amount: sellQty)
            }
            saveConfig()
            return true
        }

        return false
    }

    private func saveHistoryPoint(price: Double, sma: Double?, upper: Double?, lower: Double?, rsi: Double?) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        let point = HistoryPoint(price: price, sma: sma, upper: upper, lower: lower, rsi: rsi, timestamp: timestamp, trade: lastTickTrade)
        history.append(point)
        if history.count > 50 {
            history.removeFirst()
        }
        lastTickTrade = nil
    }

    // Indicator calculations
    private func computeBollinger() -> (sma: Double?, upper: Double?, lower: Double?) {
        guard priceHistory.count >= bbWindow else { return (nil, nil, nil) }
        let window = Array(priceHistory.suffix(bbWindow))
        let mean = window.reduce(0.0, +) / Double(bbWindow)
        
        let sumSquaredDiff = window.map { pow($0 - mean, 2) }.reduce(0.0, +)
        let variance = sumSquaredDiff / Double(bbWindow - 1)
        let stdDev = sqrt(variance)

        return (mean, mean + (stdDev * bbStdDev), mean - (stdDev * bbStdDev))
    }

    private func computeRSI() -> Double? {
        guard priceHistory.count >= rsiPeriod + 1 else { return nil }
        let recent = Array(priceHistory.suffix(rsiPeriod + 1))
        
        var gains = 0.0
        var losses = 0.0
        
        for i in 1..<recent.count {
            let diff = recent[i] - recent[i-1]
            if diff > 0 {
                gains += diff
            } else {
                losses += abs(diff)
            }
        }
        
        let avgGain = gains / Double(rsiPeriod)
        let avgLoss = max(losses / Double(rsiPeriod), 1e-9)
        
        let rs = avgGain / avgLoss
        let computedRsi = 100.0 - (100.0 / (1.0 + rs))
        return Double(round(100 * computedRsi) / 100)
    }

    private func computeBandwidth(sma: Double?, upper: Double?, lower: Double?) -> Double? {
        guard let smaVal = sma, let upperVal = upper, let lowerVal = lower, smaVal != 0.0 else { return nil }
        return (upperVal - lowerVal) / smaVal
    }

    private func computeFeatures(price: Double, sma: Double, upper: Double, lower: Double, rsi: Double, bandwidth: Double) -> [Double] {
        var features = [Double](repeating: 0.0, count: 8)
        let bbRange = max(upper - lower, 1.0)

        // 0. RSI Normalized
        features[0] = (rsi - 50.0) / 50.0

        // 1. Bollinger Band position
        features[1] = ((price - lower) / bbRange) - 0.5

        // 2. Bandwidth (scaled)
        features[2] = bandwidth * 100.0

        // 3. 5-tick momentum
        if priceHistory.count >= 6 {
            let oldP = priceHistory[priceHistory.count - 6]
            features[3] = oldP != 0.0 ? ((price - oldP) / oldP) * 100.0 : 0.0
        }

        // 4. Volatility (stddev of last 10 returns)
        if priceHistory.count >= 11 {
            var returns: [Double] = []
            for i in stride(from: priceHistory.count - 10, to: priceHistory.count, by: 1) {
                let pPrev = priceHistory[i - 1]
                let pCurr = priceHistory[i]
                if pPrev != 0.0 {
                    returns.append(((pCurr - pPrev) / pPrev) * 100.0)
                }
            }
            if returns.count >= 2 {
                let mean = returns.reduce(0.0, +) / Double(returns.count)
                let variance = returns.map { pow($0 - mean, 2) }.reduce(0.0, +) / Double(returns.count - 1)
                features[4] = sqrt(variance)
            } else if let first = returns.first {
                features[4] = abs(first)
            }
        }

        // 5. Price / SMA ratio deviation
        features[5] = ((price - sma) / sma) * 100.0

        // 6. Consecutive direction score
        if priceHistory.count >= 4 {
            var streak = 0.0
            for i in stride(from: priceHistory.count - 1, through: priceHistory.count - 3, by: -1) {
                if priceHistory[i] > priceHistory[i-1] {
                    streak += 1.0
                } else if priceHistory[i] < priceHistory[i-1] {
                    streak -= 1.0
                }
            }
            features[6] = streak / 3.0
        }

        // 7. Mean reversion intensity (z-score from SMA based on last 5 prices)
        if priceHistory.count >= 5 {
            let recent = Array(priceHistory.suffix(5))
            let mean = recent.reduce(0.0, +) / Double(recent.count)
            let variance = recent.map { pow($0 - mean, 2) }.reduce(0.0, +) / Double(recent.count - 1)
            let std = variance > 0.0 ? sqrt(variance) : 1.0
            features[7] = (price - sma) / std
        }

        return features
    }

    public func fetchMultiplePrices(symbols: [String]) async -> [String: (price: Double, change24h: Double, marketCap: Double, volume24h: Double)]? {
        if apiKey.isEmpty {
            return nil
        }
        
        let symbolList = symbols.map { $0.uppercased() }.joined(separator: ",")
        let urlStr = "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest?symbol=\(symbolList)&convert=USD"
        guard let url = URL(string: urlStr) else { return nil }
        
        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "X-CMC_PRO_API_KEY")
        request.timeoutInterval = 10.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataDict = json["data"] as? [String: Any] {
                var result: [String: (price: Double, change24h: Double, marketCap: Double, volume24h: Double)] = [:]
                for sym in symbols {
                    let upperSym = sym.uppercased()
                    if let symDict = dataDict[upperSym] as? [String: Any],
                       let quoteDict = symDict["quote"] as? [String: Any],
                       let usdDict = quoteDict["USD"] as? [String: Any],
                       let priceVal = usdDict["price"] as? Double,
                       let changeVal = usdDict["percent_change_24h"] as? Double,
                       let capVal = usdDict["market_cap"] as? Double,
                       let volVal = usdDict["volume_24h"] as? Double {
                        result[upperSym] = (priceVal, changeVal, capVal / 1_000_000_000.0, volVal / 1_000_000.0)
                        
                        // Cache the price in our published dict
                        self.cachedPrices[upperSym] = priceVal
                    }
                }
                return result
            }
        } catch {
            print("Error fetching multiple prices: \(error.localizedDescription)")
        }
        return nil
    }

    // Price Fetching / Simulation
    private func fetchPrice() async -> Double? {
        if useSimulator {
            // Generate realistic mock market movement
            // Random walk with mean reversion towards the base price + small momentum
            let noise = Double.randomNormal(mean: 0.0, stdDev: basePrice * 0.003)
            simTrend = (simTrend * 0.8) + Double.randomNormal(mean: 0.0, stdDev: basePrice * 0.0005)
            let reversion = (basePrice - (price == 0.0 ? basePrice : price)) * 0.005
            let newPrice = (price == 0.0 ? basePrice : price) + noise + simTrend + reversion
            return max(newPrice, 1.0)
        } else {
            // CoinMarketCap Pro API call
            guard !apiKey.isEmpty else {
                log("Error: API Key is required when Simulator Mode is OFF")
                return nil
            }

            let urlStr = "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest?symbol=\(symbol.uppercased())&convert=USD"
            guard let url = URL(string: urlStr) else { return nil }

            var request = URLRequest(url: url)
            request.addValue(apiKey, forHTTPHeaderField: "X-CMC_PRO_API_KEY")
            request.timeoutInterval = 10.0

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    log("Error: Invalid response status from CMC API")
                    return nil
                }

                // Decode simple JSON path: data[SYMBOL].quote.USD.price
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataDict = json["data"] as? [String: Any],
                   let symDict = dataDict[symbol.uppercased()] as? [String: Any],
                   let quoteDict = symDict["quote"] as? [String: Any],
                   let usdDict = quoteDict["USD"] as? [String: Any],
                   let priceVal = usdDict["price"] as? Double {
                    return priceVal
                } else {
                    log("Error: Failed to parse price from CMC response")
                    return nil
                }
            } catch {
                log("Error: CMC fetch failed \(error.localizedDescription)")
                return nil
            }
        }
    }

    // Persistence
    private func saveConfig() {
        let defaults = UserDefaults.standard
        defaults.set(apiKey, forKey: "monet_api_key")
        defaults.set(symbol, forKey: "monet_symbol")
        defaults.set(interval, forKey: "monet_interval")
        defaults.set(tradeAmt, forKey: "monet_trade_amt")
        defaults.set(startingWallet, forKey: "monet_wallet")
        defaults.set(positionMode, forKey: "monet_pos_mode")
        defaults.set(buyRiskPct, forKey: "monet_risk_pct")
        defaults.set(stopLossPct, forKey: "monet_stop_loss")
        defaults.set(takeProfitPct, forKey: "monet_take_profit")
        defaults.set(aiLearningRate, forKey: "monet_lr")
        defaults.set(bbWindow, forKey: "monet_bb_window")
        defaults.set(bbStdDev, forKey: "monet_bb_stddev")
        defaults.set(rsiPeriod, forKey: "monet_rsi_period")
        defaults.set(rsiOversold, forKey: "monet_rsi_oversold")
        defaults.set(rsiOverbought, forKey: "monet_rsi_overbought")
        defaults.set(useSimulator, forKey: "monet_use_simulator")

        // Save portfolio
        if let encodedPortfolio = try? JSONEncoder().encode(portfolio) {
            defaults.set(encodedPortfolio, forKey: "monet_portfolio")
        }
        // Save avgBuyPrice
        if let avgBuyPrice = avgBuyPrice {
            defaults.set(avgBuyPrice, forKey: "monet_avg_buy_price")
        } else {
            defaults.removeObject(forKey: "monet_avg_buy_price")
        }
        // Save trade stats
        defaults.set(totalTrades, forKey: "monet_total_trades")
        defaults.set(totalBuys, forKey: "monet_total_buys")
        defaults.set(totalSells, forKey: "monet_total_sells")
        defaults.set(stopLossesHit, forKey: "monet_stop_losses_hit")
    }

    private func loadConfig() {
        let defaults = UserDefaults.standard
        apiKey = defaults.string(forKey: "monet_api_key") ?? ""
        symbol = defaults.string(forKey: "monet_symbol") ?? "BTC"
        interval = defaults.integer(forKey: "monet_interval")
        if interval == 0 { interval = 10 }
        tradeAmt = defaults.double(forKey: "monet_trade_amt")
        if tradeAmt == 0.0 { tradeAmt = 500.0 }
        startingWallet = defaults.double(forKey: "monet_wallet")
        if startingWallet == 0.0 { startingWallet = 10000.0 }
        
        // Load portfolio
        if let savedPortfolioData = defaults.data(forKey: "monet_portfolio"),
           let decodedPortfolio = try? JSONDecoder().decode(Portfolio.self, from: savedPortfolioData) {
            portfolio = decodedPortfolio
        } else {
            portfolio = Portfolio(usd: startingWallet, holdings: [:])
        }

        // Load avgBuyPrice
        if defaults.object(forKey: "monet_avg_buy_price") != nil {
            avgBuyPrice = defaults.double(forKey: "monet_avg_buy_price")
        } else {
            avgBuyPrice = nil
        }

        // Load stats
        totalTrades = defaults.integer(forKey: "monet_total_trades")
        totalBuys = defaults.integer(forKey: "monet_total_buys")
        totalSells = defaults.integer(forKey: "monet_total_sells")
        stopLossesHit = defaults.integer(forKey: "monet_stop_losses_hit")

        positionMode = defaults.string(forKey: "monet_pos_mode") ?? "percent"
        buyRiskPct = defaults.double(forKey: "monet_risk_pct")
        if buyRiskPct == 0.0 { buyRiskPct = 0.20 }
        stopLossPct = defaults.double(forKey: "monet_stop_loss")
        if stopLossPct == 0.0 { stopLossPct = 0.07 }
        takeProfitPct = defaults.double(forKey: "monet_take_profit")
        if takeProfitPct == 0.0 { takeProfitPct = 0.10 }
        aiLearningRate = defaults.double(forKey: "monet_lr")
        if aiLearningRate == 0.0 { aiLearningRate = 0.005 }
        bbWindow = defaults.integer(forKey: "monet_bb_window")
        if bbWindow == 0 { bbWindow = 20 }
        bbStdDev = defaults.double(forKey: "monet_bb_stddev")
        if bbStdDev == 0.0 { bbStdDev = 2.0 }
        rsiPeriod = defaults.integer(forKey: "monet_rsi_period")
        if rsiPeriod == 0 { rsiPeriod = 14 }
        rsiOversold = defaults.double(forKey: "monet_rsi_oversold")
        if rsiOversold == 0.0 { rsiOversold = 35.0 }
        rsiOverbought = defaults.double(forKey: "monet_rsi_overbought")
        if rsiOverbought == 0.0 { rsiOverbought = 65.0 }
        if defaults.object(forKey: "monet_use_simulator") != nil {
            useSimulator = defaults.bool(forKey: "monet_use_simulator")
        }
    }

    public func fetchTop100Coins() async -> [CMCListingCoin]? {
        if apiKey.isEmpty {
            return generateMockTop100()
        }
        
        let urlStr = "https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest?limit=100&convert=USD"
        guard let url = URL(string: urlStr) else { return generateMockTop100() }
        
        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "X-CMC_PRO_API_KEY")
        request.timeoutInterval = 15.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return generateMockTop100()
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataArray = json["data"] as? [[String: Any]] {
                var coinsList: [CMCListingCoin] = []
                var updatedCachedPrices: [String: Double] = [:]
                var symbolsList: [String] = []
                
                for item in dataArray {
                    if let symbolVal = item["symbol"] as? String,
                       let nameVal = item["name"] as? String,
                       let quoteDict = item["quote"] as? [String: Any],
                       let usdDict = quoteDict["USD"] as? [String: Any],
                       let priceVal = usdDict["price"] as? Double,
                       let changeVal = usdDict["percent_change_24h"] as? Double,
                       let capVal = usdDict["market_cap"] as? Double,
                       let volVal = usdDict["volume_24h"] as? Double {
                        
                        let cleanSym = symbolVal.uppercased()
                        let coin = CMCListingCoin(
                            symbol: cleanSym,
                            name: nameVal,
                            price: priceVal,
                            change24h: changeVal,
                            marketCap: capVal / 1_000_000_000.0,
                            volume24h: volVal / 1_000_000.0
                        )
                        coinsList.append(coin)
                        updatedCachedPrices[cleanSym] = priceVal
                        symbolsList.append(cleanSym)
                    }
                }
                
                if !coinsList.isEmpty {
                    self.cachedPrices = updatedCachedPrices
                    self.availableSymbols = symbolsList
                    return coinsList
                }
            }
        } catch {
            print("Error fetching listings: \(error.localizedDescription)")
        }
        return generateMockTop100()
    }

    private func generateMockTop100() -> [CMCListingCoin] {
        let baseCoins = [
            ("BTC", "Bitcoin", 68450.0, 1340.5, 28400.0),
            ("ETH", "Ethereum", 3520.0, 422.3, 14200.0),
            ("USDT", "Tether", 1.0, 112.5, 48000.0),
            ("BNB", "BNB", 585.0, 87.2, 1600.0),
            ("SOL", "Solana", 162.5, 75.1, 3800.0),
            ("USDC", "USDC", 1.0, 32.4, 6200.0),
            ("XRP", "XRP", 0.49, 27.2, 980.0),
            ("DOGE", "Dogecoin", 0.142, 20.5, 1850.0),
            ("ADA", "Cardano", 0.485, 17.3, 420.0),
            ("SHIB", "Shiba Inu", 0.000022, 12.9, 850.0),
            ("AVAX", "Avalanche", 32.5, 12.7, 390.0),
            ("DOT", "Polkadot", 6.42, 9.2, 180.0),
            ("LINK", "Chainlink", 15.35, 9.1, 310.0),
            ("TRX", "TRON", 0.115, 10.1, 280.0),
            ("NEAR", "Near Protocol", 5.8, 6.2, 450.0),
            ("MATIC", "Polygon", 0.65, 6.4, 290.0),
            ("PEPE", "Pepe", 0.000012, 5.1, 1200.0),
            ("LTC", "Litecoin", 78.5, 5.8, 330.0),
            ("UNI", "Uniswap", 7.2, 4.3, 210.0),
            ("KAS", "Kaspa", 0.15, 3.6, 95.0),
            ("ETC", "Ethereum Classic", 28.5, 4.1, 180.0),
            ("IMX", "Immutable", 1.85, 2.7, 85.0),
            ("ICP", "Internet Computer", 9.8, 4.5, 110.0),
            ("XLM", "Stellar", 0.095, 2.8, 75.0),
            ("FIL", "Filecoin", 4.35, 2.4, 95.0),
            ("STX", "Stacks", 1.65, 2.4, 115.0),
            ("LDO", "Lido DAO", 1.95, 1.7, 72.0),
            ("GRT", "The Graph", 0.22, 2.1, 65.0),
            ("FTM", "Fantom", 0.72, 2.0, 190.0),
            ("MKR", "Maker", 2540.0, 2.3, 85.0)
        ]
        
        var list: [CMCListingCoin] = []
        var updatedCachedPrices: [String: Double] = [:]
        var symbolsList: [String] = []

        // Add standard 30 base coins with randomized variations
        for c in baseCoins {
            let change = Double.random(in: -4.5...5.5)
            let coin = CMCListingCoin(
                symbol: c.0,
                name: c.1,
                price: c.2 * (1.0 + Double.random(in: -0.02...0.02)),
                change24h: change,
                marketCap: c.3,
                volume24h: c.4
            )
            list.append(coin)
            updatedCachedPrices[c.0] = coin.price
            symbolsList.append(c.0)
        }

        // Fill remaining 70 coins programmatically to reach 100
        let fillerNames = [
            "Aave", "Maker", "Synthetix", "Compound", "Curve", "dYdX", "1inch", "Loopring", "Enjin", "Decentraland",
            "Sandbox", "Axie Infinity", "Gala", "Flow", "Chiliz", "Theta", "Helium", "Arweave", "Filecoin", "Storj",
            "Siacoin", "Fetch.ai", "SingularityNET", "Ocean Protocol", "Render", "Akash Network", "Bittensor", "Livepeer", "Audius", "Basic Attention Token",
            "Brave", "Jasmy", "Status", "Gnosis", "Loopring Token", "Balancer", "SushiSwap", "PancakeSwap", "Raydium", "Orca",
            "Jupiter", "Wormhole", "Pyth Network", "Celestia", "Sui", "Aptos", "Arbitrum", "Optimism", "Starknet", "zkSync Token",
            "Manta Network", "Altlayer", "Dymension", "EigenLayer", "Renzo", "Ether.fi", "Pendle", "Ethena", "MakerDAO", "Aave v3",
            "Lido Staked ETH", "Rocket Pool", "Frax Share", "Convex Finance", "Yearn Finance", "Curve DAO", "Balancer Governance", "Loopring DAO", "Compound Governance", "Tornado Cash"
        ]

        for i in 1...70 {
            let name = i <= fillerNames.count ? fillerNames[i-1] : "Token \(i)"
            let sym = name.uppercased().replacingOccurrences(of: " ", with: "").prefix(4) + "\(i)"
            let symStr = String(sym)
            let mockPrice = Double.random(in: 0.05...45.0)
            let change = Double.random(in: -12.0...15.0)
            let cap = Double.random(in: 0.1...1.5)
            let vol = Double.random(in: 1.0...50.0)

            let coin = CMCListingCoin(
                symbol: symStr,
                name: name,
                price: mockPrice,
                change24h: change,
                marketCap: cap,
                volume24h: vol
            )
            list.append(coin)
            updatedCachedPrices[symStr] = mockPrice
            symbolsList.append(symStr)
        }

        self.cachedPrices = updatedCachedPrices
        self.availableSymbols = symbolsList
        return list
    }
}

public struct CMCListingCoin: Codable, Identifiable, Hashable {
    public var id: String { symbol }
    public let symbol: String
    public let name: String
    public let price: Double
    public let change24h: Double
    public let marketCap: Double
    public let volume24h: Double
}
