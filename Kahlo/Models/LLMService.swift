import Foundation
import Combine
#if canImport(CoreML)
import CoreML
#endif

// MARK: - Model Config

public struct LLMModelConfig: Codable {
    public var temperature: Double = 0.3
    public var maxTokens: Int = 256

    public static let `default` = LLMModelConfig()
    public init() {}
}

// MARK: - Analysis Result

public struct MarketAnalysis: Codable {
    public var summary: String
    public var signal: TradeSignal
    public var confidence: Double
    public var reasoning: String
    public var risks: [String]

    public init(summary: String, signal: TradeSignal, confidence: Double, reasoning: String, risks: [String]) {
        self.summary = summary
        self.signal = signal
        self.confidence = confidence
        self.reasoning = reasoning
        self.risks = risks
    }
}

public enum TradeSignal: String, Codable, CaseIterable {
    case bullish = "BULLISH"
    case bearish = "BEARISH"
    case neutral = "NEUTRAL"
}

// MARK: - Protocol

public protocol LLMInferenceEngine {
    func generate(prompt: String, config: LLMModelConfig) async throws -> String
}

// MARK: - Tiny Swift Engine (built-in, no server needed)

actor TinySwiftEngine: LLMInferenceEngine {
    func generate(prompt: String, config: LLMModelConfig) async throws -> String {
        if prompt.hasPrefix("Market Data for") {
            let data = parseMarketData(from: prompt)
            return buildAnalysis(data: data)
        } else {
            return chatResponse(for: prompt)
        }
    }

    private struct MarketData {
        var symbol: String
        var price: Double
        var rsi: Double
        var bbPosition: String
        var momentum: Double
        var prediction: Double
        var accuracy: Double
        var portfolioUSD: Double
        var pnl: Double
    }

    private func parseMarketData(from prompt: String) -> MarketData {
        let lines = prompt.components(separatedBy: "\n")
        var symbol = "BTC"
        var price: Double = 0
        var rsi: Double = 50
        var bbPosition = "within bands"
        var momentum: Double = 0
        var prediction: Double = 0
        var accuracy: Double = 50
        var portfolioUSD: Double = 10000
        var pnl: Double = 0

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("- Current Price:") {
                let val = trimmed.replacingOccurrences(of: #"[^0-9.]"#, with: "", options: .regularExpression)
                price = Double(val) ?? 0
            } else if trimmed.hasPrefix("- RSI (14):") {
                let parts = trimmed.components(separatedBy: ":")
                if parts.count >= 2 {
                    let rsiStr = parts[1].trimmingCharacters(in: .whitespaces).components(separatedBy: " ").first ?? ""
                    rsi = Double(rsiStr) ?? 50
                }
            } else if trimmed.hasPrefix("- Bollinger Band Position:") {
                bbPosition = trimmed.replacingOccurrences(of: "- Bollinger Band Position:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("- 5-Tick Momentum:") {
                let val = trimmed.replacingOccurrences(of: #"[^0-9.\-]"#, with: "", options: .regularExpression)
                momentum = Double(val) ?? 0
            } else if trimmed.hasPrefix("- NN Prediction:") {
                let parts = trimmed.components(separatedBy: ":")
                if parts.count >= 2 {
                    let predStr = parts[1].trimmingCharacters(in: .whitespaces).components(separatedBy: " ").first ?? ""
                    prediction = Double(predStr) ?? 0
                }
            } else if trimmed.hasPrefix("- NN Accuracy:") {
                let val = trimmed.replacingOccurrences(of: #"[^0-9.]"#, with: "", options: .regularExpression)
                accuracy = Double(val) ?? 50
            } else if trimmed.hasPrefix("- USD Balance:") {
                let val = trimmed.replacingOccurrences(of: #"[^0-9.]"#, with: "", options: .regularExpression)
                portfolioUSD = Double(val) ?? 10000
            } else if trimmed.hasPrefix("- Unrealized P&L:") {
                let val = trimmed.replacingOccurrences(of: #"[^0-9.\-]"#, with: "", options: .regularExpression)
                pnl = Double(val) ?? 0
            } else if trimmed.hasPrefix("Market Data for") {
                let s = trimmed.replacingOccurrences(of: "Market Data for", with: "").trimmingCharacters(in: .whitespaces)
                symbol = s.replacingOccurrences(of: ":", with: "")
            }
        }

        return MarketData(
            symbol: symbol, price: price, rsi: rsi, bbPosition: bbPosition,
            momentum: momentum, prediction: prediction, accuracy: accuracy,
            portfolioUSD: portfolioUSD, pnl: pnl
        )
    }

    private let summaries = [
        "The market is showing signs of momentum that align with the broader trend.",
        "Current market conditions suggest a period of consolidation before the next move.",
        "Technical indicators present a mixed picture, warranting a cautious approach.",
        "The asset is reacting to recent volatility with increased buyer interest.",
        "Market structure remains intact with healthy pullback and support levels holding.",
    ]

    private let directionalComments: [(String, String, String)] = [
        ("The neural network prediction of %@ strongly aligns with the RSI reading of %.0f.",
         "Both technical and AI indicators confirm the current trend direction.",
         "The %@ reading of %.0f supports the current market structure."),
        ("RSI at %.0f suggests the asset is approaching a key decision point.",
         "Volume patterns and momentum indicators are converging.",
         "The %.0f%% accuracy neural net provides additional conviction for this outlook."),
    ]

    private func buildAnalysis(data: MarketData) -> String {
        let signal: TradeSignal
        let rawConfidence: Double

        let rsiWeight = (data.rsi - 50) / 50
        let predWeight = max(-1, min(1, data.prediction * 5))
        let composite = (rsiWeight * 0.4 + predWeight * 0.4 + (data.momentum / 5) * 0.2)

        if composite > 0.15 {
            signal = .bullish
            rawConfidence = min(0.95, 0.5 + abs(composite) * 0.5)
        } else if composite < -0.15 {
            signal = .bearish
            rawConfidence = min(0.95, 0.5 + abs(composite) * 0.5)
        } else {
            signal = .neutral
            rawConfidence = 0.3 + abs(composite) * 0.4
        }

        let confidence = (rawConfidence * 0.6 + (data.accuracy / 100) * 0.4)

        let summaryLine: String = {
            if data.momentum > 3 {
                return "Strong upward momentum detected with RSI at \(String(format: "%.0f", data.rsi))."
            } else if data.momentum < -3 {
                return "Downward pressure intensifying — \(data.symbol) testing key support levels."
            } else if data.rsi > 70 {
                return "Overbought conditions at RSI \(String(format: "%.0f", data.rsi)) — caution warranted."
            } else if data.rsi < 30 {
                return "Oversold territory at RSI \(String(format: "%.0f", data.rsi)) — potential reversal setup."
            } else {
                return summaries.randomElement() ?? summaries[0]
            }
        }()

        let reasoningLines: [String] = {
            var lines: [String] = []
            lines.append("• Price: $\(String(format: "%.2f", data.price)) | RSI: \(String(format: "%.0f", data.rsi)) | Position: \(data.bbPosition)")

            if abs(data.prediction) > 0.05 {
                lines.append("• Neural net predicts \(data.prediction > 0 ? "upward" : "downward") movement (\(String(format: "%+.4f", data.prediction))) with \(String(format: "%.0f%%", data.accuracy)) historical accuracy.")
            }

            if abs(data.momentum) > 2 {
                lines.append("• Short-term momentum is \(data.momentum > 0 ? "positive" : "negative") at \(String(format: "%+.2f%%", data.momentum)).")
            }

            let portStr = data.portfolioUSD > 0 ? "$\(String(format: "%.0f", data.portfolioUSD))" : "minimal"
            lines.append("• Portfolio exposure: \(portStr) USD | Unrealized P&L: \(String(format: "%+.2f%%", data.pnl))")

            return lines
        }()

        let risksList: [String] = {
            var risks: [String] = []
            if data.rsi > 65 { risks.append("Overbought RSI risk — potential mean reversion") }
            if data.rsi < 35 { risks.append("Oversold conditions — trend may persist before reversal") }
            if abs(data.momentum) > 5 { risks.append("High momentum — increased slippage and volatility risk") }
            if data.accuracy < 40 { risks.append("Reduced model confidence — NN accuracy below 40%") }
            if risks.isEmpty {
                risks.append("Normal market conditions — monitor for trend shifts")
            }
            return risks
        }()

        let reasoning = reasoningLines.joined(separator: "\n")

        return """
            \(summaryLine)

            SIGNAL: \(signal.rawValue) (Confidence: \(String(format: "%.0f%%", confidence * 100)))

            ANALYSIS:
            \(reasoning)

            KEY RISKS:
            \(risksList.map { "• \($0)" }.joined(separator: "\n"))
            """
    }

    // MARK: - Chat

    private func chatResponse(for prompt: String) -> String {
        let userMsg: String
        var symbol = "BTC"
        var price: Double?
        var rsi: Double?
        var prediction: Double?
        var accuracy: Double?
        var portfolioUSD: Double?
        var bbPos: String?

        if let range = prompt.range(of: "[USER MESSAGE]") {
            userMsg = String(prompt[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            let ctx = String(prompt[..<range.lowerBound])
            for line in ctx.components(separatedBy: "\n") {
                let t = line.trimmingCharacters(in: .whitespaces)
                if t.hasPrefix("Symbol:") { symbol = String(t.dropFirst(7)).trimmingCharacters(in: .whitespaces) }
                if t.hasPrefix("Price:") {
                    let v = t.replacingOccurrences(of: #"[^0-9.]"#, with: "", options: .regularExpression)
                    price = Double(v)
                }
                if t.hasPrefix("RSI:") {
                    let v = t.replacingOccurrences(of: #"[^0-9.]"#, with: "", options: .regularExpression)
                    rsi = Double(v)
                }
                if t.hasPrefix("Prediction:") {
                    let v = t.replacingOccurrences(of: #"[^0-9.\-]"#, with: "", options: .regularExpression)
                    prediction = Double(v)
                }
                if t.hasPrefix("Accuracy:") {
                    let v = t.replacingOccurrences(of: #"[^0-9.]"#, with: "", options: .regularExpression)
                    accuracy = Double(v)
                }
                if t.hasPrefix("Portfolio USD:") {
                    let v = t.replacingOccurrences(of: #"[^0-9.]"#, with: "", options: .regularExpression)
                    portfolioUSD = Double(v)
                }
                if t.hasPrefix("BB Position:") {
                    bbPos = String(t.dropFirst(13)).trimmingCharacters(in: .whitespaces)
                }
            }
        } else {
            userMsg = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let lower = userMsg.lowercased()
        let greet = #"^(hello|hi\b|hey|howdy|sup|good morning|good evening|yo)\b"#
        let thanks = #"^(thanks|thank you|appreciate it|thx)\b"#

        // Greetings
        if lower.range(of: greet, options: .regularExpression) != nil {
            let greetings = [
                "Hey there! I'm Kahlo AI. I can help you analyze the crypto market, check technical indicators, or explain trading concepts. What's on your mind?",
                "Hello! Ready to dive into the markets? Ask me about prices, indicators, or strategies.",
                "Hi! I'm your on-device crypto analyst. No data leaves your device. How can I help?",
            ]
            return greetings.randomElement()!
        }

        // Thanks
        if lower.range(of: thanks, options: .regularExpression) != nil {
            return "You're welcome! Let me know if you have any other questions about the markets."
        }

        // Price queries
        if lower.contains("price") || lower.contains("how much") || lower.contains("worth") || lower.contains("value") || lower.contains("trading at") {
            if let p = price {
                let trends = ["is currently trading at", "stands at", "is valued at"]
                return "\(symbol) \(trends.randomElement()!) **$\(String(format: "%.2f", p))**."
            }
            return "I don't have real-time price data for that asset right now. You can check the Markets tab for current prices, or enable the trading engine to track a specific symbol."
        }

        // RSI queries
        if lower.contains("rsi") || lower.contains("relative strength") {
            if let r = rsi {
                let status: String
                if r > 70 { status = "overbought (above 70) — this could signal a potential pullback or trend reversal." }
                else if r < 30 { status = "oversold (below 30) — this could indicate a potential bounce or reversal." }
                else { status = "neutral territory between 30 and 70 — no extreme conditions detected." }
                return "The current RSI(14) for \(symbol) is **\(String(format: "%.1f", r))**, which is \(status)"
            }
            return "RSI data isn't available right now. Make sure the trading engine is running in the Trade tab to compute indicators."
        }

        // Bollinger Band queries
        if lower.contains("bollinger") || lower.contains("bands") || lower.contains("bb") {
            if let pos = bbPos {
                return "\(symbol) is currently positioned **\(pos)**. Bollinger Bands measure volatility — prices touching the upper band suggest strength, while the lower band may indicate oversold conditions."
            }
            return "Bollinger Band data isn't available right now. Start the trading engine to compute real-time bands."
        }

        // Prediction / forecast queries
        if lower.contains("predict") || lower.contains("forecast") || lower.contains("neural") || lower.contains("nn") || lower.contains("outlook") {
            if let pred = prediction, let acc = accuracy {
                let direction = pred > 0.05 ? "upward" : (pred < -0.05 ? "downward" : "neutral (no strong direction)")
                let dirEmoji = pred > 0.05 ? "📈" : (pred < -0.05 ? "📉" : "➡️")
                return "The neural network forecast for \(symbol) is **\(String(format: "%+.4f", pred))** (\(direction)) \(dirEmoji)\n\nThis prediction has a historical accuracy of **\(String(format: "%.0f%%", acc))**. Remember — past performance doesn't guarantee future results."
            }
            return "I don't have a neural network prediction available right now. The AI Brain tab shows the latest forecast once the engine is running."
        }

        // Market analysis
        if lower.contains("analyze") || lower.contains("analysis") || lower.contains("market") || lower.contains("condition") {
            if let p = price, let r = rsi {
                var parts: [String] = []
                parts.append("Here's a quick snapshot of **\(symbol)**:")
                parts.append("• Price: **$\(String(format: "%.2f", p))**")
                parts.append("• RSI(14): **\(String(format: "%.1f", r))** \(r > 70 ? "(overbought)" : r < 30 ? "(oversold)" : "(neutral)")")
                if let pred = prediction {
                    parts.append("• NN Forecast: **\(String(format: "%+.4f", pred))**")
                }
                if let pos = bbPos {
                    parts.append("• Bollinger Position: **\(pos)**")
                }
                parts.append("")
                parts.append("For a deeper AI-powered analysis, check the **AI Brain** tab with on-device LLM analysis enabled in Settings.")
                return parts.joined(separator: "\n")
            }
            return "I need live market data to provide analysis. Start the trading engine in the Trade tab first, then ask me again!"
        }

        // Portfolio queries
        if lower.contains("portfolio") || lower.contains("holdings") || lower.contains("balance") || (lower.contains("my ") && (lower.contains("money") || lower.contains("usd") || lower.contains("wallet"))) {
            if let bal = portfolioUSD {
                return "Your current USD balance is **$\(String(format: "%.2f", bal))**.\n\nYou can manage your portfolio and execute trades from the **Portfolio** and **Trade** tabs."
            }
            return "Portfolio data isn't available right now. Check the Portfolio tab for your latest balances."
        }

        // Help / capabilities
        if lower.contains("help") || lower.contains("what can you") || lower.contains("capabilities") || lower.contains("commands") || lower.contains("how do you") {
            return "I'm Kahlo AI, your on-device crypto assistant. I can help with:\n\n• **Market prices** — \"What's the price of BTC?\"\n• **Technical indicators** — \"What's the RSI?\" or \"Analyze the Bollinger Bands\"\n• **Forecasts** — \"What does the neural net predict?\"\n• **Portfolio** — \"How much USD do I have?\"\n• **Analysis** — \"Analyze the current market conditions\"\n• **Concepts** — \"What is RSI?\" or \"Explain Bollinger Bands\"\n• **Trading** — \"What's a good trading strategy?\"\n\nEverything runs **on-device** — no data is sent to external servers with the built-in Tiny Swift engine."
        }

        // Educational: What is RSI?
        if lower.contains("what is rsi") || lower.contains("explain rsi") || lower.contains("rsi mean") || lower.contains("rsi indicator") {
            return "**RSI (Relative Strength Index)** is a momentum oscillator that measures the speed and change of price movements on a scale of 0 to 100.\n\n• **Above 70** = Overbought — the asset may be due for a pullback\n• **Below 30** = Oversold — the asset may be due for a bounce\n• **Middle (30-70)** = Neutral — normal trading range\n\nKahlo uses a 14-period RSI by default, configurable in Settings."
        }

        // Educational: Bollinger Bands
        if lower.contains("explain bollinger") || lower.contains("what are bollinger") || lower.contains("bollinger bands") || lower.contains("how do bollinger") {
            return "**Bollinger Bands** consist of three lines:\n\n• **Middle Band**: A simple moving average (SMA)\n• **Upper Band**: SMA + (standard deviation × multiplier)\n• **Lower Band**: SMA - (standard deviation × multiplier)\n\nWhen bands widen, volatility is increasing. When they contract (a \"squeeze\"), a breakout may be coming. Prices touching the upper band suggest strength; the lower band suggests weakness.\n\nKahlo's default settings are a 20-period SMA with 2.0 standard deviations."
        }

        // Educational: Trading strategies
        if lower.contains("strategy") || lower.contains("strategies") || lower.contains("how to trade") || lower.contains("trading tip") || lower.contains("risk management") {
            let strategies = [
                "**Dollar-Cost Averaging (DCA)**: Invest a fixed amount at regular intervals regardless of price. Reduces the impact of volatility.",
                "**Trend Following**: Trade in the direction of the prevailing trend. Use moving averages to identify direction.",
                "**Mean Reversion**: Buy when prices are below their historical average (oversold) and sell when above (overbought). Kahlo uses this with Bollinger Bands!",
                "**Risk Management**: Never risk more than 1-2% of your portfolio on a single trade. Always use stop-losses and take-profits — Kahlo has these built-in.",
            ]
            return "Here are some common strategies:\n\n\(strategies.randomElement()!)\n\nYou can configure Kahlo's auto-trading parameters in **Settings** under Risk Management."
        }

        // About the app
        if lower.contains("what is kahlo") || lower.contains("about this app") || lower.contains("what does kahlo do") || lower.contains("tell me about kahlo") {
            return "**Kahlo** is a premium iOS cryptocurrency tracking and algorithmic trading simulator. Key features:\n\n• **Live Market Data** — Track 100+ coins with real-time prices\n• **Neural Network AI** — On-device predictions with a [8,16,8,4,1] architecture\n• **Technical Indicators** — Bollinger Bands, RSI, Bandwidth\n• **Auto-Trading Bot** — Configurable strategies with stop-loss & take-profit\n• **On-Device LLM** — Built-in AI analysis (no server needed)\n• **Portfolio Tracking** — Manual trading with P&L tracking\n• **Price Alerts** — Push notifications when targets are hit"
        }

        // Who built it
        if lower.contains("who made") || lower.contains("who created") || lower.contains("developer") || lower.contains("creator") {
            return "Kahlo was created by **Aanetra Vaidya**. It's built natively with SwiftUI and Combine, featuring a glassmorphic dark design."
        }

        // Generic crypto knowledge fallbacks
        if lower.contains("crypto") || lower.contains("bitcoin") || lower.contains("ethereum") || lower.contains("blockchain") || lower.contains("defi") {
            let facts = [
                "Bitcoin (BTC) was created in 2009 by an anonymous entity known as Satoshi Nakamoto. It was the first decentralized cryptocurrency.",
                "Ethereum (ETH) introduced smart contracts in 2015, enabling decentralized applications (dApps) beyond simple payments.",
                "DeFi (Decentralized Finance) refers to financial services built on blockchain that operate without traditional intermediaries like banks.",
                "Market capitalization (market cap) is calculated by multiplying the current price by the circulating supply. It's a key metric for comparing asset sizes.",
            ]
            return facts.randomElement()!
        }

        // Default fallback
        let fallbacks = [
            "That's an interesting question! I'm best equipped to help with cryptocurrency prices, technical indicators, trading strategies, and portfolio insights. Could you rephrase your question?",
            "I'm not sure I understand — but I can help with market analysis, indicators, trading, and crypto concepts. Try asking about prices, RSI, Bollinger Bands, or your portfolio!",
            "I'm still learning! I specialize in crypto market data, technical analysis, and trading strategies. Could you ask about something related to those topics?",
        ]
        return fallbacks.randomElement()!
    }
}

// MARK: - Core ML Engine

actor CoreMLEngine: LLMInferenceEngine {
    enum CoreMLError: LocalizedError {
        case modelNotFound(String), inferenceFailed(String)

        var errorDescription: String? {
            switch self {
            case .modelNotFound(let name): return "Model '\(name)' not found"
            case .inferenceFailed(let msg): return "Inference failed: \(msg)"
            }
        }
    }

    private let modelName: String

    init(modelName: String) {
        self.modelName = modelName
    }

    func generate(prompt: String, config: LLMModelConfig) async throws -> String {
        guard let modelURL = findModel() else {
            throw CoreMLError.modelNotFound(modelName)
        }
        return try await runInference(modelURL: modelURL, prompt: prompt, config: config)
    }

    private func findModel() -> URL? {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let candidates = [
            Bundle.main.bundleURL.appendingPathComponent("\(modelName).mlpackage"),
            Bundle.main.bundleURL.appendingPathComponent("\(modelName).mlmodelc"),
            docDir?.appendingPathComponent("\(modelName).mlpackage"),
            docDir?.appendingPathComponent("\(modelName).mlmodelc"),
        ]
        return candidates.compactMap { $0 }.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    private func runInference(modelURL: URL, prompt: String, config: LLMModelConfig) async throws -> String {
        #if canImport(CoreML)
        let model = try await MLModel.load(contentsOf: modelURL)
        let input = try MLDictionaryFeatureProvider(dictionary: [
            "prompt": prompt as NSString,
            "maxTokens": NSNumber(value: config.maxTokens),
            "temperature": NSNumber(value: config.temperature),
        ])
        let output = try await model.prediction(from: input)
        if let text = output.featureValue(for: "response")?.stringValue {
            return text
        }
        throw CoreMLError.inferenceFailed("No response from model")
        #else
        throw CoreMLError.inferenceFailed("Core ML not available on this platform")
        #endif
    }
}

// MARK: - Prompt Builder

struct MarketPromptBuilder {
    static func buildAnalysisPrompt(
        symbol: String,
        price: Double,
        rsi: Double?,
        bbPosition: String,
        bandwidth: Double?,
        momentum: Double,
        volatility: Double?,
        prediction: Double,
        accuracy: Double,
        portfolioUSD: Double,
        holdings: [String: Double],
        avgBuyPrice: Double?
    ) -> String {
        let holdingsStr = holdings.isEmpty
            ? "None"
            : holdings.map { "\($0.key): \(String(format: "%.6f", $0.value))" }.joined(separator: ", ")

        let entryPrice = avgBuyPrice.map { String(format: "$%.2f", $0) } ?? "N/A"
        let pnl = avgBuyPrice.map { ((price - $0) / $0) * 100 } ?? 0

        return """
            Market Data for \(symbol):
            - Current Price: $\(String(format: "%.2f", price))
            - RSI (14): \(rsi.map { String(format: "%.1f", $0) } ?? "N/A") \(rsi.map { $0 > 70 ? "(overbought)" : $0 < 30 ? "(oversold)" : "" } ?? "")
            - Bollinger Band Position: \(bbPosition)
            - Bandwidth: \(bandwidth.map { String(format: "%.4f", $0) } ?? "N/A")
            - 5-Tick Momentum: \(String(format: "%+.2f%%", momentum))
            - Volatility: \(volatility.map { String(format: "%.2f%%", $0) } ?? "N/A")
            - NN Prediction: \(String(format: "%+.4f", prediction)) (\(prediction > 0.05 ? "bullish" : prediction < -0.05 ? "bearish" : "neutral"))
            - NN Accuracy: \(String(format: "%.0f%%", accuracy))

            Portfolio:
            - USD Balance: $\(String(format: "%.2f", portfolioUSD))
            - Holdings: \(holdingsStr)
            - Avg Entry: \(entryPrice)
            - Unrealized P&L: \(String(format: "%+.2f%%", pnl))

            Analyze the current market conditions and provide:
            1. A one-line summary of market conditions
            2. A trading signal (BULLISH, BEARISH, or NEUTRAL)
            3. Confidence level (0.0 to 1.0)
            4. Brief reasoning for your analysis
            5. Key risks to watch
            """
    }

    static func parseAnalysis(from text: String) -> MarketAnalysis {
        let signal: TradeSignal
        if text.uppercased().contains("BULLISH") {
            signal = .bullish
        } else if text.uppercased().contains("BEARISH") {
            signal = .bearish
        } else {
            signal = .neutral
        }

        let confidence: Double = {
            if let range = text.range(of: #"(\d\.?\d*)"#, options: .regularExpression) {
                let numStr = text[range]
                if let val = Double(numStr), val >= 0, val <= 1 {
                    return val
                }
            }
            return 0.5
        }()

        let lines = text.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let summary = lines.first ?? text
        let risks = lines.filter { $0.lowercased().contains("risk") || $0.lowercased().contains("watch") }

        return MarketAnalysis(
            summary: summary,
            signal: signal,
            confidence: confidence,
            reasoning: text,
            risks: risks
        )
    }
}

// MARK: - Model Manager

public struct ModelEntry: Identifiable, Codable {
    public var id: String { name }
    public let name: String
    public let displayName: String
    public let description: String
    public let sizeMB: Double
    public let remoteURL: String?
    public var isDownloaded: Bool
    public var isBuiltIn: Bool

    public init(name: String, displayName: String, description: String, sizeMB: Double, remoteURL: String? = nil, isDownloaded: Bool = false, isBuiltIn: Bool = false) {
        self.name = name
        self.displayName = displayName
        self.description = description
        self.sizeMB = sizeMB
        self.remoteURL = remoteURL
        self.isDownloaded = isDownloaded
        self.isBuiltIn = isBuiltIn
    }
}

@MainActor
public final class ModelManager: ObservableObject {
    @Published public var availableModels: [ModelEntry] = []
    @Published public var activeModel: String = "tiny-swift"
    @Published public var isDownloading = false
    @Published public var downloadProgress: Double = 0
    @Published public var downloadError: String?

    private let documentsDir: URL
    private let modelsListKey = "kahlo_downloaded_models"

    public init() {
        documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        loadModels()
    }

    public var activeEngine: LLMInferenceEngine {
        if activeModel == "tiny-swift" {
            return TinySwiftEngine()
        }
        return CoreMLEngine(modelName: activeModel)
    }

    private func loadModels() {
        var models = [
            ModelEntry(
                name: "tiny-swift",
                displayName: "Tiny Swift (Built-in)",
                description: "On-device rule-based financial analyst. Zero dependencies, instant responses, no downloads needed.",
                sizeMB: 0,
                isBuiltIn: true
            ),
        ]

        if let data = UserDefaults.standard.data(forKey: modelsListKey),
           let downloaded = try? JSONDecoder().decode([String].self, from: data) {
            for name in downloaded {
                models.append(ModelEntry(
                    name: name,
                    displayName: name,
                    description: "Downloaded Core ML model",
                    sizeMB: 0,
                    isDownloaded: true
                ))
            }
        }

        availableModels = models
    }

    public func downloadModel(name: String, urlString: String) async {
        guard let url = URL(string: urlString) else {
            downloadError = "Invalid URL"
            return
        }

        isDownloading = true
        downloadProgress = 0
        downloadError = nil

        do {
            let (localURL, _) = try await URLSession.shared.download(from: url)
            let destination = documentsDir.appendingPathComponent("\(name).mlpackage")

            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: localURL, to: destination)

            var downloaded = UserDefaults.standard.data(forKey: modelsListKey)
                .flatMap { try? JSONDecoder().decode([String].self, from: $0) } ?? []
            if !downloaded.contains(name) {
                downloaded.append(name)
            }
            UserDefaults.standard.set(try? JSONEncoder().encode(downloaded), forKey: modelsListKey)

            loadModels()
            downloadProgress = 1.0
        } catch {
            downloadError = error.localizedDescription
        }

        isDownloading = false
    }

    public func deleteModel(_ name: String) {
        let urls = [
            documentsDir.appendingPathComponent("\(name).mlpackage"),
            documentsDir.appendingPathComponent("\(name).mlmodelc"),
        ]
        for url in urls where FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }

        var downloaded = UserDefaults.standard.data(forKey: modelsListKey)
            .flatMap { try? JSONDecoder().decode([String].self, from: $0) } ?? []
        downloaded.removeAll { $0 == name }
        UserDefaults.standard.set(try? JSONEncoder().encode(downloaded), forKey: modelsListKey)

        if activeModel == name { activeModel = "tiny-swift" }
        loadModels()
    }
}

// MARK: - Observable Service

@MainActor
public final class LLMService: ObservableObject {
    @Published public var config: LLMModelConfig = .default
    @Published public var isEnabled: Bool = false
    @Published public var isAnalyzing: Bool = false
    @Published public var lastAnalysis: MarketAnalysis?
    @Published public var errorMessage: String?
    @Published public var rawResponse: String?

    public let modelManager = ModelManager()
    private var analysisTask: Task<Void, Never>?

    public init() {}

    public func analyzeMarket(
        symbol: String,
        price: Double,
        rsi: Double?,
        bbPosition: String,
        bandwidth: Double?,
        momentum: Double,
        volatility: Double?,
        prediction: Double,
        accuracy: Double,
        portfolioUSD: Double,
        holdings: [String: Double],
        avgBuyPrice: Double?
    ) {
        analysisTask?.cancel()
        guard isEnabled else { return }

        analysisTask = Task { [weak self] in
            guard let self else { return }
            isAnalyzing = true
            errorMessage = nil

            let prompt = MarketPromptBuilder.buildAnalysisPrompt(
                symbol: symbol,
                price: price,
                rsi: rsi,
                bbPosition: bbPosition,
                bandwidth: bandwidth,
                momentum: momentum,
                volatility: volatility,
                prediction: prediction,
                accuracy: accuracy,
                portfolioUSD: portfolioUSD,
                holdings: holdings,
                avgBuyPrice: avgBuyPrice
            )

            do {
                let engine = modelManager.activeEngine
                let result = try await engine.generate(prompt: prompt, config: config)
                guard !Task.isCancelled else { return }
                rawResponse = result
                lastAnalysis = MarketPromptBuilder.parseAnalysis(from: result)
                errorMessage = nil
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
            }

            isAnalyzing = false
        }
    }

    public func cancelAnalysis() {
        analysisTask?.cancel()
        analysisTask = nil
        isAnalyzing = false
    }
}
