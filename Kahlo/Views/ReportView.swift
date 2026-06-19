import SwiftUI

struct ReportView: View {
    @ObservedObject var engine: TradingEngine
    @State private var reportDate = Date()

    private var coins: [CoinModel] { engine.coins }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignConstant.spacingLg) {
                headerSection
                marketSummary
                sentimentAnalysis
                topGainersSection
                topLosersSection
                volumeLeadersSection
                marketCapSection
                priceWatchSection
                marketHealthSection
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(GlassBackgroundView())
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("MARKET ANALYSIS REPORT")
                .font(.system(.title2, design: .rounded))
                .bold()

            Text(reportDate.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.gray)

            Text("\(coins.count) assets tracked")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(.top, 12)
    }

    // MARK: - Market Summary

    private var marketSummary: some View {
        VStack(alignment: .leading, spacing: DesignConstant.spacingSm) {
            SectionLabel(text: "MARKET SUMMARY")

            let totalCap = coins.reduce(0.0) { $0 + $1.marketCap }
            let totalVol = coins.reduce(0.0) { $0 + $1.volume24h }
            let avgChange = coins.isEmpty ? 0 : coins.reduce(0.0) { $0 + $1.change24h } / Double(coins.count)

            HStack(spacing: 0) {
                metricItem("Total Market Cap", "\(String(format: "%.1f", totalCap))B", .primary)
                metricItem("24h Volume", "\(String(format: "%.1f", totalVol))M", .primary)
                metricItem("Avg Change", String(format: "%+.2f%%", avgChange), avgChange >= 0 ? .positive : .negative)
            }

            Divider().background(Color.white.opacity(0.1))

            HStack(spacing: 0) {
                let gainers = coins.filter { $0.change24h > 0 }.count
                let losers = coins.filter { $0.change24h < 0 }.count
                let flat = coins.count - gainers - losers
                metricItem("Gainers", "\(gainers)", .positive)
                metricItem("Losers", "\(losers)", .negative)
                metricItem("Flat", "\(flat)", .gray)
            }

            Divider().background(Color.white.opacity(0.1))

            if let topGainer = coins.max(by: { $0.change24h < $1.change24h }) {
                HStack {
                    Text("Best Performer:")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.gray)
                    Text(topGainer.symbol)
                        .font(.monoSmall)
                        .foregroundColor(.positive)
                    Text(String(format: "%+.2f%%", topGainer.change24h))
                        .font(.monoSmall)
                        .foregroundColor(.positive)
                }
            }

            if let topLoser = coins.min(by: { $0.change24h < $1.change24h }) {
                HStack {
                    Text("Worst Performer:")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.gray)
                    Text(topLoser.symbol)
                        .font(.monoSmall)
                        .foregroundColor(.negative)
                    Text(String(format: "%+.2f%%", topLoser.change24h))
                        .font(.monoSmall)
                        .foregroundColor(.negative)
                }
            }
        }
        .padding()
        .glassPanel()
    }

    // MARK: - Sentiment Analysis

    private var sentimentAnalysis: some View {
        VStack(alignment: .leading, spacing: DesignConstant.spacingSm) {
            SectionLabel(text: "MARKET SENTIMENT")

            let gainers = coins.filter { $0.change24h > 0 }
            let losers = coins.filter { $0.change24h < 0 }
            let total = Double(max(coins.count, 1))
            let bullishPct = Double(gainers.count) / total * 100
            let bearishPct = Double(losers.count) / total * 100
            let avgGainer = gainers.isEmpty ? 0 : gainers.reduce(0.0) { $0 + $1.change24h } / Double(gainers.count)
            let avgLoser = losers.isEmpty ? 0 : losers.reduce(0.0) { $0 + $1.change24h } / Double(losers.count)

            VStack(spacing: 6) {
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(LinearGradient.positiveGradient)
                            .frame(width: geo.size.width * CGFloat(bullishPct / 100))
                        Rectangle()
                            .fill(LinearGradient.negativeGradient)
                            .frame(width: geo.size.width * CGFloat(bearishPct / 100))
                    }
                    .cornerRadius(4)
                }
                .frame(height: 8)

                HStack {
                    Text("\(String(format: "%.0f", bullishPct))% Bullish")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.positive)
                    Spacer()
                    Text("\(String(format: "%.0f", bearishPct))% Bearish")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.negative)
                }
            }

            Divider().background(Color.white.opacity(0.1))

            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("Avg Gainer").font(.system(size: 9, design: .monospaced)).foregroundColor(.gray)
                    Text(String(format: "%+.2f%%", avgGainer))
                        .font(.monoSmall)
                        .foregroundColor(.positive)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Text("Avg Loser").font(.system(size: 9, design: .monospaced)).foregroundColor(.gray)
                    Text(String(format: "%+.2f%%", avgLoser))
                        .font(.monoSmall)
                        .foregroundColor(.negative)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Text("Spread").font(.system(size: 9, design: .monospaced)).foregroundColor(.gray)
                    Text(String(format: "%.2f", avgGainer - avgLoser))
                        .font(.monoSmall)
                        .foregroundColor(.cyan)
                }
                .frame(maxWidth: .infinity)
            }

            let sentiment: String = {
                if bullishPct > 65 { return "Strongly Bullish — broad market participation with most assets in positive territory." }
                if bullishPct > 55 { return "Mildly Bullish — more gainers than losers, indicating positive momentum." }
                if bearishPct > 65 { return "Strongly Bearish — broad sell-off across the market." }
                if bearishPct > 55 { return "Mildly Bearish — more losers than gainers, caution advised." }
                return "Mixed — gains and losses are relatively balanced. Market is indecisive."
            }()

            Text(sentiment)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .glassPanel()
    }

    // MARK: - Top Gainers

    private var topGainersSection: some View {
        VStack(alignment: .leading, spacing: DesignConstant.spacingSm) {
            SectionLabel(text: "TOP GAINERS (24H)")

            let gainers = coins.filter { $0.change24h > 0 }.sorted { $0.change24h > $1.change24h }
            if gainers.isEmpty {
                Text("No gainers in this period")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                ForEach(Array(gainers.prefix(5).enumerated()), id: \.element.id) { rank, coin in
                    coinRow(rank: rank + 1, coin: coin, changeColor: .positive)
                }
            }
        }
        .padding()
        .glassPanel()
    }

    // MARK: - Top Losers

    private var topLosersSection: some View {
        VStack(alignment: .leading, spacing: DesignConstant.spacingSm) {
            SectionLabel(text: "TOP LOSERS (24H)")

            let losers = coins.filter { $0.change24h < 0 }.sorted { $0.change24h < $1.change24h }
            if losers.isEmpty {
                Text("No losers in this period")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                ForEach(Array(losers.prefix(5).enumerated()), id: \.element.id) { rank, coin in
                    coinRow(rank: rank + 1, coin: coin, changeColor: .negative)
                }
            }
        }
        .padding()
        .glassPanel()
    }

    // MARK: - Volume Leaders

    private var volumeLeadersSection: some View {
        VStack(alignment: .leading, spacing: DesignConstant.spacingSm) {
            SectionLabel(text: "VOLUME LEADERS (24H)")

            let byVolume = coins.sorted { $0.volume24h > $1.volume24h }
            let totalVol = coins.reduce(0.0) { $0 + $1.volume24h }

            ForEach(Array(byVolume.prefix(5).enumerated()), id: \.element.id) { rank, coin in
                HStack {
                    Text("#\(rank + 1)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.gray)
                        .frame(width: 20, alignment: .leading)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(coin.symbol).font(.monoSmall).foregroundColor(.primary)
                        Text(coin.name).font(.system(size: 8, design: .monospaced)).foregroundColor(.gray)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(String(format: "%.1f", coin.volume24h))M")
                            .font(.monoSmall)
                            .foregroundColor(.primary)
                        Text("\(String(format: "%.1f", (coin.volume24h / max(totalVol, 1)) * 100))% share")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }

                if rank < min(byVolume.prefix(5).count, 5) - 1 {
                    Divider().background(Color.white.opacity(0.05))
                }
            }
        }
        .padding()
        .glassPanel()
    }

    // MARK: - Market Cap Distribution

    private var marketCapSection: some View {
        VStack(alignment: .leading, spacing: DesignConstant.spacingSm) {
            SectionLabel(text: "MARKET CAP DISTRIBUTION")

            let totalCap = coins.reduce(0.0) { $0 + $1.marketCap }
            let byCap = coins.sorted { $0.marketCap > $1.marketCap }

            if let btc = byCap.first {
                HStack {
                    Text("BTC Dominance")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(String(format: "%.1f", (btc.marketCap / max(totalCap, 1)) * 100))%")
                        .font(.monoSmall)
                        .foregroundColor(.cyan)
                }
            }

            if byCap.count >= 2 {
                let top10Cap = byCap.prefix(10).reduce(0.0) { $0 + $1.marketCap }
                HStack {
                    Text("Top 10 Concentration")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(String(format: "%.1f", (top10Cap / max(totalCap, 1)) * 100))%")
                        .font(.monoSmall)
                        .foregroundColor(.caution)
                }
            }

            if byCap.count >= 3 {
                Divider().background(Color.white.opacity(0.1))

                ForEach(Array(byCap.prefix(3).enumerated()), id: \.element.id) { rank, coin in
                    HStack {
                        Text("#\(rank + 1)")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.gray)
                            .frame(width: 20, alignment: .leading)

                        Text(coin.symbol)
                            .font(.monoSmall)
                            .foregroundColor(.primary)

                        Spacer()

                        Text("\(String(format: "%.1f", coin.marketCap))B")
                            .font(.monoSmall)
                            .foregroundColor(.primary)

                        Text("\(String(format: "%.1f", (coin.marketCap / max(totalCap, 1)) * 100))%")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.gray)
                            .frame(width: 44, alignment: .trailing)
                    }

                    if rank < 2 {
                        Divider().background(Color.white.opacity(0.05))
                    }
                }
            }
        }
        .padding()
        .glassPanel()
    }

    // MARK: - Price Watch

    private var priceWatchSection: some View {
        VStack(alignment: .leading, spacing: DesignConstant.spacingSm) {
            SectionLabel(text: "PRICE WATCH")

            let sortedByPrice = coins.sorted { $0.price > $1.price }
            let highest = sortedByPrice.first
            let lowest = sortedByPrice.last

            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("Highest Price").font(.system(size: 9, design: .monospaced)).foregroundColor(.gray)
                    if let coin = highest {
                        Text(coin.symbol)
                            .font(.monoSmall)
                            .foregroundColor(.primary)
                        Text("$\(String(format: "%.2f", coin.price))")
                            .font(.monoSmall)
                            .foregroundColor(.positive)
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Text("Lowest Price").font(.system(size: 9, design: .monospaced)).foregroundColor(.gray)
                    if let coin = lowest {
                        Text(coin.symbol)
                            .font(.monoSmall)
                            .foregroundColor(.primary)
                        Text("$\(String(format: "%.4f", coin.price))")
                            .font(.monoSmall)
                            .foregroundColor(.negative)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            if coins.count >= 3 {
                Divider().background(Color.white.opacity(0.1))

                HStack(spacing: 0) {
                    metricItem("Mean Price", "$\(String(format: "%.2f", coins.reduce(0.0) { $0 + $1.price } / Double(coins.count)))", .primary)
                    metricItem("Median Price", "$\(String(format: "%.2f", sortedByPrice[sortedByPrice.count / 2].price))", .primary)
                    metricItem("Range", "$\(String(format: "%.2f", (highest?.price ?? 0) - (lowest?.price ?? 0)))", .cyan)
                }
            }
        }
        .padding()
        .glassPanel()
    }

    // MARK: - Market Health

    private var marketHealthSection: some View {
        VStack(alignment: .leading, spacing: DesignConstant.spacingSm) {
            SectionLabel(text: "MARKET HEALTH")

            let gainers = coins.filter { $0.change24h > 0 }
            let losers = coins.filter { $0.change24h < 0 }
            let bullishPct = Double(gainers.count) / Double(max(coins.count, 1)) * 100
            let avgChangeAll = coins.isEmpty ? 0 : coins.reduce(0.0) { $0 + $1.change24h } / Double(coins.count)
            let totalVol = coins.reduce(0.0) { $0 + $1.volume24h }
            let totalCap = coins.reduce(0.0) { $0 + $1.marketCap }
            let volToCapRatio = totalCap > 0 ? totalVol / totalCap : 0

            let healthScore = computeHealthScore(
                bullishPct: bullishPct,
                avgChange: avgChangeAll,
                volToCapRatio: volToCapRatio,
                totalAssets: coins.count
            )

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: CGFloat(healthScore / 100))
                        .stroke(healthColor(healthScore), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.75), value: healthScore)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Market Health Score")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.gray)
                    Text("\(String(format: "%.0f", healthScore))/100")
                        .font(.medNumber)
                        .foregroundColor(healthColor(healthScore))
                    Text(healthLabel(healthScore))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(healthColor(healthScore))
                }
            }

            Divider().background(Color.white.opacity(0.1))

            let summary = marketSummaryText(
                bullishPct: bullishPct,
                avgChange: avgChangeAll,
                gainersCount: gainers.count,
                losersCount: losers.count,
                totalVol: totalVol,
                volToCapRatio: volToCapRatio
            )
            Text(summary)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .glassPanel()
    }

    // MARK: - Helpers

    private func metricItem(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.system(size: 8, design: .monospaced)).foregroundColor(.gray)
            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    private func coinRow(rank: Int, coin: CoinModel, changeColor: Color) -> some View {
        HStack {
            Text("#\(rank)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.gray)
                .frame(width: 20, alignment: .leading)

            VStack(alignment: .leading, spacing: 1) {
                Text(coin.symbol).font(.monoSmall).foregroundColor(.primary)
                Text(coin.name).font(.system(size: 8, design: .monospaced)).foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("$\(String(format: "%.4f", coin.price))")
                    .font(.monoSmall)
                    .foregroundColor(.primary)
                Text(String(format: "%+.2f%%", coin.change24h))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(changeColor)
            }
        }
    }

    private func computeHealthScore(bullishPct: Double, avgChange: Double, volToCapRatio: Double, totalAssets: Int) -> Double {
        var score = 50.0
        score += (bullishPct - 50) * 0.6
        score += max(-15, min(15, avgChange * 3))
        if volToCapRatio > 0.05 { score += 10 }
        else if volToCapRatio > 0.02 { score += 5 }
        if totalAssets >= 20 { score += 15 }
        else if totalAssets >= 10 { score += 10 }
        else if totalAssets >= 5 { score += 5 }
        return max(0, min(100, score))
    }

    private func healthColor(_ score: Double) -> Color {
        if score >= 65 { return .positive }
        if score >= 40 { return .caution }
        return .negative
    }

    private func healthLabel(_ score: Double) -> String {
        if score >= 75 { return "Excellent" }
        if score >= 65 { return "Good" }
        if score >= 50 { return "Fair" }
        if score >= 40 { return "Cautious" }
        return "Elevated Risk"
    }

    private func marketSummaryText(bullishPct: Double, avgChange: Double, gainersCount: Int, losersCount: Int, totalVol: Double, volToCapRatio: Double) -> String {
        var parts: [String] = []

        if bullishPct > 60 {
            parts.append("The market is predominantly bullish with \(String(format: "%.0f", bullishPct))% of assets in positive territory.")
        } else if losersCount > gainersCount {
            let bearishPct = 100 - bullishPct
            parts.append("Bearish sentiment dominates with \(String(format: "%.0f", bearishPct))% of assets declining.")
        } else {
            parts.append("Market sentiment is mixed with \(gainersCount) gainers and \(losersCount) losers.")
        }

        let absAvg = abs(avgChange)
        if absAvg > 3 {
            parts.append("The average movement of \(String(format: "%+.2f%%", avgChange)) indicates significant \(avgChange > 0 ? "upward" : "downward") momentum across the board.")
        } else if absAvg > 1 {
            parts.append("Moderate price action with average change of \(String(format: "%+.2f%%", avgChange)).")
        } else {
            parts.append("Price action is relatively subdued with average change of \(String(format: "%+.2f%%", avgChange)).")
        }

        if volToCapRatio > 0.05 {
            parts.append("Trading volume is robust relative to market cap, suggesting strong participant engagement.")
        } else if volToCapRatio < 0.01 {
            parts.append("Volume is relatively low compared to market cap — liquidity conditions warrant attention.")
        }

        return parts.joined(separator: " ")
    }

    private var bearishPct: Double {
        let losers = coins.filter { $0.change24h < 0 }.count
        return Double(losers) / Double(max(coins.count, 1)) * 100
    }
}
