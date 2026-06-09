import SwiftUI

struct SettingsView: View {
    @ObservedObject var engine: TradingEngine
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("API & Connectivity")) {
                    Toggle("Use Simulator (Mock Data)", isOn: $engine.useSimulator)
                        .tint(.purple)
                    
                    if !engine.useSimulator {
                        SecureField("CoinMarketCap API Key", text: $engine.apiKey)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                    }
                }
                
                Section(header: Text("Trading Configuration")) {
                    Picker("Asset Symbol", selection: $engine.symbol) {
                        Text("BTC").tag("BTC")
                        Text("ETH").tag("ETH")
                        Text("SOL").tag("SOL")
                        Text("BNB").tag("BNB")
                    }
                    
                    HStack {
                        Text("Refresh Interval (s)")
                        Spacer()
                        TextField("Seconds", value: $engine.interval, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
                
                Section(header: Text("Risk Management")) {
                    Picker("Position Sizing", selection: $engine.positionMode) {
                        Text("Percentage (%)").tag("percent")
                        Text("Fixed USD").tag("fixed")
                    }
                    
                    if engine.positionMode == "percent" {
                        HStack {
                            Text("Risk per Trade (%)")
                            Spacer()
                            TextField("Risk %", value: Binding(
                                get: { engine.buyRiskPct * 100 },
                                set: { engine.buyRiskPct = $0 / 100 }
                            ), formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        }
                    } else {
                        HStack {
                            Text("Fixed Trade Amount ($)")
                            Spacer()
                            TextField("USD", value: $engine.tradeAmt, formatter: NumberFormatter())
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                    }
                    
                    HStack {
                        Text("Stop Loss (%)")
                        Spacer()
                        TextField("Stop Loss %", value: Binding(
                            get: { engine.stopLossPct * 100 },
                            set: { engine.stopLossPct = $0 / 100 }
                        ), formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Take Profit (%)")
                        Spacer()
                        TextField("Take Profit %", value: Binding(
                            get: { engine.takeProfitPct * 100 },
                            set: { engine.takeProfitPct = $0 / 100 }
                        ), formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    }
                }
                
                Section(header: Text("Neural Engine & Indicators")) {
                    HStack {
                        Text("Learning Rate")
                        Spacer()
                        TextField("LR", value: $engine.aiLearningRate, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Bollinger Window")
                        Spacer()
                        TextField("Window", value: $engine.bbWindow, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Bollinger Std Dev")
                        Spacer()
                        TextField("Std Dev", value: $engine.bbStdDev, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("RSI Period")
                        Spacer()
                        TextField("Period", value: $engine.rsiPeriod, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("RSI Oversold Level")
                        Spacer()
                        TextField("Level", value: $engine.rsiOversold, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("RSI Overbought Level")
                        Spacer()
                        TextField("Level", value: $engine.rsiOverbought, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(GlassBackgroundView())
        }
        // Force dark mode to match the rest of the application
        .preferredColorScheme(.dark)
    }
}
