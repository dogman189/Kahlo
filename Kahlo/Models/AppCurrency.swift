import Foundation
import SwiftUI

public enum AppCurrency: String, CaseIterable, Identifiable, Codable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    case cad = "CAD"
    case aud = "AUD"
    
    public var id: String { self.rawValue }
    
    public var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy: return "¥"
        case .cad: return "CA$"
        case .aud: return "A$"
        }
    }
    
    /// Exchange rate from 1 USD to the target currency
    public var rateFromUSD: Double {
        switch self {
        case .usd: return 1.0
        case .eur: return 0.92
        case .gbp: return 0.78
        case .jpy: return 157.20
        case .cad: return 1.37
        case .aud: return 1.51
        }
    }
    
    /// Convert USD value to this currency
    public func convert(_ usdValue: Double) -> Double {
        return usdValue * rateFromUSD
    }
    
    /// Convert this currency value back to USD
    public func convertToUSD(_ localValue: Double) -> Double {
        return localValue / rateFromUSD
    }
    
    /// Format a USD value in this currency
    public func format(_ usdValue: Double, decimalPlaces: Int = 2) -> String {
        let converted = convert(usdValue)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = self.symbol
        formatter.maximumFractionDigits = decimalPlaces
        formatter.minimumFractionDigits = decimalPlaces
        
        return formatter.string(from: NSNumber(value: converted)) ?? "\(symbol)\(String(format: "%.\(decimalPlaces)f", converted))"
    }
}
