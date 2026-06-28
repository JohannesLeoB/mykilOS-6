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
// Aktiv: `schaetze`. Bewusst noch Stubs (eigene Folgeschritte):
// - `geraetepreis`  → DeviceCatalog noch nicht portiert.
// - `importPDF`     → braucht `GoogleDriveClient.downloadFile`.
// - `recordAdjustment` → braucht persistierte Session + Reason/Target-Mapping
//   und den Bestätigungs-Flow (Action-Card → Audit).
//
// Actor: die mitgeführten Kern-Objekte (Estimator/Parser/LearningStore) sind nicht
// Sendable; die Actor-Isolation kapselt sie und passt zu den async-Protokollmethoden.
public actor KalkulationsEngine: KalkulationsEngineProviding {
    private let provider: PriceAnchorProviding
    private let learningStore: LearningStore
    private let parser = EstimateRequestParser()
    private let maxEvidences: Int

    public init(provider: PriceAnchorProviding, learningStore: LearningStore, maxEvidences: Int = 5) {
        self.provider = provider
        self.learningStore = learningStore
        self.maxEvidences = maxEvidences
    }

    public func schaetze(projektID: String, freitext: String) async throws -> KostenSchaetzung {
        let request = parser.parse(freitext)
        let estimator = EvidenceBasedEstimator(provider: provider, calibrationProvider: learningStore)
        let result = try estimator.estimate(request)
        return Self.map(result, projektID: projektID, maxEvidences: maxEvidences)
    }

    public func geraetepreis(suchbegriff: String) async -> Double? {
        nil
    }

    public func importPDF(driveFileID: String, projektID: String) async throws {
        throw KalkulationsEngineError.notYetImplemented(
            "PDF-Import (SHA256-Dedup) braucht GoogleDriveClient.downloadFile."
        )
    }

    public func recordAdjustment(schaetzungsID: String, faktor: Double, grund: String) async throws {
        throw KalkulationsEngineError.notYetImplemented(
            "recordAdjustment braucht persistierte Session + Reason/Target-Mapping über den Bestätigungs-Flow."
        )
    }

    // MARK: Mapping EstimateResult → KostenSchaetzung

    static func map(_ result: EstimateResult, projektID: String, maxEvidences: Int) -> KostenSchaetzung {
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
