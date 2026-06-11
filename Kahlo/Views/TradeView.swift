import SwiftUI

struct TradeView: View {
    @ObservedObject var engine: TradingEngine
    @State private var selectedSide: TradeSide = .buy
    @State private var selectedSymbol: String = "BTC"
    @State private var amountText: String = ""
    @State private var showConfirmation: Bool = false
    @State private var confirmationMessage: String = ""
    @State private var confirmationSuccess: Bool = true
    @State private var usePercentage: Bool = false
    @State private var selectedPercentage: Double = 0.0
    @State private var recentManualTrades: [ManualTradeRecord] = []
    @State private var timer: Timer?

    private let availableSymbols = ["BTC", "ETH", "SOL", "ADA", "DOT", "LINK", "DOGE"]

    enum TradeSide: String, CaseIterable {
        case buy = "BUY"
        case sell = "SELL"

        var color: Color {
            switch self {
            case .buy: return .green
            case .sell: return .red
            }
        }

        var icon: String {
            switch self {
            case .buy: return "arrow.down.circle.fill"
            case .sell: return "arrow.up.circle.fill"
            }
        }
    }

    struct ManualTradeRecord: Identifiable {
        let id = UUID()
        let side: String
        let symbol: String
        let quantity: Double
        let price: Double
        let total: Double
        let timestamp: Date
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                // MARK: - Header
                headerSection

                // MARK: - Side Selector (BUY / SELL)
                sideSelector

                // MARK: - Symbol Picker
                symbolPicker

                // MARK: - Price Display
                priceDisplay

                // MARK: - Amount Input
                amountSection

                // MARK: - Quick Percentage Buttons
                quickPercentageButtons

                // MARK: - Order Summary
                orderSummary

                // MARK: - Execute Button
                executeButton

                // MARK: - Recent Manual Trades
                if !recentManualTrades.isEmpty {
                    recentTradesSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(GlassBackgroundView())
        .overlay(confirmationOverlay)
        .onAppear {
            selectedSymbol = engine.symbol
            fetchMarketPrices()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    private func fetchMarketPrices() {
        if !engine.apiKey.isEmpty {
            Task {
                _ = await engine.fetchMultiplePrices(symbols: availableSymbols)
            }
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 61.0, repeats: true) { _ in
            fetchMarketPrices()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("MANUAL TRADE")
                    .font(.system(.title2, design: .rounded))
                    .bold()
                    .foregroundColor(.primary)
                Text("Execute orders at market price")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            Spacer()
            // Balance pill
            VStack(alignment: .trailing, spacing: 2) {
                Text("AVAILABLE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                Text("$\(String(format: "%.2f", engine.portfolio.usd))")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.cyan.opacity(0.08))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.cyan.opacity(0.15), lineWidth: 1)
            )
        }
        .padding(.top, 10)
    }

    // MARK: - Side Selector

    private var sideSelector: some View {
        HStack(spacing: 0) {
            ForEach(TradeSide.allCases, id: \.self) { side in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedSide = side
                        amountText = ""
                        selectedPercentage = 0
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: side.icon)
                            .font(.system(size: 14, weight: .bold))
                        Text(side.rawValue)
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(selectedSide == side ? .white : side.color.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        selectedSide == side
                            ? side.color.opacity(0.85)
                            : Color.clear
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.03))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Symbol Picker

    private var symbolPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ASSET")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(availableSymbols, id: \.self) { sym in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedSymbol = sym
                                amountText = ""
                                selectedPercentage = 0
                            }
                        }) {
                            VStack(spacing: 4) {
                                Text(sym)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(selectedSymbol == sym ? .white : .gray)
                                let symPrice = engine.priceForSymbol(sym)
                                Text(symPrice >= 1.0 ? "$\(String(format: "%.2f", symPrice))" : "$\(String(format: "%.4f", symPrice))")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(selectedSymbol == sym ? .white.opacity(0.8) : .gray.opacity(0.6))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                selectedSymbol == sym
                                    ? selectedSide.color.opacity(0.7)
                                    : Color.white.opacity(0.03)
                            )
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        selectedSymbol == sym
                                            ? selectedSide.color.opacity(0.5)
                                            : Color.white.opacity(0.05),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }
        }
        .padding(14)
        .glassPanel()
    }

