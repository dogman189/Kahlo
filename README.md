# MONÉT & KAHLO 🎨📊

A premium, state-of-the-art iOS cryptocurrency tracking and autonomous algorithmic trading simulator. Built natively with **SwiftUI** and powered by **Combine**, Kahlo features an advanced neural network prediction engine, real-time Bollinger Band & RSI indicators, interactive visualization graphs, and a comprehensive price alert system.

---

## 🚀 Key Features

### 1. 📊 Markets Dashboard (MONÉT)
* **Real-time Tracker**: Live tracking of the top cryptocurrencies with interactive price metrics and mini sparkline graphs.
* **Smart Filter Pills**: Instantly filter assets by **Gainers**, **Losers**, or **Holdings** (active auto-trading targets).
* **Clickable Summary Cards**: 
  * **Top Gainer / Top Loser**: Shows the best and worst performing assets; clicks reveal full coin details.
  * **Sentiment**: Shows the gainer/loser ratio of the market with a detailed sentiment analysis sheet.
  * **24h Volume**: Visualizes trading volume contribution breakdown and global market capitalization metrics.

### 2. 🤖 Neural AI Brain & Technical Indicators
* **Current Forecasts**: Calculates neural network forecast scores, classifying current sentiment as `BULLISH`, `BEARISH`, or `NEUTRAL`.
* **Network Topology Graph**: Interactive render of the neural network layers (`[8, 16, 8, 4, 1]`) displaying activations and average weight layer norms in real-time.
* **Indicator Stream**: Real-time math engine computing Bollinger Bands, Relative Strength Index (RSI), and Bandwidth metrics.

### 3. 🎯 Price Alerts & Push Notifications
* **Multi-Condition Alerts**: Configure notifications for when a coin goes above/below a specific value or when its 24h percentage change crosses a target threshold.
* **Inline Management**: Set up, view, or delete active alerts right from any coin's detail sheet.
* **System Push Alerts**: Integrates natively with `UserNotifications` to fire instant local push notifications when targets are breached.

### 4. 💼 Portfolio & Manual Trading
* **Real-time Net Worth**: Automatically calculated net worth in USD or alternative currencies based on holding quantities and current market prices.
* **Interactive Holdings**: Click any holding in the list to open the market detail card.
* **Manual Trades**: Instantly execute `BUY` or `SELL` orders at market value with quick percentage-of-balance buttons.

---

## 🛠 Tech Stack

* **Language**: Swift 5.10+
* **Framework**: SwiftUI (Natively structured views with Glassmorphic effects)
* **Asynchronous Engine**: Combine & Async/Await concurrency models
* **Data Sources**: CoinMarketCap API Integration (with seamless simulated fallback data)
* **Local Notifications**: UserNotifications Framework
* **Theme**: Sleek Dark Mode with tailored cyber-cyan, purple, and green accent highlights

---

## 📁 Project Structure

```
Kahlo/
├── Models/
│   ├── CoinModel.swift             # Shared data structure for cryptocurrency assets
│   ├── PriceAlert.swift            # Alert configuration parameters & enumerations
│   ├── AppCurrency.swift           # Alternative fiat conversion logic
│   ├── NotificationManager.swift   # Local push notification handlers
│   ├── TradingEngine.swift         # Core indicator math, simulation loop, & configurations
│   └── NeuralNetwork.swift         # Feedforward neural net & backpropagation logic
└── Views/
    ├── ContentView.swift           # Main navigation and TabBar coordinator
    ├── HomeView.swift              # Markets dashboard, detail sheet, & detail subviews
    ├── TradeView.swift             # Manual order execution panel
    ├── MonitorView.swift           # Real-time algorithm logs and Bollinger Band graph
    ├── BrainView.swift             # Forecast card and neural network activations visualizer
    ├── PortfolioView.swift         # Net Worth analytics, holdings, and trade statistics
    └── Components/
        ├── Glassmorphism.swift     # Glass panels & background view modifiers
        ├── NeuralNetworkView.swift # Custom graphics rendering for network nodes
        ├── LineChart.swift         # Bollinger Bands chart canvas
        └── Theme.swift             # Tailored color schemes & layouts
```

---

## ⚙️ Setup Instructions

### Prerequisites
* **macOS**: Sonoma 14.0 or later
* **Xcode**: Xcode 15.0 or later
* **iOS SDK**: iOS 17.0+ Target

### Build and Run
1. Clone the repository to your local drive.
2. Open `Kahlo.xcodeproj` in Xcode.
3. Select an iOS Simulator destination (e.g. iPhone 15 Pro) or a registered iOS device.
4. Press `⌘ + R` to build and run.
5. Grant Notification permissions on first launch to enable trading alerts and indicators.

---

## 🎨 Visual Design Guidelines
The application utilizes a dark futuristic **glassmorphic design system** (`.glassPanel()` modifiers). The visual elements prioritize:
* Curved borders with fine translucent white gradients (`lineWidth: 1`, `opacity: 0.04`).
* Clear typographic hierarchy using `monospaced` structures for numerical prices and code markers.
* Micro-interaction spring physics animations (`.spring(response: 0.45, dampingFraction: 0.85)`) on all clickable elements.
