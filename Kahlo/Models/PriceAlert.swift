import Foundation

public struct PriceAlert: Codable, Identifiable, Hashable {
    public var id = UUID()
    public var symbol: String
    public var type: AlertType
    public var targetValue: Double
    public var isActive: Bool = true
    
    public enum AlertType: String, Codable, CaseIterable {
        case priceAbove = "Price Above"
        case priceBelow = "Price Below"
        case changeAbove = "24h Change Above (%)"
        case changeBelow = "24h Change Below (%)"
    }

    public init(id: UUID = UUID(), symbol: String, type: AlertType, targetValue: Double, isActive: Bool = true) {
        self.id = id
        self.symbol = symbol
        self.type = type
        self.targetValue = targetValue
        self.isActive = isActive
    }
}
