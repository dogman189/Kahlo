import Foundation

public struct CoinModel: Identifiable, Hashable {
    public let id = UUID()
    public let symbol: String
    public let name: String
    public var price: Double
    public var change24h: Double
    public var marketCap: Double // in billions
    public var volume24h: Double // in millions
    public var sparkline: [Double]

    public init(symbol: String, name: String, price: Double, change24h: Double, marketCap: Double, volume24h: Double, sparkline: [Double]) {
        self.symbol = symbol
        self.name = name
        self.price = price
        self.change24h = change24h
        self.marketCap = marketCap
        self.volume24h = volume24h
        self.sparkline = sparkline
    }
}
