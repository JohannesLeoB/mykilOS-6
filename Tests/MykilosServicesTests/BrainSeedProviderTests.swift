import Testing
import Foundation
@testable import MykilosServices
import MykilosKalkulationsCore

// MARK: - BrainSeedProvider Tests
// GATE L1: Inline-CSV → Anker mit Klasse/Preis/„eiche" geladen;
// DoT: KalkulationsEngine mit Fixture → mittleNetto > 0 für Eichenküche.
struct BrainSeedProviderTests {

    // Minimale aber realistische CSV mit einem Eichen-Anker
    private static let fixtureCSV = """
candidate_id,price_net,superseded_by_candidate,materials,dimension_raw,original_text,component_class,document,page_start,supplier,project,doc_type,confidence,risk_flags,scope_json,status
eiche-001,8500.00,,Eiche massiv,5.0m,5m Eichenholzküche massiv,kitchen_run,angebot.pdf,1,HolzFirma,2025-001,angebot,0.82,,{},release_candidate
eiche-002,9200.00,,Eiche furniert,4.5m,4.5m Küche Eiche furniert Küchenzeile,kitchen_run,angebot2.pdf,2,KüchenProfi,2025-002,angebot,0.78,,{},release_candidate
eiche-003,12000.00,,Eiche natur,6.0m,6m Massivholzküche Eiche natur,kitchen_run,angebot3.pdf,1,TischlerGmbH,2025-003,angebot,0.85,,{},release_candidate
"""

    private func tempCSV(_ content: String) throws -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("brain-seed-test-\(UUID().uuidString).csv")
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    @Test("anchor(from:) parst Eichen-CSV-Zeile korrekt")
    func anchorParserEiche() throws {
        let row: [String: String] = [
            "candidate_id": "eiche-001",
            "price_net": "8500.00",
            "superseded_by_candidate": "",
            "materials": "Eiche massiv",
            "dimension_raw": "5.0m",
            "original_text": "5m Eichenholzküche",
            "component_class": "kitchen_run",
            "document": "angebot.pdf",
            "page_start": "1",
            "supplier": "HolzFirma",
            "project": "2025-001",
            "doc_type": "angebot",
            "confidence": "0.82",
            "risk_flags": "",
            "scope_json": "{}",
            "status": "release_candidate"
        ]
        let anchor = try #require(BrainSeedProvider.anchor(from: row))
        #expect(anchor.candidateID == "eiche-001")
        #expect(anchor.priceNetGuess == Decimal(string: "8500.00"))
        #expect(anchor.componentClass == .kitchenRun)
        #expect(anchor.title.localizedCaseInsensitiveContains("eiche") ||
                anchor.title.localizedCaseInsensitiveContains("küche") ||
                anchor.title.localizedCaseInsensitiveContains("massiv"))
    }

    @Test("anchor(from:) ignoriert Zeile ohne Preis")
    func anchorIgnoriertKeinPreis() {
        let row: [String: String] = [
            "candidate_id": "test-no-price",
            "price_net": "0",
            "superseded_by_candidate": "",
            "materials": "Eiche"
        ]
        #expect(BrainSeedProvider.anchor(from: row) == nil)
    }

    @Test("anchor(from:) ignoriert veraltete Einträge")
    func anchorIgnoriertSuperseded() {
        let row: [String: String] = [
            "candidate_id": "alt-001",
            "price_net": "5000.00",
            "superseded_by_candidate": "neu-001",
            "materials": "Eiche"
        ]
        #expect(BrainSeedProvider.anchor(from: row) == nil)
    }

    @Test("BrainSeedProvider lädt Anker aus Inline-CSV")
    func laeadtAnkerAusCSV() throws {
        let csvURL = try tempCSV(Self.fixtureCSV)
        defer { try? FileManager.default.removeItem(at: csvURL) }

        let provider = BrainSeedProvider(csvURL: csvURL, fallback: BaselineAnchorProvider())
        #expect(provider.isCorpusAvailable)
        let anchors = try provider.activeAnchors()
        #expect(anchors.count == 3)
        #expect(anchors.allSatisfy { $0.priceNetGuess > 0 })
        let eicheAnker = anchors.filter {
            $0.title.localizedCaseInsensitiveContains("eiche") ||
            $0.component.localizedCaseInsensitiveContains("eiche")
        }
        #expect(eicheAnker.isEmpty == false)
    }

    @Test("BrainSeedProvider fällt auf BaselineAnchors zurück wenn CSV fehlt")
    func fallbackWennCSVFehlt() throws {
        let missing = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("nonexistent-\(UUID().uuidString).csv")
        let provider = BrainSeedProvider(csvURL: missing, fallback: BaselineAnchorProvider())
        #expect(provider.isCorpusAvailable == false)
        let anchors = try provider.activeAnchors()
        // Baseline hat mindestens 1 Anker
        #expect(anchors.isEmpty == false)
    }

    @Test("Smoke: KalkulationsEngine mit Fixture-Korpus liefert > 0 für Eichenküche")
    func smokeEichenkuecheGibtPreis() async throws {
        let csvURL = try tempCSV(Self.fixtureCSV)
        defer { try? FileManager.default.removeItem(at: csvURL) }

        let provider = BrainSeedProvider(csvURL: csvURL, fallback: BaselineAnchorProvider())
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("brain-engine-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let engine = KalkulationsEngine(
            provider: provider,
            learningStore: LearningStore(directory: tempDir),
            deviceCatalog: nil,
            auditStore: nil
        )
        let schaetzung = try await engine.schaetze(projektID: "test-001", freitext: "5m Eichenküche")
        #expect(schaetzung.mitteNetto > 0)
    }
}
