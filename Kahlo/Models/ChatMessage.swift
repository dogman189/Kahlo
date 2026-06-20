import Foundation

public enum MessageRole: String, Codable {
    case user
    case assistant
}

public struct ChatMessage: Identifiable, Codable {
    public let id: UUID
    public let role: MessageRole
    public let content: String
    public let timestamp: Date

    public init(role: MessageRole, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}
