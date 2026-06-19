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
            ScrollView {
                VStack(spacing: DesignConstant.spacingLg) {
                    appearanceSection
                    currencySection
                    apiSection
                    tradingSection
                    riskSection
                    neuralSection
                    llmSection
                    navSection
                    resetSection
                }
                .padding(.horizontal, DesignConstant.paddingMd)
                .padding(.vertical, DesignConstant.paddingMd)
            }
            .background(GlassBackgroundView())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                engine.saveConfig()
            }
        }
    }

    // MARK: - Section Wrapper

    private func settingsSection<Content: View>(title: String, footer: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DesignConstant.spacingMd) {
            SectionLabel(text: title)
            
            content()
                .padding(DesignConstant.paddingMd)
                .glassPanel()
            
            if let footer = footer {
                Text(footer)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.6))
                    .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        settingsSection(title: "APPEARANCE") {
            HStack {
                Label("Dark Mode", systemImage: isDarkMode ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                Spacer()
                Toggle("", isOn: $isDarkMode)
                    .tint(.cyan)
                    .labelsHidden()
            }
        }
    }

    // MARK: - Currency

    private var currencySection: some View {
        settingsSection(title: "CURRENCY") {
            HStack {
                Label("Active Currency", systemImage: "dollarsign.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                Spacer()
                Picker("", selection: $engine.selectedCurrency) {
                    ForEach(AppCurrency.allCases) { currency in
                        Text("\(currency.rawValue) (\(currency.symbol))").tag(currency)
                    }
                }
                .pickerStyle(.menu)
                .tint(.cyan)
                .labelsHidden()
                .onChange(of: engine.selectedCurrency) {
                    engine.saveConfig()
                }
            }
        }
    }

    // MARK: - API & Connectivity

    private var apiSection: some View {
        settingsSection(title: "API & CONNECTIVITY") {
            VStack(spacing: DesignConstant.spacingMd) {
                HStack {
                    Label("Simulator Mode", systemImage: "wifi.slash")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                    Spacer()
                    Toggle("", isOn: $engine.useSimulator)
                        .tint(.purple)
                        .labelsHidden()
                }
                
                if !engine.useSimulator {
                    Divider().background(Color.white.opacity(0.06))
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CoinMarketCap API Key")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        SecureField("API Key", text: $engine.apiKey)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                            .font(.system(size: 13, design: .monospaced))
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Trading Configuration

    private var tradingSection: some View {
        settingsSection(title: "TRADING CONFIGURATION") {
            VStack(spacing: DesignConstant.spacingMd) {
                HStack {
                    Label("Asset Symbol", systemImage: "bitcoinsign")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                    Spacer()
                    Picker("", selection: $engine.symbol) {
                        Text("BTC").tag("BTC")
                        Text("ETH").tag("ETH")
                        Text("SOL").tag("SOL")
                        Text("BNB").tag("BNB")
                    }
                    .pickerStyle(.menu)
                    .tint(.cyan)
                    .labelsHidden()
                }
                
                Divider().background(Color.white.opacity(0.06))
                
                HStack {
                    Label("Refresh Interval", systemImage: "clock.arrow.2.circlepath")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                    Spacer()
                    HStack(spacing: 4) {
                        TextField("", value: $engine.interval, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                            .font(.system(size: 14, design: .monospaced))
                        Text("s")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Risk Management

    private var riskSection: some View {
        settingsSection(title: "RISK MANAGEMENT") {
            VStack(spacing: DesignConstant.spacingMd) {
                HStack {
                    Label("Position Sizing", systemImage: "ruler")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                    Spacer()
                    Picker("", selection: $engine.positionMode) {
                        Text("Percentage (%)").tag("percent")
                        Text("Fixed USD").tag("fixed")
                    }
                    .pickerStyle(.menu)
                    .tint(.cyan)
                    .labelsHidden()
                }
                
                Divider().background(Color.white.opacity(0.06))
                
                if engine.positionMode == "percent" {
                    labeledField(label: "Risk per Trade (%)", value: Binding(
                        get: { String(format: "%.1f", engine.buyRiskPct * 100) },
                        set: { if let v = Double($0) { engine.buyRiskPct = v / 100 } }
                    ))
                } else {
                    labeledField(label: "Fixed Trade Amount ($)", value: Binding(
                        get: { String(format: "%.0f", engine.tradeAmt) },
                        set: { if let v = Double($0) { engine.tradeAmt = v } }
                    ))
                }
                
                Divider().background(Color.white.opacity(0.06))
                
                labeledField(label: "Stop Loss (%)", value: Binding(
                    get: { String(format: "%.1f", engine.stopLossPct * 100) },
                    set: { if let v = Double($0) { engine.stopLossPct = v / 100 } }
                ))
                
                Divider().background(Color.white.opacity(0.06))
                
                labeledField(label: "Take Profit (%)", value: Binding(
                    get: { String(format: "%.1f", engine.takeProfitPct * 100) },
                    set: { if let v = Double($0) { engine.takeProfitPct = v / 100 } }
                ))
            }
        }
    }

    // MARK: - Neural Engine & Indicators

    private var neuralSection: some View {
        settingsSection(title: "NEURAL ENGINE & INDICATORS") {
            VStack(spacing: DesignConstant.spacingMd) {
                labeledField(label: "Learning Rate", value: Binding(
                    get: { String(engine.aiLearningRate) },
                    set: { if let v = Double($0) { engine.aiLearningRate = v } }
                ))
                
                Divider().background(Color.white.opacity(0.06))
                
                labeledField(label: "Bollinger Window", value: Binding(
                    get: { "\(engine.bbWindow)" },
                    set: { if let v = Int($0) { engine.bbWindow = v } }
                ))
                
                Divider().background(Color.white.opacity(0.06))
                
                labeledField(label: "Bollinger Std Dev", value: Binding(
                    get: { String(engine.bbStdDev) },
                    set: { if let v = Double($0) { engine.bbStdDev = v } }
                ))
                
                Divider().background(Color.white.opacity(0.06))
                
                labeledField(label: "RSI Period", value: Binding(
                    get: { "\(engine.rsiPeriod)" },
                    set: { if let v = Int($0) { engine.rsiPeriod = v } }
                ))
                
                Divider().background(Color.white.opacity(0.06))
                
                labeledField(label: "RSI Oversold Level", value: Binding(
                    get: { String(format: "%.0f", engine.rsiOversold) },
                    set: { if let v = Double($0) { engine.rsiOversold = v } }
                ))
                
                Divider().background(Color.white.opacity(0.06))
                
                labeledField(label: "RSI Overbought Level", value: Binding(
                    get: { String(format: "%.0f", engine.rsiOverbought) },
                    set: { if let v = Double($0) { engine.rsiOverbought = v } }
                ))
            }
        }
    }

    // MARK: - Local LLM

    private var llmSection: some View {
        settingsSection(title: "LOCAL LLM (ON-DEVICE ANALYSIS)", footer: "The built-in Tiny Swift model runs entirely on-device with no server or internet required. Download additional Core ML models for enhanced analysis.") {
            VStack(spacing: DesignConstant.spacingMd) {
                HStack {
                    Label("Enable Analysis", systemImage: "brain")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                    Spacer()
                    Toggle("", isOn: $engine.useLLM)
                        .tint(.purple)
                        .labelsHidden()
                        .onChange(of: engine.useLLM) {
                            engine.saveConfig()
                        }
                }
                
                if engine.useLLM {
                    Divider().background(Color.white.opacity(0.06))
                    
                    HStack {
                        Label("Active Model", systemImage: "cpu")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
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
                    
                    Divider().background(Color.white.opacity(0.06))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Temperature")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        HStack {
                            Slider(value: Binding(
                                get: { engine.llmService.config.temperature },
                                set: { engine.llmService.config.temperature = $0 }
                            ), in: 0.0...1.0, step: 0.05)
                                .tint(.purple)
                            Text(String(format: "%.2f", engine.llmService.config.temperature))
                                .font(.monoSmall)
                                .foregroundColor(.gray)
                                .frame(width: 40)
                        }
                    }
                    
                    Divider().background(Color.white.opacity(0.06))
                    
                    labeledField(label: "Max Tokens", value: Binding(
                        get: { "\(engine.llmService.config.maxTokens)" },
                        set: { if let v = Int($0) { engine.llmService.config.maxTokens = v } }
                    ))
                    
                    Divider().background(Color.white.opacity(0.06))
                    
                    HStack {
                        Label("Status", systemImage: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
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
        }
    }

    // MARK: - Customize Navigation

    private var navSection: some View {
        settingsSection(title: "CUSTOMIZE NAVIGATION", footer: "At least one tab must remain active. Settings tab cannot be disabled.") {
            VStack(spacing: DesignConstant.spacingMd) {
                navToggle(label: "Markets", icon: "chart.bar.xaxis", isOn: $showTabMarkets)
                Divider().background(Color.white.opacity(0.06))
                navToggle(label: "Trade", icon: "arrow.left.arrow.right.circle.fill", isOn: $showTabTrade)
                Divider().background(Color.white.opacity(0.06))
                navToggle(label: "Terminal", icon: "terminal.fill", isOn: $showTabTerminal)
                Divider().background(Color.white.opacity(0.06))
                navToggle(label: "AI Brain", icon: "brain", isOn: $showTabBrain)
                Divider().background(Color.white.opacity(0.06))
                navToggle(label: "AI Report", icon: "doc.text.magnifyingglass", isOn: $showTabReport)
                Divider().background(Color.white.opacity(0.06))
                navToggle(label: "Portfolio", icon: "chart.pie.fill", isOn: $showTabPortfolio)
                Divider().background(Color.white.opacity(0.06))
                navToggle(label: "Settings (Always On)", icon: "gearshape.fill", isOn: $showTabSettings, disabled: true)
            }
        }
    }

    private func navToggle(label: String, icon: String, isOn: Binding<Bool>, disabled: Bool = false) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.system(size: 14))
                .foregroundColor(disabled ? .gray : .primary)
            Spacer()
            Toggle("", isOn: isOn)
                .tint(.cyan)
                .labelsHidden()
                .disabled(disabled || (activeTabCount <= 1 && isOn.wrappedValue))
        }
        .opacity(disabled ? 0.5 : 1)
    }

    // MARK: - Reset

    private var resetSection: some View {
        settingsSection(title: "RESET DATA") {
            Button(role: .destructive) {
                HapticManager.heavy()
                engine.resetPortfolio()
            } label: {
                HStack {
                    Spacer()
                    Label("Reset Portfolio & Stats", systemImage: "trash")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Helper

    private func labeledField(label: String, value: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.primary)
            Spacer()
            TextField("", text: value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .font(.system(size: 14, design: .monospaced))
                .padding(8)
                .background(.ultraThinMaterial)
                .background(Color.black.opacity(0.2))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        }
    }
}
