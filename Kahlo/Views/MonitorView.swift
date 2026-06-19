import SwiftUI

struct MonitorView: View {
    @ObservedObject var engine: TradingEngine
    @State private var priceColor: Color = .primary
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignConstant.spacingLg) {
                // Header status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MONÉT TRADING BOT")
                            .font(.system(.title2, design: .rounded))
                            .bold()
                            .foregroundColor(.primary)
                        Text(engine.symbol + " / USD")
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    
                    HStack(spacing: 6) {
                        if engine.isRunning {
                            PulsingDot(color: .green)
                        } else {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                        }
                        Text(engine.isRunning ? "RUNNING" : "STOPPED")
                            .font(.system(.caption, design: .monospaced))
                            .bold()
                            .foregroundColor(engine.isRunning ? .green : .red)
                    }
                    .padding(.horizontal, DesignConstant.paddingSm)
                    .padding(.vertical, 6)
                    .background(engine.isRunning ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(engine.isRunning ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.top, 10)
                
                // Realtime Price & Sparkline
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Price")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(engine.price > 0 ? engine.selectedCurrency.format(engine.price) : engine.selectedCurrency.format(0.0))
                                .font(.system(size: 38, weight: .bold, design: .monospaced))
                                .foregroundColor(priceColor)
                                .onChange(of: engine.price) { oldPrice, newPrice in
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        if newPrice > oldPrice {
                                            priceColor = .green
                                        } else if newPrice < oldPrice {
                                            priceColor = .red
                                        }
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        withAnimation {
                                            priceColor = .white
                                        }
                                    }
                                }
                        }
                        Spacer()
                        
                        if !engine.isRunning {
                            Button(action: {
                                HapticManager.medium()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    engine.start()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("START")
                                }
                                .font(.system(.subheadline, design: .monospaced))
                                .bold()
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.green)
                                .cornerRadius(DesignConstant.cornerRadiusSm)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        } else {
                            Button(action: {
                                HapticManager.medium()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    engine.stop()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "stop.fill")
                                    Text("STOP")
                                }
                                .font(.system(.subheadline, design: .monospaced))
                                .bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.red)
                                .cornerRadius(DesignConstant.cornerRadiusSm)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    
                    // Chart Area
                    VStack {
                        LineChart(history: engine.history)
                            .frame(height: 180)
                            .padding(.vertical, 10)
                    }
                    .glassPanel()
                }
                .padding()
                .glassPanel()
                
                // Indicators Panel (Bollinger, RSI, Bandwidth)
                VStack(spacing: DesignConstant.spacingMd) {
                    Text("TECHNICAL INDICATORS")
                        .font(.system(.caption, design: .monospaced))
                        .bold()
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Bollinger Bands Meter
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Bollinger Band Position")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            if let s = engine.sma {
                                Text("SMA: \(engine.selectedCurrency.format(s))")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.cyan)
                            }
                        }
                        
                        GeometryReader { meterGeo in
                            ZStack(alignment: .leading) {
                                // Background gradient bar
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.red.opacity(0.2), Color.purple.opacity(0.1), Color.green.opacity(0.2)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 8)
                                
                                Text("LOWER")
                                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                                    .foregroundColor(.purple)
                                    .offset(y: 14)
                                
                                Text("UPPER")
                                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                                    .foregroundColor(.purple)
                                    .offset(x: meterGeo.size.width - 32, y: 14)
                                
                                if let upper = engine.upper, let lower = engine.lower {
                                    let range = upper - lower
                                    let pct = range > 0 ? max(0.0, min(1.0, (engine.price - lower) / range)) : 0.5
                                    
                                    Circle()
                                        .fill(Color.purple)
                                        .frame(width: 14, height: 14)
                                        .offset(x: meterGeo.size.width * CGFloat(pct) - 7, y: -3)
                                        .shadow(color: .purple.opacity(0.6), radius: 4)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: pct)
                                }
                            }
                        }
                        .frame(height: 28)
                    }
                    .padding(.bottom, 6)
                    
                    Divider().background(Color.white.opacity(0.05))
                    
                    // RSI and Bandwidth Squeeze
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("RSI (\(engine.rsiPeriod))")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                if let r = engine.rsi {
                                    Text("\(String(format: "%.1f", r))")
                                        .font(.system(.caption, design: .monospaced))
                                        .bold()
                                        .foregroundColor(rsiColor(r))
                                }
                            }
                            
                            GeometryReader { progressGeo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.white.opacity(0.05))
                                        .frame(height: 6)
                                    
                                    if let r = engine.rsi {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(rsiColor(r))
                                            .frame(width: progressGeo.size.width * CGFloat(r / 100.0), height: 6)
                                            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: r)
                                    }
                                }
                            }
                            .frame(height: 6)
                        }
                        
                        Divider().background(Color.white.opacity(0.05))
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Bollinger Bandwidth")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                if let bw = engine.bandwidth {
                                    Text(String(format: "%.5f", bw))
                                        .font(.system(.subheadline, design: .monospaced))
                                        .bold()
                                        .foregroundColor(.primary)
                                    
                                    if bw < 0.0002 {
                                        Text("SQUEEZE")
                                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.red.opacity(0.2))
                                            .foregroundColor(.red)
                                            .cornerRadius(4)
                                    }
                                } else {
                                    Text("—")
                                        .font(.system(.subheadline, design: .monospaced))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .glassPanel()
                
                // Logging Console
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("SYSTEM LOGS")
                            .font(.system(.caption, design: .monospaced))
                            .bold()
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(engine.logs.count) entries")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                if engine.logs.isEmpty {
                                    Text("[System] Idle. Click Start to initialize feed.")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.gray)
                                } else {
                                    ForEach(Array(engine.logs.enumerated()), id: \.offset) { index, log in
                                        Text(log)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(logColor(log))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .id(index)
                                            .transition(.move(edge: .leading).combined(with: .opacity))
                                    }
                                }
                            }
                            .onChange(of: engine.logs.count) { _, newCount in
                                if let lastIndex = engine.logs.indices.last {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        proxy.scrollTo(lastIndex, anchor: .bottom)
                                    }
                                }
                            }
                        }
                        .frame(height: 140)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .background(Color.black.opacity(0.55))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
                        )
                    }
                }
                .padding()
                .glassPanel()
            }
            .padding(.horizontal)
        }
        .background(GlassBackgroundView())
    }
    
    private func rsiColor(_ rsi: Double) -> Color {
        if rsi < engine.rsiOversold {
            return .green
        } else if rsi > engine.rsiOverbought {
            return .red
        }
        return .cyan
    }
    
    private func logColor(_ log: String) -> Color {
        if log.contains("Filled BUY") {
            return .green
        } else if log.contains("Filled SELL") {
            return .red
        } else if log.contains("Error") || log.contains("Vetoed") {
            return .orange
        } else if log.contains("Calibrating") {
            return .yellow
        }
        return .white.opacity(0.85)
    }
}

// MARK: - Pulsing Status Dot View
struct PulsingDot: View {
    let color: Color
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(color, lineWidth: 1.5)
                    .scaleEffect(isAnimating ? 2.5 : 1.0)
                    .opacity(isAnimating ? 0.0 : 0.8)
            )
            .onAppear {
                withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}
