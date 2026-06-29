import Testing
import Foundation
import MykilosKit
@testable import MykilosServices

// MARK: - TimelineMerger (L27)

struct TimelineMergerTests {

    private func file(_ id: String, _ name: String, _ mime: String, _ date: Date?) -> GoogleDriveFile {
        GoogleDriveFile(id: id, name: name, mimeType: mime, modifiedAt: date, webViewLink: "https://drive/\(id)")
    }

    private func t(_ s: TimeInterval) -> Date { Date(timeIntervalSince1970: s) }

    @Test func mergtAlleVierQuellenUndSortiertAbsteigend() {
        let drive = [file("d1", "Plan.pdf", "application/pdf", t(100))]
        let offers = OffersCollector.Result(
            incoming: [OfferDocumentClassifier.classify(
                file("o1", "202603971.pdf", "application/pdf", t(300)), isIncoming: true)],
            outgoing: [],
            incomingFolderFound: true, outgoingFolderFound: false)
        let events = [GoogleCalendarEvent(id: "c1", title: "Abnahme", startsAt: t(500), isAllDay: false, location: "Vor Ort")]
        let audits = [AuditEntry(actorUserID: "u", projectID: "P", action: .offerImported, summary: "Import")]
        // Audit timestamp = jetzt (großer Wert) → vorne. Setze deterministisch:
        let audit = AuditEntry(timestamp: t(400), actorUserID: "u", projectID: "P",
                               action: .estimateAdjusted, summary: "Schätzung")
        _ = audits

        let items = TimelineMerger.merge(driveFiles: drive, offers: offers,
                                         calendarEvents: events, auditEntries: [audit])
        #expect(items.count == 4)
        // absteigend nach Datum: 500 (cal) > 400 (audit) > 300 (offer) > 100 (drive)
        #expect(items.map(\.date) == [t(500), t(400), t(300), t(100)])
        #expect(items.first?.source == .calendar)
        #expect(items.last?.source == .drive)
    }

    @Test func ueberspringtOrdnerUndDatumsloseEintraege() {
        let drive = [
            file("folder", "05 eingehende", "application/vnd.google-apps.folder", t(900)),  // Ordner → raus
            file("d2", "ohnedatum.pdf", "application/pdf", nil),                              // nil-Datum → raus
            file("d3", "gut.pdf", "application/pdf", t(50)),
        ]
        let offers = OffersCollector.Result(incoming: [], outgoing: [], incomingFolderFound: false, outgoingFolderFound: false)
        let events = [GoogleCalendarEvent(id: "c", title: "X", startsAt: nil, isAllDay: false, location: nil)]  // nil → raus
        let items = TimelineMerger.merge(driveFiles: drive, offers: offers, calendarEvents: events, auditEntries: [])
        #expect(items.count == 1)
        #expect(items.first?.id == "drive:d3")
    }

    @Test func entdoppeltDriveGegenAngebotAngebotGewinnt() {
        // Dieselbe Datei-ID taucht als Drive-Datei UND als Angebot auf → genau einmal, Quelle .offer.
        let shared = file("x1", "AN_2026-0001.pdf", "application/pdf", t(200))
        let drive = [shared]
        let offers = OffersCollector.Result(
            incoming: [], outgoing: [OfferDocumentClassifier.classify(shared, isIncoming: false, folderName: "Angebot")],
            incomingFolderFound: false, outgoingFolderFound: true)
        let items = TimelineMerger.merge(driveFiles: drive, offers: offers, calendarEvents: [], auditEntries: [])
        #expect(items.count == 1)
        #expect(items.first?.source == .offer)
        #expect(items.first?.id == "offer:x1")
    }

    @Test func stabileQuellenPraefixIDs() {
        let drive = [file("d", "f.pdf", "application/pdf", t(10))]
        let audit = AuditEntry(timestamp: t(20), actorUserID: "u", projectID: "P", action: .noteUpdated, summary: "x")
        let items = TimelineMerger.merge(
            driveFiles: drive,
            offers: .init(incoming: [], outgoing: [], incomingFolderFound: false, outgoingFolderFound: false),
            calendarEvents: [GoogleCalendarEvent(id: "e", title: "T", startsAt: t(30), isAllDay: false, location: nil)],
            auditEntries: [audit])
        let ids = items.map(\.id)
        #expect(ids.contains("drive:d"))
        #expect(ids.contains("cal:e"))
        #expect(ids.contains { $0.hasPrefix("audit:") })
    }

    @Test func auditActionLabels() {
        #expect(AuditEntry.Action.estimateAdjusted.timelineLabel == "Schätzung angepasst")
        #expect(AuditEntry.Action.offerImported.timelineLabel == "Angebot importiert")
        #expect(AuditEntry.Action.calibrationPromoted.timelineLabel == "Kalibrierung übernommen")
    }
}
