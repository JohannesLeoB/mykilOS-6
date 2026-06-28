import Testing
import Foundation
@testable import MykilosServices
import MykilosKit
import MykilosKalkulationsCore

// MARK: - KalkulationsEngine Adapter-Tests
// Testet den Adapter selbst (parse → estimate → Mapping), nicht die Preislogik des
// Kerns (die ist in MykilosKalkulationsCoreTests + den deferred Integrationstests).
// Stub-Provider ohne Anker hält den Test deterministisch und seed-frei.
struct KalkulationsEngineTests {

    /// Anker-Provider ohne Daten — deterministisch, keine externen Seed-Dateien nötig.
    private struct StubAnchorProvider: PriceAnchorProviding {
        func activeAnchors() throws -> [CandidateReleaseDecision] { [] }
    }

    private func tempStore() throws -> LearningStore {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("mykilos-engine-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return LearningStore(directory: dir)
    }

    @Test func schaetzeLiefertGemappteKostenSchaetzung() async throws {
        let engine = KalkulationsEngine(provider: StubAnchorProvider(), learningStore: try tempStore())

        let schaetzung = try await engine.schaetze(
            projektID: "P-1",
            freitext: "5 laufmeter unterschränke mit linoleumfronten. 15 eichenschubkästen."
        )

        // Mapping korrekt verdrahtet
        #expect(schaetzung.projektID == "P-1")
        // Ohne Anker: keine Evidenzen, aber kein Crash
        #expect(schaetzung.evidenceCount == 0)
        #expect(schaetzung.topEvidences.isEmpty)
        // Div-by-Zero-Guard: mitte == 0 → ratio == 0 (nicht inf/NaN)
        #expect(schaetzung.kostenbodenRatio.isFinite)
        #expect(schaetzung.kostenboden >= 0)
        #expect(schaetzung.minNetto <= schaetzung.maxNetto)
    }

    @Test func nochNichtVerdrahteteFaehigkeitenWerfenKlar() async throws {
        let engine = KalkulationsEngine(provider: StubAnchorProvider(), learningStore: try tempStore())

        await #expect(throws: KalkulationsEngineError.self) {
            try await engine.importPDF(driveFileID: "x", projektID: "P-1")
        }
        await #expect(throws: KalkulationsEngineError.self) {
            try await engine.recordAdjustment(schaetzungsID: "s-1", faktor: 1.1, grund: "Test")
        }
        let preis = await engine.geraetepreis(suchbegriff: "spüle")
        #expect(preis == nil)
    }
}
