import Foundation
import Combine

@MainActor
public final class ChatService: ObservableObject {
    @Published public var messages: [ChatMessage] = []
    @Published public var isResponding = false
    @Published public var errorMessage: String?

    private var llmService: LLMService

    public init() {
        self.llmService = LLMService()
        messages.append(ChatMessage(
            role: .assistant,
            content: "Hello! I'm **Kahlo AI**, your on-device crypto assistant.\n\nAsk me about:\n• Current market conditions\n• Technical indicators (RSI, Bollinger Bands)\n• Trading strategies & risk management\n• Portfolio insights\n• Cryptocurrency concepts"
        ))
    }

    public convenience init(llmService: LLMService) {
        self.init()
        self.llmService = llmService
    }

    public func send(_ text: String, context: String = "") async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: trimmed)
        messages.append(userMessage)
        isResponding = true
        errorMessage = nil

        let prompt = context.isEmpty ? trimmed : "\(context)\n\n[USER MESSAGE]\n\(trimmed)"

        do {
            let engine = llmService.modelManager.activeEngine
            let response = try await engine.generate(prompt: prompt, config: llmService.config)
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            messages.append(assistantMessage)
        } catch {
            errorMessage = error.localizedDescription
            let fallback = ChatMessage(
                role: .assistant,
                content: "Sorry, I encountered an issue: \(error.localizedDescription)"
            )
            messages.append(fallback)
        }

        isResponding = false
    }

    public func clear() {
        messages.removeAll()
        messages.append(ChatMessage(
            role: .assistant,
            content: "Hello! I'm **Kahlo AI**, your on-device crypto assistant.\n\nAsk me about:\n• Current market conditions\n• Technical indicators (RSI, Bollinger Bands)\n• Trading strategies & risk management\n• Portfolio insights\n• Cryptocurrency concepts"
        ))
    }
}
