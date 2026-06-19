import SwiftUI

struct PortfolioView: View {
    @ObservedObject var engine: TradingEngine
    @State private var showAddFundsAlert: Bool = false
    @State private var addFundsAmountText: String = ""
    @State private var showRemoveFundsAlert: Bool = false
    @State private var removeFundsAmountText: String = ""
    @State private var selectedCoin: CoinModel? = nil
    
    private var netWorth: Double {
        var total = engine.portfolio.usd
        for (sym, qty) in engine.portfolio.holdings {
            let price = engine.priceForSymbol(sym)
            total += qty * (price > 0 ? price : 0.0)
        }
        return total
    }
    
    private var pnlUsd: Double {
        netWorth - engine.startingWallet
    }
    
    private var pnlPct: Double {
        engine.startingWallet > 0 ? (pnlUsd / engine.startingWallet) * 100.0 : 0.0
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignConstant.spacingLg) {
                HStack {
                    Text("PORTFOLIO")
                        .font(.system(.title2, design: .rounded))
                        .bold()
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.top, 10)
                
                // Net Worth Card
                VStack(spacing: 16) {
                    Text("Total Net Worth")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(engine.selectedCurrency.format(netWorth))
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: netWorth)
                    
                    HStack(spacing: 8) {
                        Image(systemName: pnlUsd >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text("\(String(format: "%+.2f", pnlPct))%")
                        let pnlFormatted = engine.selectedCurrency.format(abs(pnlUsd))
                        let pnlPrefix = pnlUsd >= 0 ? "+" : "-"
                        Text("(\(pnlPrefix)\(pnlFormatted))")
                    }
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(pnlUsd >= 0 ? .green : .red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(pnlUsd >= 0 ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .cornerRadius(20)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .glassPanel()
                
                // USD Balance Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.green)
                        Text("\(engine.selectedCurrency.rawValue) Cash Balance")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        HStack(spacing: 12) {
                            Button(action: {
                                showAddFundsAlert = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundColor(.green)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            Button(action: {
                                showRemoveFundsAlert = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "minus.circle.fill")
                                    Text("Remove")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    Text(engine.selectedCurrency.format(engine.portfolio.usd))
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassPanel()
                
                // Asset Holdings Section
                VStack(alignment: .leading, spacing: DesignConstant.spacingMd) {
                    Text("ASSET HOLDINGS")
                        .font(.system(.caption, design: .monospaced))
                        .bold()
                        .foregroundColor(.gray)
                    
                    let nonZeroHoldings = engine.availableSymbols.filter { (engine.portfolio.holdings[$0] ?? 0.0) > 0 }
                    
                    if nonZeroHoldings.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "tray.empty")
                                    .font(.system(size: 24))
                                    .foregroundColor(.gray.opacity(0.6))
                                Text("No crypto holdings yet")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, DesignConstant.spacingSm)
                            Spacer()
                        }
                    } else {
                        VStack(spacing: 12) {
                            ForEach(nonZeroHoldings, id: \.self) { sym in
                                let qty = engine.portfolio.holdings[sym] ?? 0.0
                                let price = engine.priceForSymbol(sym)
                                let usdValue = qty * price
                                
                                Button(action: {
                                    HapticManager.light()
                                    if let coin = engine.coins.first(where: { $0.symbol == sym }) {
                                        selectedCoin = coin
                                    } else {
                                        selectedCoin = CoinModel(
                                            symbol: sym,
                                            name: sym,
                                            price: price,
                                            change24h: 0.0,
                                            marketCap: 0.0,
                                            volume24h: 0.0,
                                            sparkline: [price]
                                        )
                                    }
                                }) {
                                    HStack {
                                        HStack(spacing: 10) {
                                            Circle()
                                                .fill(Color.orange.opacity(0.15))
                                                .frame(width: 32, height: 32)
                                                .overlay(
                                                    Text(sym.prefix(1))
                                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                                        .foregroundColor(.orange)
                                                )
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(sym)
                                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                                    .foregroundColor(.primary)
                                                Text("\(String(format: "%.6f", qty)) \(sym)")
                                                    .font(.system(size: 12, design: .monospaced))
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(engine.selectedCurrency.format(usdValue))
                                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                                .foregroundColor(.primary)
                                            Text(engine.selectedCurrency.format(price, decimalPlaces: price >= 1.0 ? 2 : 4))
                                                .font(.system(size: 11, design: .monospaced))
                                                .foregroundColor(.gray.opacity(0.8))
                                        }
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(ScaleButtonStyle())
                                .padding(.vertical, 4)
                                
                                if sym != nonZeroHoldings.last {
                                    Divider().background(Color.white.opacity(0.06))
                                }
                            }
                        }
                    }
                }
                .padding()
                .glassPanel()
                
                // Trade Statistics
                VStack(alignment: .leading, spacing: DesignConstant.spacingMd) {
                    Text("PERFORMANCE STATS")
                        .font(.system(.caption, design: .monospaced))
                        .bold()
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 0) {
                        StatBox(title: "Total Trades", value: "\(engine.totalTrades)", color: .blue)
                        StatBox(title: "Total Buys", value: "\(engine.totalBuys)", color: .green)
                        StatBox(title: "Total Sells", value: "\(engine.totalSells)", color: .red)
                        StatBox(title: "Stops Hit", value: "\(engine.stopLossesHit)", color: .orange)
                    }
                    .glassPanel()
                    
                    if let avgPrice = engine.avgBuyPrice, (engine.portfolio.holdings[engine.symbol] ?? 0.0) > 0 {
                        HStack {
                            Text("Avg. Entry Price")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            Text(engine.selectedCurrency.format(avgPrice))
                                .font(.system(.body, design: .monospaced))
                                .bold()
                                .foregroundColor(.amber)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
                .glassPanel()
            }
            .padding(.horizontal)
        }
        .background(GlassBackgroundView())
        .alert("Add Funds", isPresented: $showAddFundsAlert) {
            TextField("Amount (\(engine.selectedCurrency.rawValue))", text: $addFundsAmountText)
                .keyboardType(.decimalPad)
            Button("Add") {
                if let amount = Double(addFundsAmountText), amount > 0 {
                    engine.addFunds(engine.selectedCurrency.convertToUSD(amount))
                }
                addFundsAmountText = ""
            }
            Button("Cancel", role: .cancel) {
                addFundsAmountText = ""
            }
        } message: {
            Text("Enter the amount of \(engine.selectedCurrency.rawValue) you want to add to your trading balance.")
        }
        .alert("Remove Funds", isPresented: $showRemoveFundsAlert) {
            TextField("Amount (\(engine.selectedCurrency.rawValue))", text: $removeFundsAmountText)
                .keyboardType(.decimalPad)
            Button("Remove", role: .destructive) {
                if let amount = Double(removeFundsAmountText), amount > 0 {
                    engine.removeFunds(engine.selectedCurrency.convertToUSD(amount))
                }
                removeFundsAmountText = ""
            }
            Button("Cancel", role: .cancel) {
                removeFundsAmountText = ""
            }
        } message: {
            Text("Enter the amount of \(engine.selectedCurrency.rawValue) you want to remove from your trading balance.")
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
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignConstant.spacingMd)
    }
}

extension Color {
    static let amber = Color(red: 251/255, green: 191/255, blue: 36/255)
}
