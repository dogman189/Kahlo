import SwiftUI

struct ChatView: View {
    @ObservedObject var engine: TradingEngine
    @State private var inputText = ""
    @FocusState private var isFocused: Bool

    private var chat: ChatService { engine.chatService }

    var body: some View {
        VStack(spacing: 0) {
            header
            messagesList
            inputBar
        }
        .background(GlassBackgroundView())
    }

    private var header: some View {
        HStack {
            Text("AI CHAT")
                .font(.sectionHeader)
                .foregroundColor(.mutedLabel)
                .tracking(1.2)

            Spacer()

            if chat.isResponding {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(.cyan)
                    Text("Thinking...")
                        .font(.caption)
                        .foregroundColor(.cyan)
                }
            }

            if !chat.messages.isEmpty {
                Button(action: { chat.clear() }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.caution)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(chat.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    if chat.messages.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.gray.opacity(0.4))
                            Text("Start a conversation with Kahlo AI")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .onChange(of: chat.messages.count) { _ in
                if let last = chat.messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.1))

            HStack(spacing: 10) {
                TextField("Ask Kahlo AI...", text: $inputText)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.primary)
                    .focused($isFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(inputText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? .gray.opacity(0.4)
                            : .cyan)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || chat.isResponding)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color.black.opacity(0.3))
    }

    private func sendMessage() {
        let text = inputText
        inputText = ""
        isFocused = false
        Task {
            let context = buildMarketContext()
            await chat.send(text, context: context)
        }
    }

    private func buildMarketContext() -> String {
        let sym = engine.symbol
        let pr = engine.price
        let r = engine.rsi ?? 50
        let pred = engine.aiPrediction
        let acc = engine.aiAccuracyScore
        let bal = engine.portfolio.usd
        let bbPos: String = {
            if let low = engine.lower, pr <= low { return "below lower band" }
            if let up = engine.upper, pr >= up { return "above upper band" }
            return "within bands"
        }()
        return """
            [SYSTEM CONTEXT]
            Symbol: \(sym)
            Price: \(String(format: "%.2f", pr))
            RSI: \(String(format: "%.1f", r))
            BB Position: \(bbPos)
            Prediction: \(String(format: "%+.4f", pred))
            Accuracy: \(String(format: "%.1f", acc))
            Portfolio USD: \(String(format: "%.2f", bal))
            """
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isUser { Spacer(minLength: 40) }

            if !isUser {
                Image(systemName: "brain")
                    .font(.system(size: 11))
                    .foregroundColor(.purple)
                    .frame(width: 22, height: 22)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(6)
            }

            Text(message.content)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(isUser ? .white : .primary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isUser {
                            LinearGradient(
                                colors: [.cyan.opacity(0.7), .purple.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Color.white.opacity(0.06)
                        }
                    }
                )
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isUser
                                ? Color.white.opacity(0.15)
                                : Color.white.opacity(0.08),
                            lineWidth: 1
                        )
                )

            if !isUser { Spacer(minLength: 40) }
        }
    }
}
