import Foundation
import MykilosKit

// MARK: - Wire-DTOs (API-Form, getrennt von der Domäne ChatMessage)
// Phase 1: nur Text-Blöcke. tool_use/tool_result (Phase 2) und image/document
// (Phase 3) werden hier ergänzt — die Domäne ist dafür schon vollständig.
struct ClaudeWireMessage: Encodable, Equatable {
    var role: String
    var content: [ClaudeWireTextBlock]
}

struct ClaudeWireTextBlock: Encodable, Equatable {
    var type: String = "text"
    var text: String
}

struct ClaudeChatRequestPayload: Encodable, Equatable {
    var model: String
    var maxTokens: Int
    var system: String
    var messages: [ClaudeWireMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system
        case messages
    }
}

// MARK: - ClaudeChatClient
// Multi-Turn-Chat über die Anthropic Messages API. Parallel zum bestehenden
// ClaudeMessagesClient (Einmal-Summary bleibt unangetastet). Teilt
// Keychain-Credentials + injizierbaren HTTP-Client → testbar ohne Netz/Keychain.
public struct ClaudeChatClient: AssistantChatProviding {
    private let credentialsStore: ClaudeCredentialsStoring
    private let httpClient: ClaudeHTTPClient
    private let baseURL: URL

    public init(
        credentialsStore: ClaudeCredentialsStoring = KeychainClaudeCredentialsStore(),
        httpClient: ClaudeHTTPClient = URLSession.shared,
        baseURL: URL = URL(string: "https://api.anthropic.com/v1/messages")!
    ) {
        self.credentialsStore = credentialsStore
        self.httpClient = httpClient
        self.baseURL = baseURL
    }

    public func chat(messages: [ChatMessage], system: String, maxTokens: Int = 1024) async throws -> String {
        guard let credentials = try credentialsStore.load() else { throw ClaudeClientError.notConnected }
        let request = try Self.buildChatRequest(
            url: baseURL, credentials: credentials, messages: messages, system: system, maxTokens: maxTokens
        )
        let (data, response) = try await httpClient.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ClaudeClientError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw Self.mapHTTPError(status: http.statusCode, response: http) }
        return try Self.parseChatResponse(from: data)
    }

    // MARK: - Reine, testbare Bausteine (kein Netz/Keychain)

    static func buildChatRequest(
        url: URL, credentials: ClaudeCredentials, messages: [ChatMessage], system: String, maxTokens: Int
    ) throws -> URLRequest {
        let payload = ClaudeChatRequestPayload(
            model: credentials.model,
            maxTokens: maxTokens,
            system: system,
            messages: messages.map(wire(from:))
        )
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(credentials.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(payload)
        return request
    }

    // Phase 1: Domäne → Wire nur über Text-Blöcke (leerer Text → " ", da die
    // API leere content-Blöcke ablehnt).
    static func wire(from message: ChatMessage) -> ClaudeWireMessage {
        let joined = message.blocks
            .compactMap { if case let .text(value) = $0 { return value } else { return nil } }
            .joined(separator: "\n")
        return ClaudeWireMessage(
            role: message.role.rawValue,
            content: [ClaudeWireTextBlock(text: joined.isEmpty ? " " : joined)]
        )
    }

    static func parseChatResponse(from data: Data) throws -> String {
        do {
            let response = try JSONDecoder().decode(ChatResponseDTO.self, from: data)
            let text = response.content
                .compactMap { $0.type == "text" ? $0.text?.trimmingCharacters(in: .whitespacesAndNewlines) : nil }
                .filter { $0.isEmpty == false }
                .joined(separator: "\n\n")
            guard text.isEmpty == false else { throw ClaudeClientError.emptyResponse }
            return text
        } catch let error as ClaudeClientError {
            throw error
        } catch {
            throw ClaudeClientError.decodingFailed
        }
    }

    static func mapHTTPError(status: Int, response: HTTPURLResponse) -> ClaudeClientError {
        switch status {
        case 429:
            let retry = response.value(forHTTPHeaderField: "retry-after").flatMap { Int($0) }
            return .rateLimited(retryAfter: retry)
        case 529:
            return .overloaded
        default:
            return .httpError(status)
        }
    }
}

private struct ChatResponseDTO: Decodable {
    var content: [Block]
    struct Block: Decodable {
        var type: String
        var text: String?
    }
}
