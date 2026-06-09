import SwiftUI

struct LineChart: View {
    let history: [HistoryPoint]
    
    var body: some View {
        GeometryReader { geo in
            if history.isEmpty {
                VStack {
                    Spacer()
                    Text("Calibrating Price Stream...")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.gray)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ZStack {
                    // Grid lines
                    gridLines(in: geo.size)
                    
                    // Bollinger Band Shading Area
                    bollingerArea(in: geo.size)
                    
                    // Bollinger Upper & Lower bands
                    bandLine(keyPath: \.upper, in: geo.size, color: Color.purple.opacity(0.4))
                    bandLine(keyPath: \.lower, in: geo.size, color: Color.purple.opacity(0.4))
                    
                    // SMA Line
                    bandLine(keyPath: \.sma, in: geo.size, color: Color.cyan.opacity(0.6))
                    
                    // Price Line
                    priceLine(in: geo.size)
                    
                    // Trade events
                    tradeMarkers(in: geo.size)
                }
            }
        }
    }
    
    private var minMaxPrice: (min: Double, max: Double) {
        let prices = history.map { $0.price }
        let smas = history.compactMap { $0.sma }
        let uppers = history.compactMap { $0.upper }
        let lowers = history.compactMap { $0.lower }
        
        let allValues = prices + smas + uppers + lowers
        guard !allValues.isEmpty else { return (0, 1) }
        
        let minVal = allValues.min() ?? 0
        let maxVal = allValues.max() ?? 1
        let padding = (maxVal - minVal) * 0.15
        return (minVal - padding, maxVal + padding)
    }
    
    private func point(for value: Double, index: Int, size: CGSize) -> CGPoint {
        let (minVal, maxVal) = minMaxPrice
        let range = maxVal - minVal
        let x = size.width * (Double(index) / Double(max(1, history.count - 1)))
        let y = size.height - (size.height * CGFloat((value - minVal) / (range > 0 ? range : 1.0)))
        return CGPoint(x: x, y: y)
    }
    
    private func gridLines(in size: CGSize) -> some View {
        VStack(spacing: size.height / 4.0) {
            ForEach(0..<4) { _ in
                Divider().background(Color.white.opacity(0.05))
            }
        }
    }
    
    private func bollingerArea(in size: CGSize) -> some View {
        Path { path in
            var started = false
            // Find points where both upper and lower exist
            for (idx, pt) in history.enumerated() {
                if let upperVal = pt.upper {
                    let ptUpper = point(for: upperVal, index: idx, size: size)
                    if !started {
                        path.move(to: ptUpper)
                        started = true
                    } else {
                        path.addLine(to: ptUpper)
                    }
                }
            }
            
            // Loop backwards for lower band to close the shape
            for (idx, pt) in history.enumerated().reversed() {
                if let lowerVal = pt.lower {
                    let ptLower = point(for: lowerVal, index: idx, size: size)
                    path.addLine(to: ptLower)
                }
            }
            
            path.closeSubpath()
        }
        .fill(Color.purple.opacity(0.04))
    }
    
    private func bandLine(keyPath: KeyPath<HistoryPoint, Double?>, in size: CGSize, color: Color) -> some View {
        Path { path in
            var started = false
            for (idx, pt) in history.enumerated() {
                if let val = pt[keyPath: keyPath] {
                    let ptLoc = point(for: val, index: idx, size: size)
                    if !started {
                        path.move(to: ptLoc)
                        started = true
                    } else {
                        path.addLine(to: ptLoc)
                    }
                }
            }
        }
        .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 4]))
    }
    
    private func priceLine(in size: CGSize) -> some View {
        Path { path in
            guard let firstPrice = history.first?.price else { return }
            path.move(to: point(for: firstPrice, index: 0, size: size))
            for i in 1..<history.count {
                path.addLine(to: point(for: history[i].price, index: i, size: size))
            }
        }
        .stroke(
            LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .leading, endPoint: .trailing),
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
        )
        .shadow(color: Color.cyan.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    private func tradeMarkers(in size: CGSize) -> some View {
        ForEach(0..<history.count, id: \.self) { idx in
            if let trade = history[idx].trade {
                let loc = point(for: history[idx].price, index: idx, size: size)
                Circle()
                    .fill(markerColor(for: trade))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 1.5)
                    )
                    .position(loc)
                    .shadow(radius: 2)
            }
        }
    }
    
    private func markerColor(for trade: String) -> Color {
        switch trade {
        case "BUY":
            return .green
        case "SELL":
            return .red
        case "STOP_LOSS":
            return .orange
        case "TAKE_PROFIT":
            return .emerald // Wait, let's just use .green or custom emerald
        default:
            return .blue
        }
    }
}

extension Color {
    static let emerald = Color(red: 16/255, green: 185/255, blue: 129/255)
}
