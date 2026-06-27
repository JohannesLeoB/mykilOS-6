import Foundation
import MykilosKit

// MARK: - AssistantChatProviding
// Abstrahiert den Chat-Aufruf, damit die Engine ohne Netz/Keychain testbar ist.
public protocol AssistantChatProviding: Sendable {
    func chat(messages: [ChatMessage], system: String, maxTokens: Int) async throws -> String
}

extension ClaudeChatClient: AssistantChatProviding {}

// MARK: - ConversationEngine
// Orchestriert einen Chat-Turn: User-Nachricht anhängen → Platzhalter-Antwort
// (.streaming) → geerdeter Claude-Aufruf → Antwort finalisieren (.complete) bzw.
// bei Fehler .failed. Phase 1: non-streaming (ein Platzhalter, ein finaler Commit).
// Persistenz/SaveState laufen über den ChatStore — keine Schreibvorgänge aus Views.
@MainActor
public final class ConversationEngine {
    private let chatStore: ChatStore
    private let provider: any AssistantChatProviding

    public private(set) var isResponding = false

    public init(chatStore: ChatStore, provider: any AssistantChatProviding) {
        self.chatStore = chatStore
        self.provider = provider
    }

    public func send(
        _ text: String,
        scope: ChatScope,
        focusedProjectID: String?,
        signals: [WidgetSignal],
        projects: [Project],
        now: Date = Date()
    ) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false, isResponding == false else { return }
        isResponding = true
        defer { isResponding = false }

        let user = ChatMessage.text(trimmed, role: .user)
        let placeholder = ChatMessage(role: .assistant, blocks: [.text("")], status: .streaming)
        do {
            try chatStore.append(user, to: scope)
            try chatStore.append(placeholder, to: scope)
        } catch {
            // Persistenzfehler ist über chatStore.saveState in der UI sichtbar.
            return
        }

        // Verlauf für den API-Call: alles AUSSER dem leeren Platzhalter.
        let history = chatStore.messages(for: scope).filter { $0.id != placeholder.id }
        let system = AssistantGrounding.systemPrompt(
            focusedProjectID: focusedProjectID, signals: signals, projects: projects, now: now
        )

        do {
            let answer = try await provider.chat(messages: history, system: system, maxTokens: 1024)
            try chatStore.updateAssistantTurn(id: placeholder.id, blocks: [.text(answer)], status: .complete, in: scope)
        } catch {
            let message = Self.describe(error)
            // try? begründet: scheitert sogar das Finalisieren, ist der Fehler über
            // chatStore.saveState sichtbar; ein erneuter Wurf verpufft im UI-.task.
            try? chatStore.updateAssistantTurn(
                id: placeholder.id, blocks: [.text(message)], status: .failed(message), in: scope
            )
        }
    }

    static func describe(_ error: Error) -> String {
        switch error {
        case ClaudeClientError.notConnected:
            "Claude ist nicht verbunden — bitte in den Einstellungen einen API-Key hinterlegen."
        case ClaudeClientError.rateLimited:
            "Zu viele Anfragen — bitte kurz warten und erneut versuchen."
        case ClaudeClientError.overloaded:
            "Der Dienst ist gerade überlastet — bitte gleich erneut versuchen."
        case ClaudeClientError.httpError(let code):
            "Die Anfrage ist fehlgeschlagen (Fehler \(code))."
        default:
            "Es ist ein Fehler aufgetreten. Bitte erneut versuchen."
        }
    }
}
