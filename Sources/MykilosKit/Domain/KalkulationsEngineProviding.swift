import Foundation

// MARK: - KalkulationsEngineProviding
// Schnittstelle zwischen mykilOS 6 und der integrierten Kalkulationsengine.
// Ermöglicht testbare Integration ohne Import der konkreten Implementierung.
public protocol KalkulationsEngineProviding: AnyObject, Sendable {
    func schaetze(projektID: String, freitext: String) async throws -> KostenSchaetzung
    func geraetepreis(suchbegriff: String) async -> Double?
    func importPDF(driveFileID: String, projektID: String) async throws
    func recordAdjustment(schaetzungsID: UUID, faktor: Double, grund: String) async throws
}

// MARK: - KostenSchaetzung

public struct KostenSchaetzung: Sendable {
    public let projektID: String
    public let minNetto: Double
    public let maxNetto: Double
    public let mitteNetto: Double
    public let confidence: Double
    public let evidenceCount: Int
    public let kostenboden: Double
    public let kostenbodenRatio: Double
    public let topEvidences: [PriceEvidence]

    public init(
        projektID: String,
        minNetto: Double,
        maxNetto: Double,
        mitteNetto: Double,
        confidence: Double,
        evidenceCount: Int,
        kostenboden: Double,
        kostenbodenRatio: Double,
        topEvidences: [PriceEvidence]
    ) {
        self.projektID = projektID
        self.minNetto = minNetto
        self.maxNetto = maxNetto
        self.mitteNetto = mitteNetto
        self.confidence = confidence
        self.evidenceCount = evidenceCount
        self.kostenboden = kostenboden
        self.kostenbodenRatio = kostenbodenRatio
        self.topEvidences = topEvidences
    }
}

// MARK: - PriceEvidence

public struct PriceEvidence: Sendable {
    public let lieferant: String
    public let dokument: String
    public let seite: Int?
    public let originalZitat: String
    public let nettoPreis: Double

    public init(
        lieferant: String,
        dokument: String,
        seite: Int?,
        originalZitat: String,
        nettoPreis: Double
    ) {
        self.lieferant = lieferant
        self.dokument = dokument
        self.seite = seite
        self.originalZitat = originalZitat
        self.nettoPreis = nettoPreis
    }
}
