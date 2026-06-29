import Testing
import Foundation
@testable import MykilosServices

@MainActor
struct AirtableHealTests {

    // Vertauschter Swap (PAT im baseID-Feld, Base-ID im pat-Feld) wird beim Lesen
    // automatisch korrigiert und neu gespeichert.
    @Test func storedCredentialsHeiltVertauschtenSwap() throws {
        let store = MutableCredsStore(initial: AirtableCredentials(pat: "appuVMh3KDfKw4OoQ", baseID: "patABC123.def456"))
        let auth = AirtableAuthService(credentialsStore: store)

        let healed = try #require(try auth.storedCredentials())
        #expect(healed.pat == "patABC123.def456")
        #expect(healed.baseID == "appuVMh3KDfKw4OoQ")
        // Heilung wurde persistiert
        #expect(store.loaded?.baseID == "appuVMh3KDfKw4OoQ")
        #expect(store.loaded?.pat == "patABC123.def456")
    }

    // Korrekte Credentials bleiben unangetastet.
    @Test func storedCredentialsLaesstKorrekteInRuhe() throws {
        let store = MutableCredsStore(initial: AirtableCredentials(pat: "patXYZ.123", baseID: "appuVMh3KDfKw4OoQ"))
        let auth = AirtableAuthService(credentialsStore: store)
        let creds = try #require(try auth.storedCredentials())
        #expect(creds.pat == "patXYZ.123")
        #expect(creds.baseID == "appuVMh3KDfKw4OoQ")
    }
}

private final class MutableCredsStore: AirtableCredentialsStoring, @unchecked Sendable {
    var loaded: AirtableCredentials?
    init(initial: AirtableCredentials?) { self.loaded = initial }
    func store(_ credentials: AirtableCredentials) throws { loaded = credentials }
    func load() throws -> AirtableCredentials? { loaded }
    func clear() throws { loaded = nil }
}
