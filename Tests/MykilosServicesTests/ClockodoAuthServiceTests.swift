import Testing
import Foundation
@testable import MykilosServices
@testable import MykilosKit

struct ClockodoAuthServiceTests {

    @Test @MainActor func startetDisconnectedOhneCredentials() {
        let store = InMemoryClockodoCredentialsStore()
        let service = ClockodoAuthService(credentialsStore: store)
        #expect(service.status == .disconnected)
    }

    @Test @MainActor func startetConnectedMitGespeichertenCredentials() {
        let store = InMemoryClockodoCredentialsStore(
            credentials: ClockodoCredentials(email: "a@b.de", apiKey: "key")
        )
        let service = ClockodoAuthService(credentialsStore: store)
        #expect(service.status == .connected)
    }

    @Test @MainActor func connectSpeichertUndSetztConnected() throws {
        let store = InMemoryClockodoCredentialsStore()
        let service = ClockodoAuthService(credentialsStore: store)
        try service.connect(email: "test@example.com", apiKey: "abc123")
        #expect(service.status == .connected)
        let creds = try store.load()
        #expect(creds?.email == "test@example.com")
        #expect(creds?.apiKey == "abc123")
    }

    @Test @MainActor func connectMitLeerenFeldernWirft() {
        let store = InMemoryClockodoCredentialsStore()
        let service = ClockodoAuthService(credentialsStore: store)
        #expect(throws: ClockodoError.notConnected) {
            try service.connect(email: "", apiKey: "")
        }
        #expect(service.status == .error("E-Mail oder API-Key fehlt"))
    }

    @Test @MainActor func disconnectLoeschtUndSetztDisconnected() throws {
        let store = InMemoryClockodoCredentialsStore(
            credentials: ClockodoCredentials(email: "a@b.de", apiKey: "key")
        )
        let service = ClockodoAuthService(credentialsStore: store)
        try service.disconnect()
        #expect(service.status == .disconnected)
        #expect(try store.load() == nil)
    }

    @Test @MainActor func connectTrimtWhitespace() throws {
        let store = InMemoryClockodoCredentialsStore()
        let service = ClockodoAuthService(credentialsStore: store)
        try service.connect(email: "  test@b.de  ", apiKey: "  key123  ")
        let creds = try store.load()
        #expect(creds?.email == "test@b.de")
        #expect(creds?.apiKey == "key123")
    }
}
