import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

@MainActor
struct ConversationEngineTests {

    // Fängt die letzten Call-Argumente; liefert eine feste Antwort oder wirft.
    final class FakeProvider: AssistantChatProviding, @unchecked Sendable {
        var answer: String
        var error: Error?
        private(set) var lastMessages: [ChatMessage] = []
        private(set) var lastSystem: String = ""
        init(answer: String = "Antwort.", error: Error? = nil) { self.answer = answer; self.error = error }
        func chat(messages: [ChatMessage], system: String, maxTokens: Int) async throws -> String {
            lastMessages = messages; lastSystem = system
            if let error { throw error }
            return answer
        }
    }

    @Test func sendHaengtUserUndAssistentAn() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = ChatStore(db: db)
        let provider = FakeProvider(answer: "Drei Punkte für Montag.")
        let engine = ConversationEngine(chatStore: store, provider: provider)

        await engine.send("Was ist Montag?", scope: .home, focusedProjectID: nil, signals: [], projects: [], now: Date(timeIntervalSince1970: 1_800_000_000))

        let msgs = store.messages(for: .home)
        #expect(msgs.count == 2)
        #expect(msgs[0].role == .user)
        #expect(msgs[0].text == "Was ist Montag?")
        #expect(msgs[1].role == .assistant)
        #expect(msgs[1].status == .complete)
        #expect(msgs[1].text == "Drei Punkte für Montag.")
        // Verlauf an die API enthielt den User-Turn, nicht den leeren Platzhalter.
        #expect(provider.lastMessages.count == 1)
        #expect(provider.lastMessages[0].role == .user)
        #expect(provider.lastSystem.contains("mykilOS-Projektassistent"))
    }

    @Test func sendMarkiertTurnBeiFehlerAlsFailed() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = ChatStore(db: db)
        let provider = FakeProvider(error: ClaudeClientError.notConnected)
        let engine = ConversationEngine(chatStore: store, provider: provider)

        await engine.send("hallo", scope: .home, focusedProjectID: nil, signals: [], projects: [], now: Date())

        let last = store.messages(for: .home).last
        if case .failed = last?.status { } else {
            Issue.record("Erwarte .failed, ist: \(String(describing: last?.status))")
        }
        #expect(last?.text.contains("nicht verbunden") == true)
    }

    @Test func leereEingabeSendetNicht() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = ChatStore(db: db)
        let engine = ConversationEngine(chatStore: store, provider: FakeProvider())
        await engine.send("   ", scope: .home, focusedProjectID: nil, signals: [], projects: [], now: Date())
        #expect(store.messages(for: .home).isEmpty)
    }

    @Test func failedTurnUeberlebtNeustart() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = ChatStore(db: db)
        let engine = ConversationEngine(chatStore: store, provider: FakeProvider(error: ClaudeClientError.overloaded))
        await engine.send("hi", scope: .project("ME-24"), focusedProjectID: "ME-24", signals: [], projects: [], now: Date())

        let storeB = ChatStore(db: db)
        try storeB.loadIfNeeded(.project("ME-24"))
        if case .failed = storeB.messages(for: .project("ME-24")).last?.status { } else {
            Issue.record("Fehler-Turn sollte Neustart überleben")
        }
    }
}
