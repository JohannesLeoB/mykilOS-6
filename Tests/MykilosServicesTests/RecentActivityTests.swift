import Testing
import Foundation
import MykilosKit
@testable import MykilosServices

// MARK: - RecentActivityFeed (L28)

struct RecentActivityTests {
    private func t(_ s: TimeInterval) -> Date { Date(timeIntervalSince1970: s) }

    @Test func mergtUndSortiertNeuesteZuerst() {
        let handshakes = [
            DataFlowEntry(timestamp: t(100), integrationID: "GMAIL_SEARCH", actorUserID: "a", action: .success, summary: "ok"),
            DataFlowEntry(timestamp: t(300), integrationID: "DRIVE_FILES_TAB", actorUserID: "a", action: .success, summary: "ok"),
        ]
        let audits = [AuditEntry(timestamp: t(200), actorUserID: "u", projectID: "P", action: .offerImported, summary: "imp")]
        let items = RecentActivityFeed.recent(handshakes: handshakes, audits: audits, limit: 8)
        #expect(items.count == 3)
        #expect(items.map(\.timestamp) == [t(300), t(200), t(100)])
    }

    @Test func respektiertLimitUndNimmtNeueste() {
        let handshakes = (0..<20).map {
            DataFlowEntry(timestamp: t(Double($0)), integrationID: "X\($0)", actorUserID: "a", action: .success, summary: "s")
        }
        let items = RecentActivityFeed.recent(handshakes: handshakes, audits: [], limit: 8)
        #expect(items.count == 8)
        #expect(items.first?.timestamp == t(19))   // neueste zuerst
    }

    @Test func fehlerHandshakeWirdMarkiert() {
        let h = [DataFlowEntry(integrationID: "AIRTABLE", actorUserID: "a", action: .error,
                               errorMessage: "boom", summary: "fail")]
        let items = RecentActivityFeed.recent(handshakes: h, audits: [], limit: 8)
        #expect(items.first?.isError == true)
        #expect(items.first?.detail == "boom")
    }

    @Test func auditTitelSindDeutsch() {
        let a = [AuditEntry(actorUserID: "u", projectID: "P", action: .estimateAdjusted, summary: "s")]
        let items = RecentActivityFeed.recent(handshakes: [], audits: a, limit: 8)
        #expect(items.first?.title == "Schätzung angepasst")
        #expect(items.first?.source == .audit)
    }

    @Test func leereEingabenErgebenLeer() {
        #expect(RecentActivityFeed.recent(handshakes: [], audits: [], limit: 8).isEmpty)
    }
}

// MARK: - Cold-Start (L29): die Feed-Quellen überleben den Neustart
@MainActor
struct RecentActivityColdStartTests {
    @Test func feedUeberlebtNeustart() throws {
        let db = try GRDBDatabase.inMemory()

        let logger = DataFlowLogger(db: db)
        try logger.load()
        try logger.append(DataFlowEntry(integrationID: "GMAIL_SEARCH", actorUserID: "a",
                                        action: .success, summary: "ok"))
        let audit = AuditStore(db: db)
        try audit.append(AuditEntry(actorUserID: "u", projectID: "P",
                                    action: .offerImported, summary: "imp"))

        // Frische Instanzen auf derselben DB → laden → Feed sieht beide Quellen.
        let logger2 = DataFlowLogger(db: db); try logger2.load()
        let audit2 = AuditStore(db: db); try audit2.load()
        let items = RecentActivityFeed.recent(handshakes: logger2.entries, audits: audit2.entries, limit: 8)

        #expect(items.count == 2)
        #expect(items.contains { $0.source == .handshake })
        #expect(items.contains { $0.source == .audit })
    }
}
