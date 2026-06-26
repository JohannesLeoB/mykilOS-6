import Testing
import Foundation
@testable import MykilosServices

struct ClaudeAuthServiceTests {

    @Test @MainActor func startetDisconnectedOhneCredentials() {
        let store = InMemoryClaudeCredentialsStore()
        let service = ClaudeAuthService(credentialsStore: store)
        #expect(service.status == .disconnected)
    }

    @Test @MainActor func startetConnectedMitGespeichertenCredentials() {
        let store = InMemoryClaudeCredentialsStore(
            credentials: ClaudeCredentials(apiKey: "sk-ant-test", model: "claude-test")
        )
        let service = ClaudeAuthService(credentialsStore: store)
        #expect(service.status == .connected)
    }

    @Test @MainActor func connectSpeichertGetrimmtUndSetztConnected() throws {
        let store = InMemoryClaudeCredentialsStore()
        let service = ClaudeAuthService(credentialsStore: store)
        try service.connect(apiKey: "  sk-ant-test  ", model: "  claude-test  ")
        #expect(service.status == .connected)
        let creds = try store.load()
        #expect(creds?.apiKey == "sk-ant-test")
        #expect(creds?.model == "claude-test")
    }

    @Test @MainActor func connectNutztDefaultModellBeiLeeremFeld() throws {
        let store = InMemoryClaudeCredentialsStore()
        let service = ClaudeAuthService(credentialsStore: store)
        try service.connect(apiKey: "sk-ant-test", model: " ")
        #expect(try store.load()?.model == ClaudeAuthService.defaultModel)
    }

    @Test @MainActor func connectOhneAPIKeyWirft() {
        let store = InMemoryClaudeCredentialsStore()
        let service = ClaudeAuthService(credentialsStore: store)
        #expect(throws: ClaudeClientError.notConnected) {
            try service.connect(apiKey: "", model: "claude-test")
        }
        #expect(service.status == .error("API-Key fehlt"))
    }

    @Test @MainActor func disconnectLoeschtUndSetztDisconnected() throws {
        let store = InMemoryClaudeCredentialsStore(
            credentials: ClaudeCredentials(apiKey: "sk-ant-test", model: "claude-test")
        )
        let service = ClaudeAuthService(credentialsStore: store)
        try service.disconnect()
        #expect(service.status == .disconnected)
        #expect(try store.load() == nil)
    }
}

final class InMemoryClaudeCredentialsStore: ClaudeCredentialsStoring, @unchecked Sendable {
    private var credentials: ClaudeCredentials?

    init(credentials: ClaudeCredentials? = nil) {
        self.credentials = credentials
    }

    func store(_ credentials: ClaudeCredentials) throws {
        self.credentials = credentials
    }

    func load() throws -> ClaudeCredentials? {
        credentials
    }

    func clear() throws {
        credentials = nil
    }
}
