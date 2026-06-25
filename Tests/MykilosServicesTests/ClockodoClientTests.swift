import Testing
import Foundation
@testable import MykilosServices

struct ClockodoClientTests {

    @Test func buildEntriesURLEnthaeltTimeSinceUndTimeUntil() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let url = ClockodoClient.buildEntriesURL(
            baseURL: "https://my.clockodo.com/api/v2/entries",
            now: now
        )
        let components = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let items = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(items["time_since"] != nil)
        #expect(items["time_until"] != nil)
    }

    @Test func parseEntriesDekodiertProjektUndDauer() throws {
        let json = """
        {
          "entries": [
            { "id": 1, "customers_name": "Kunde A", "projects_name": "Projekt X", "duration": 3600 },
            { "id": 2, "customers_name": "Kunde B", "projects_name": null, "duration": 1800 }
          ]
        }
        """
        let entries = try ClockodoClient.parseEntries(from: Data(json.utf8))

        #expect(entries.count == 2)
        #expect(entries[0].label == "Projekt X")
        #expect(entries[0].durationSeconds == 3600)
        #expect(entries[1].label == "Kunde B")
        #expect(entries[1].durationSeconds == 1800)
    }

    @Test func parseEntriesFallbackOhneProjektOhneKunde() throws {
        let json = """
        { "entries": [{ "id": 1, "customers_name": null, "projects_name": null, "duration": 900 }] }
        """
        let entries = try ClockodoClient.parseEntries(from: Data(json.utf8))
        #expect(entries[0].label == "(ohne Projekt)")
    }

    @Test func parseEntriesWirftBeiKaputtemJSON() {
        #expect(throws: ClockodoError.decodingFailed) {
            _ = try ClockodoClient.parseEntries(from: Data("nope".utf8))
        }
    }

    @Test func todaysEntriesWirftNotConnectedOhneCredentials() async {
        let store = InMemoryClockodoCredentialsStore()
        let client = ClockodoClient(credentialsStore: store)

        do {
            _ = try await client.todaysEntries()
            Issue.record("sollte werfen")
        } catch {
            #expect(error as? ClockodoError == .notConnected)
        }
    }
}

// MARK: - InMemoryClockodoCredentialsStore

final class InMemoryClockodoCredentialsStore: ClockodoCredentialsStoring, @unchecked Sendable {
    private var stored: ClockodoCredentials?

    init(credentials: ClockodoCredentials? = nil) {
        self.stored = credentials
    }

    func store(_ credentials: ClockodoCredentials) throws {
        self.stored = credentials
    }

    func load() throws -> ClockodoCredentials? {
        stored
    }

    func clear() throws {
        stored = nil
    }
}
