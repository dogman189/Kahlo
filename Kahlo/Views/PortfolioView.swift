import SwiftUI

struct PortfolioView: View {
    @ObservedObject var engine: TradingEngine
    
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
            VStack(spacing: 24) {
                HStack {
                    Text("PORTFOLIO")
                        .font(.system(.title2, design: .rounded))
                        .bold()
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.top, 10)
                
                VStack(spacing: 16) {
                    Text("Total Net Worth")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("$\(String(format: "%.2f", netWorth))")
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: pnlUsd >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text("\(String(format: "%+.2f", pnlPct))%")
                        Text("(\(String(format: "%+.2f", pnlUsd)))")
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
                
                // Balances
                HStack(spacing: 16) {
                    // USD
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(.green)
                            Text("USD Balance")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Text("$\(String(format: "%.2f", engine.portfolio.usd))")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassPanel()
                    
                    // Crypto
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "bitcoinsign.circle.fill")
                                .foregroundColor(.orange)
                            Text("\(engine.symbol) Holdings")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        let holdings = engine.portfolio.holdings[engine.symbol] ?? 0.0
                        Text("\(String(format: "%.6f", holdings))")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassPanel()
                }
                
                // Trade Statistics
                VStack(alignment: .leading, spacing: 16) {
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
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
                    
                    if let avgPrice = engine.avgBuyPrice, (engine.portfolio.holdings[engine.symbol] ?? 0.0) > 0 {
                        HStack {
                            Text("Avg. Entry Price")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("$\(String(format: "%.2f", avgPrice))")
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
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: netWorth)
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: engine.totalTrades)
        }
        .background(GlassBackgroundView())
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
        .padding(.vertical, 16)
    }
}

extension Color {
    static let amber = Color(red: 251/255, green: 191/255, blue: 36/255)
}
