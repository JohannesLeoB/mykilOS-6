import Testing
import Foundation
@testable import MykilosServices
import MykilosKalkulationsCore

// MARK: - KalkulationsLearningStore Cold-Start-Tests
// Beweist: Lern-/Kalibrierungsdaten überleben den App-Neustart.
// LearningStore schreibt append-only in eine eigene `learning.sqlite`
// (nicht in die Haupt-GRDB-Migration). Cold-Start ist hier der stärkste
// Beweis: eine ZWEITE Store-Instanz öffnet dieselbe Datei frisch von Platte.
struct KalkulationsLearningStoreTests {

    private func tempDir() throws -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mykilos-learning-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Minimale, gültige Schätzung — kein Seed/Estimator nötig, nur der Persistenz-Pfad.
    private func minimalResult() -> EstimateResult {
        let request = EstimateRequest(
            rawText: "Cold-Start Test",
            components: [],
            materials: [],
            scope: ScopeFlags()
        )
        let band = PriceBand(low: 1000, expected: 1500, high: 2000, currency: "EUR")
        return EstimateResult(
            request: request,
            lines: [],
            totalBand: band,
            laborValue: 500,
            confidence: 0.5,
            evidence: [],
            dataGaps: [],
            excludedRisks: [],
            scopeNotes: []
        )
    }

    // MARK: Core: Lern-Daten überleben Neustart
    @Test func lernDatenUeberlebenNeustart() throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        // Session A: schreiben (Session + Adjustment, append-only)
        let storeA = LearningStore(directory: dir)
        let session = try storeA.saveSession(from: minimalResult())
        let adjustment = try storeA.appendAdjustment(
            sessionID: session.id,
            percentDelta: 10,
            euroDelta: nil,
            reason: .marketPrice,
            target: .wholeEstimate,
            learn: false
        )
        #expect(try storeA.estimateSessions().count == 1)
        #expect(try storeA.estimateAdjustments().count == 1)

        // "App neu gestartet": neue Store-Instanz, selbe learning.sqlite auf Platte
        let storeB = LearningStore(directory: dir)
        let sessionsB = try storeB.estimateSessions()
        let adjustmentsB = try storeB.estimateAdjustments()

        #expect(sessionsB.count == 1)
        #expect(adjustmentsB.count == 1)
        // Identisch — kein Datenverlust über den Neustart
        #expect(sessionsB.first?.id == session.id)
        #expect(sessionsB.first?.requestText == "Cold-Start Test")
        #expect(sessionsB.first?.baseMidNet == Decimal(1500))
        #expect(adjustmentsB.first?.id == adjustment.id)
        #expect(adjustmentsB.first?.adjustedMidNet == adjustment.adjustedMidNet)
    }

    // MARK: Append-only: zwei Adjustments = zwei physische Zeilen nach Neustart
    @Test func appendOnlyBleibtNachNeustartErhalten() throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let storeA = LearningStore(directory: dir)
        let session = try storeA.saveSession(from: minimalResult())
        _ = try storeA.appendAdjustment(sessionID: session.id, percentDelta: 8, euroDelta: nil,
                                        reason: .materialUnderestimated, target: .wholeEstimate, learn: false)
        _ = try storeA.appendAdjustment(sessionID: session.id, percentDelta: 6, euroDelta: nil,
                                        reason: .materialUnderestimated, target: .wholeEstimate, learn: false)

        let storeB = LearningStore(directory: dir)
        #expect(try storeB.estimateAdjustments().count == 2)
    }
}
