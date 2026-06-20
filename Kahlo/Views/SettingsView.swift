import SwiftUI

struct SettingsView: View {
    @ObservedObject var engine: TradingEngine
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("showTabMarkets") private var showTabMarkets = true
    @AppStorage("showTabTrade") private var showTabTrade = true
    @AppStorage("showTabTerminal") private var showTabTerminal = true
    @AppStorage("showTabBrain") private var showTabBrain = true
    @AppStorage("showTabReport") private var showTabReport = true
    @AppStorage("showTabPortfolio") private var showTabPortfolio = true
    @AppStorage("showTabSettings") private var showTabSettings = true

    @State private var showingModelManager = false

    private var activeTabCount: Int {
        var count = 0
        if showTabMarkets { count += 1 }
        if showTabTrade { count += 1 }
        if showTabTerminal { count += 1 }
        if showTabBrain { count += 1 }
        if showTabReport { count += 1 }
        if showTabPortfolio { count += 1 }
        if showTabSettings { count += 1 }
        return count
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .tint(.cyan)
                }
                
                Section(header: Text("Currency")) {
                    Picker("Active Currency", selection: $engine.selectedCurrency) {
                        ForEach(AppCurrency.allCases) { currency in
                            Text("\(currency.rawValue) (\(currency.symbol))").tag(currency)
                        }
                    }
                    .tint(.cyan)
                    .onChange(of: engine.selectedCurrency) {
                        engine.saveConfig()
                    }
                }
                
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

                Section(header: Text("Local LLM (On-Device Analysis)"), footer: Text("The built-in Tiny Swift model runs entirely on-device with no server or internet required. Download additional Core ML models for enhanced analysis.")) {
                    Toggle("Enable On-Device Analysis", isOn: $engine.useLLM)
                        .tint(.purple)
                        .onChange(of: engine.useLLM) {
                            engine.saveConfig()
                        }

                    if engine.useLLM {
                        HStack {
                            Text("Active Model")
                            Spacer()
                            Text(engine.llmService.modelManager.activeModel == "tiny-swift"
                                 ? "Tiny Swift (Built-in)"
                                 : engine.llmService.modelManager.activeModel)
                                .font(.monoSmall)
                                .foregroundColor(.cyan)
                        }

                        Button {
                            showingModelManager = true
                        } label: {
                            HStack {
                                Image(systemName: "square.grid.3x1.folder.fill")
                                    .font(.caption)
                                Text("Manage Models")
                                    .font(.caption)
                            }
                            .tint(.purple)
                        }
                        .sheet(isPresented: $showingModelManager) {
                            ModelManagerView(modelManager: engine.llmService.modelManager)
                        }

                        HStack {
                            Text("Temperature")
                            Spacer()
                            Slider(value: Binding(
                                get: { engine.llmService.config.temperature },
                                set: { engine.llmService.config.temperature = $0 }
                            ), in: 0.0...1.0, step: 0.05)
                                .tint(.purple)
                                .frame(width: 160)
                            Text(String(format: "%.2f", engine.llmService.config.temperature))
                                .font(.monoSmall)
                                .foregroundColor(.gray)
                                .frame(width: 40)
                        }

                        HStack {
                            Text("Max Tokens")
                            Spacer()
                            TextField("Tokens", value: Binding(
                                get: { engine.llmService.config.maxTokens },
                                set: { engine.llmService.config.maxTokens = $0 }
                            ), formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }

                        HStack {
                            Text("Status")
                            Spacer()
                            if engine.llmService.isAnalyzing {
                                HStack(spacing: 4) {
                                    ProgressView().scaleEffect(0.6)
                                    Text("Analyzing...")
                                        .font(.caption)
                                }
                                .foregroundColor(.cyan)
                            } else if engine.llmService.errorMessage != nil {
                                Label("Error", systemImage: "exclamationmark.triangle")
                                    .font(.caption)
                                    .foregroundColor(.caution)
                            } else if engine.llmService.lastAnalysis != nil {
                                Label("Ready", systemImage: "checkmark.circle")
                                    .font(.caption)
                                    .foregroundColor(.positive)
                            } else {
                                Text("Waiting...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }

                Section(header: Text("Customize Navigation"), footer: Text("At least one tab must remain active. Settings tab cannot be disabled to ensure customization is always accessible.")) {
                    Toggle(isOn: $showTabMarkets) {
                        Label("Markets", systemImage: "chart.bar.xaxis")
                    }
                    .tint(.cyan)
                    .disabled(activeTabCount <= 1 && showTabMarkets)
                    
                    Toggle(isOn: $showTabTrade) {
                        Label("Trade", systemImage: "arrow.left.arrow.right.circle.fill")
                    }
                    .tint(.cyan)
                    .disabled(activeTabCount <= 1 && showTabTrade)
                    
                    Toggle(isOn: $showTabTerminal) {
                        Label("Terminal", systemImage: "terminal.fill")
                    }
                    .tint(.cyan)
                    .disabled(activeTabCount <= 1 && showTabTerminal)
                    
                    Toggle(isOn: $showTabBrain) {
                        Label("AI Brain", systemImage: "brain")
                    }
                    .tint(.cyan)
                    .disabled(activeTabCount <= 1 && showTabBrain)
                    
                    Toggle(isOn: $showTabReport) {
                        Label("AI Report", systemImage: "doc.text.magnifyingglass")
                    }
                    .tint(.cyan)
                    .disabled(activeTabCount <= 1 && showTabReport)

                    Toggle(isOn: $showTabPortfolio) {
                        Label("Portfolio", systemImage: "chart.pie.fill")
                    }
                    .tint(.cyan)
                    .disabled(activeTabCount <= 1 && showTabPortfolio)
                    
                    Toggle(isOn: $showTabSettings) {
                        Label("Settings (Always On)", systemImage: "gearshape.fill")
                    }
                    .tint(.cyan)
                    .disabled(true)
                }

                Section(header: Text("Reset Data")) {
                    Button(role: .destructive) {
                        engine.resetPortfolio()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Reset Portfolio & Stats")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(GlassBackgroundView())
            .onDisappear {
                engine.saveConfig()
            }
        }
    }
}