    // MARK: - Price Display

    private var priceDisplay: some View {
        let currentPrice = engine.priceForSymbol(selectedSymbol)
        let isActiveSymbol = selectedSymbol == engine.symbol && engine.price > 0

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("MARKET PRICE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                Text(currentPrice >= 1.0 ? "$\(String(format: "%.2f", currentPrice))" : "$\(String(format: "%.6f", currentPrice))")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            }
            Spacer()
            if isActiveSymbol {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
            } else {
                Text("INDICATIVE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding(14)
        .glassPanel()
    }

    // MARK: - Amount Section

    private var amountSection: some View {
        let holdings = engine.portfolio.holdings[selectedSymbol] ?? 0.0

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(selectedSide == .buy ? "AMOUNT (USD)" : "QUANTITY (\(selectedSymbol))")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                if selectedSide == .sell {
                    Text("Holdings: \(String(format: "%.6f", holdings))")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.7))
                }
            }

            HStack(spacing: 12) {
                // Currency / Coin icon
                ZStack {
                    Circle()
                        .fill(selectedSide.color.opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: selectedSide == .buy ? "dollarsign" : "bitcoinsign")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(selectedSide.color)
                }

                TextField(selectedSide == .buy ? "0.00" : "0.000000", text: $amountText)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                    .keyboardType(.decimalPad)
                    .onChange(of: amountText) { _ in
                        selectedPercentage = 0
                    }

                if !amountText.isEmpty {
                    Button(action: {
                        amountText = ""
                        selectedPercentage = 0
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 18))
                    }
                }
            }
            .padding(14)
            .background(Color.black.opacity(0.2))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedSide.color.opacity(amountText.isEmpty ? 0.1 : 0.35), lineWidth: 1)
            )

            // Max available hint
            if selectedSide == .buy {
                Text("Max: $\(String(format: "%.2f", engine.portfolio.usd))")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.5))
            } else {
                Text("Max: \(String(format: "%.6f", holdings)) \(selectedSymbol)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding(14)
        .glassPanel()
    }

    // MARK: - Quick Percentage Buttons

    private var quickPercentageButtons: some View {
        let percentages: [Double] = [25, 50, 75, 100]

        return HStack(spacing: 8) {
            ForEach(percentages, id: \.self) { pct in
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        selectedPercentage = pct
                        applyPercentage(pct)
                    }
                }) {
                    Text("\(Int(pct))%")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(selectedPercentage == pct ? .white : selectedSide.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedPercentage == pct
                                ? selectedSide.color.opacity(0.75)
                                : selectedSide.color.opacity(0.08)
                        )
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedSide.color.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    // MARK: - Order Summary

    private var orderSummary: some View {
        let currentPrice = engine.priceForSymbol(selectedSymbol)
        let parsedAmount = Double(amountText) ?? 0.0

        let estimatedQty: Double
        let estimatedTotal: Double

        if selectedSide == .buy {
            estimatedQty = currentPrice > 0 ? parsedAmount / currentPrice : 0.0
            estimatedTotal = parsedAmount
        } else {
            estimatedQty = parsedAmount
            estimatedTotal = parsedAmount * currentPrice
        }

        return VStack(alignment: .leading, spacing: 12) {
            Text("ORDER SUMMARY")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)

            Divider().background(Color.white.opacity(0.06))

            HStack {
                Text("Side")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Spacer()
                Text(selectedSide.rawValue)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(selectedSide.color)
            }

            HStack {
                Text("Asset")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Spacer()
                Text(selectedSymbol)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            }

            HStack {
                Text("Quantity")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Spacer()
                Text("\(String(format: "%.6f", estimatedQty)) \(selectedSymbol)")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary)
            }

            HStack {
                Text("Total")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Spacer()
                Text("$\(String(format: "%.2f", estimatedTotal))")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
            }
        }
        .padding(16)
        .glassPanel()
    }

    // MARK: - Execute Button

    private var executeButton: some View {
        let parsedAmount = Double(amountText) ?? 0.0
        let isValid: Bool = {
            if selectedSide == .buy {
                return parsedAmount > 0 && parsedAmount <= engine.portfolio.usd
            } else {
                let holdings = engine.portfolio.holdings[selectedSymbol] ?? 0.0
                return parsedAmount > 0 && parsedAmount <= holdings
            }
        }()

        return Button(action: executeTrade) {
            HStack(spacing: 8) {
                Image(systemName: selectedSide == .buy ? "cart.fill.badge.plus" : "cart.fill.badge.minus")
                    .font(.system(size: 16, weight: .bold))
                Text("\(selectedSide.rawValue) \(selectedSymbol)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
            }
            .foregroundColor(isValid ? .white : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isValid
                    ? selectedSide.color.opacity(0.9)
                    : Color.white.opacity(0.05)
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isValid ? selectedSide.color.opacity(0.6) : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isValid)
    }

    // MARK: - Recent Trades

    private var recentTradesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT MANUAL TRADES")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)

            ForEach(recentManualTrades.reversed()) { trade in
                HStack(spacing: 10) {
                    // Side indicator
                    Circle()
                        .fill(trade.side == "BUY" ? Color.green : Color.red)
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(trade.side) \(trade.symbol)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                        Text("\(String(format: "%.6f", trade.quantity)) @ $\(String(format: "%.2f", trade.price))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(String(format: "%.2f", trade.total))")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(.primary)
                        Text(timeAgo(trade.timestamp))
                            .font(.system(size: 10))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.015))
                .cornerRadius(10)
            }
        }
        .padding(14)
        .glassPanel()
    }

    // MARK: - Confirmation Overlay

    private var confirmationOverlay: some View {
        Group {
            if showConfirmation {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showConfirmation = false
                            }
                        }

                    VStack(spacing: 16) {
                        Image(systemName: confirmationSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(confirmationSuccess ? .green : .orange)

                        Text(confirmationSuccess ? "Order Filled" : "Order Failed")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text(confirmationMessage)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)

                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showConfirmation = false
                            }
                        }) {
                            Text("DONE")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.cyan)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(24)
                    .frame(maxWidth: 320)
                    .background(.ultraThinMaterial)
                    .background(Color(red: 17/255, green: 24/255, blue: 39/255).opacity(0.85))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 30)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: showConfirmation)
            }
        }
    }

    // MARK: - Actions

    private func applyPercentage(_ pct: Double) {
        if selectedSide == .buy {
            let maxUsd = engine.portfolio.usd
            let amount = maxUsd * (pct / 100.0)
            amountText = String(format: "%.2f", amount)
        } else {
            let holdings = engine.portfolio.holdings[selectedSymbol] ?? 0.0
            let amount = holdings * (pct / 100.0)
            amountText = String(format: "%.6f", amount)
        }
    }

    private func executeTrade() {
        let parsedAmount = Double(amountText) ?? 0.0
        guard parsedAmount > 0 else { return }

        let result: String
        let currentPrice = engine.priceForSymbol(selectedSymbol)

        if selectedSide == .buy {
            result = engine.manualBuy(symbol: selectedSymbol, usdAmount: parsedAmount)
            let qty = currentPrice > 0 ? parsedAmount / currentPrice : 0.0
            recentManualTrades.append(ManualTradeRecord(
                side: "BUY", symbol: selectedSymbol,
                quantity: qty, price: currentPrice,
                total: parsedAmount, timestamp: Date()
            ))
        } else {
            let proceeds = parsedAmount * currentPrice
            result = engine.manualSell(symbol: selectedSymbol, quantity: parsedAmount)
            recentManualTrades.append(ManualTradeRecord(
                side: "SELL", symbol: selectedSymbol,
                quantity: parsedAmount, price: currentPrice,
                total: proceeds, timestamp: Date()
            ))
        }

        // Keep only last 10 trades
        if recentManualTrades.count > 10 {
            recentManualTrades.removeFirst()
        }

        confirmationMessage = result
        confirmationSuccess = !result.contains("failed")

        amountText = ""
        selectedPercentage = 0

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            showConfirmation = true
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        return "\(seconds / 3600)h ago"
    }
}
