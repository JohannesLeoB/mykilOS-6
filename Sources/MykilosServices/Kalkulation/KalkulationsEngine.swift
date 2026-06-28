import Foundation
import MykilosKit
import MykilosKalkulationsCore

// MARK: - KalkulationsEngineError

public enum KalkulationsEngineError: Error, CustomStringConvertible {
    /// Fähigkeit ist absichtlich noch nicht verdrahtet (braucht Infra aus einem späteren Schritt).
    case notYetImplemented(String)

    public var description: String {
        switch self {
        case .notYetImplemented(let detail): "Noch nicht implementiert: \(detail)"
        }
    }
}

// MARK: - KalkulationsEngine
// Adapter zwischen mykilOS 6 (`KalkulationsEngineProviding`) und dem portierten
// mykilO$$-Kern. `schaetze` ist der zweistufige Einstieg: `parse` (Semantik) →
// `estimate` (Preislogik) → Mapping `EstimateResult` → `KostenSchaetzung`.
//
// Aktiv: `schaetze` + `geraetepreis` (wenn ein DeviceCatalog injiziert ist;
// sonst nil — der Lookup ist optional) + `recordAdjustment` (persistiert die
// Anpassung im LearningStore und protokolliert sie als AuditEntry). Bewusst noch
// Stub (eigener Folgeschritt):
// - `importPDF`     → braucht `GoogleDriveClient.downloadFile`.
//
// Actor: die mitgeführten Kern-Objekte (Estimator/Parser/LearningStore) sind nicht
// Sendable; die Actor-Isolation kapselt sie und passt zu den async-Protokollmethoden.
public actor KalkulationsEngine: KalkulationsEngineProviding {
    private let provider: PriceAnchorProviding
    private let learningStore: LearningStore
    private let deviceCatalog: DeviceCatalog?
    private let auditStore: AuditStore?
    private let parser = EstimateRequestParser()
    private let maxEvidences: Int

    // Merkt sich je persistierter Schätzung das Projekt, gegen das geschätzt wurde.
    // `recordAdjustment` kennt nur die `schaetzungsID`, der AuditEntry braucht aber
    // ein `projectID`. Innerhalb einer Sitzung läuft schaetze → recordAdjustment
    // sequenziell, daher genügt eine In-Memory-Map (kein Persistenzbedarf).
    private var projektIDBySession: [String: String] = [:]

    public init(
        provider: PriceAnchorProviding,
        learningStore: LearningStore,
        deviceCatalog: DeviceCatalog? = nil,
        auditStore: AuditStore? = nil,
        maxEvidences: Int = 5
    ) {
        self.provider = provider
        self.learningStore = learningStore
        self.deviceCatalog = deviceCatalog
        self.auditStore = auditStore
        self.maxEvidences = maxEvidences
    }

    public func schaetze(projektID: String, freitext: String) async throws -> KostenSchaetzung {
        let request = parser.parse(freitext)
        let estimator = EvidenceBasedEstimator(provider: provider, calibrationProvider: learningStore)
        let result = try estimator.estimate(request)
        // Session persistieren — liefert die stabile `schaetzungsID`, gegen die
        // später eine Anpassung gebucht werden kann (append-only im LearningStore).
        let session = try learningStore.saveSession(from: result)
        projektIDBySession[session.id] = projektID
        return Self.map(result, schaetzungsID: session.id, projektID: projektID, maxEvidences: maxEvidences)
    }

    public func geraetepreis(suchbegriff: String) async -> Double? {
        guard let deviceCatalog else { return nil }
        guard let best = deviceCatalog.search(suchbegriff, limit: 1).first,
              let preis = best.sellNet else { return nil }
        return Self.double(preis)
    }

    public func importPDF(driveFileID: String, projektID: String) async throws {
        throw KalkulationsEngineError.notYetImplemented(
            "PDF-Import (SHA256-Dedup) braucht GoogleDriveClient.downloadFile."
        )
    }

    public func recordAdjustment(schaetzungsID: String, faktor: Double, grund: String) async throws {
        // `faktor` ist ein Multiplikator um 1.0 (0.8 = 20 % günstiger). Der
        // LearningStore rechnet intern mit Prozent-Delta.
        let percentDelta = (faktor - 1) * 100
        // Manuelle Freitext-Anpassung → Bauchgefühl (niedriges Reliability-Gewicht),
        // Gesamtschätzung, `grund` als Notiz. `learn: false` — eine einzelne manuelle
        // Anpassung darf den Kalibrierungs-Kandidaten nicht automatisch verändern.
        _ = try learningStore.appendAdjustment(
            sessionID: schaetzungsID,
            percentDelta: percentDelta,
            euroDelta: nil,
            reason: .gutFeeling,
            target: .wholeEstimate,
            learn: false,
            note: grund
        )

        // Audit: gleiche Semantik wie bestätigte Assistant-Actions — sichtbar,
        // persistent, nachvollziehbar. Ohne injizierten AuditStore (z. B. in
        // reinen Engine-Unit-Tests) wird die Anpassung dennoch persistiert.
        guard let auditStore else { return }
        let projektID = projektIDBySession[schaetzungsID] ?? schaetzungsID
        let prozent = abs(percentDelta).rounded()
        let richtung = percentDelta >= 0 ? "höher" : "günstiger"
        let summary = "Schätzung \(Int(prozent)) % \(richtung) angepasst (\(grund))"
        let entry = AuditEntry(
            actorUserID: "local-user",
            projectID: projektID,
            action: .estimateAdjusted,
            summary: summary
        )
        try await auditStore.append(entry)
    }

    // MARK: Mapping EstimateResult → KostenSchaetzung

    static func map(_ result: EstimateResult, schaetzungsID: String, projektID: String, maxEvidences: Int) -> KostenSchaetzung {
        let mitte = double(result.totalBand.expected)
        let kostenboden = double(result.bottomUpCost?.total ?? 0)
        let topEvidences = result.evidence.prefix(maxEvidences).map { evidence in
            PriceEvidence(
                lieferant: evidence.supplier,
                dokument: evidence.sourceFile,
                seite: evidence.page,
                originalZitat: evidence.quote,
                nettoPreis: double(evidence.netPrice)
            )
        }
        return KostenSchaetzung(
            schaetzungsID: schaetzungsID,
            projektID: projektID,
            minNetto: double(result.totalBand.low),
            maxNetto: double(result.totalBand.high),
            mitteNetto: mitte,
            confidence: result.confidence,
            evidenceCount: result.evidence.count,
            kostenboden: kostenboden,
            kostenbodenRatio: mitte > 0 ? kostenboden / mitte : 0,
            topEvidences: Array(topEvidences)
        )
    }

    private static func double(_ value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }
}
