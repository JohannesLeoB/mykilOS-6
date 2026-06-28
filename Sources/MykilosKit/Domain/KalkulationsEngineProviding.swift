import Foundation

// MARK: - KalkulationsEngineProviding
// Schnittstelle zwischen mykilOS 6 und der integrierten Kalkulationsengine.
// Ermöglicht testbare Integration ohne Import der konkreten Implementierung.
//
// Herkunft: übernommen aus PR #1 (claude/musing-sammet) auf die kanonische Basis
// `stabilize`. Einzige Änderung gegenüber PR #1: `recordAdjustment(schaetzungsID:)`
// ist `String` statt `UUID` — der stabile Schlüssel ist `EstimateSession.id`
// (`UUID().uuidString`, persistiert als String in der LearningDatabase), nie
// `EstimateLine.id`. Vermeidet fragiles UUID-Parsing.
public protocol KalkulationsEngineProviding: AnyObject, Sendable {
    func schaetze(projektID: String, freitext: String) async throws -> KostenSchaetzung
    func geraetepreis(suchbegriff: String) async -> Double?
    func importPDF(driveFileID: String, projektID: String) async throws
    /// Bucht eine Anpassung gegen eine Schätzung. `lernen: true` lässt sie in die
    /// Kalibrierungs-Kandidaten einfließen (Lern-Loop); `false` ist eine reine
    /// Einzelkorrektur. Kein Default am Protokoll — Bequemlichkeit über die Extension.
    func recordAdjustment(schaetzungsID: String, faktor: Double, grund: String, lernen: Bool) async throws
    /// Aktueller Lern-Stand (aktive Faktoren, promotebare Kandidaten, Zähler) als
    /// reine Value-Types — kein Core-Typ leakt ins Widget.
    func lernUebersicht() async throws -> KalkulationsLernStand
    /// Promotet einen Kalibrierungs-Kandidaten zu einem aktiven Faktor. Künftige
    /// Schätzungen verschieben sich entsprechend. Protokolliert als AuditEntry.
    func promote(candidateID: String) async throws
}

public extension KalkulationsEngineProviding {
    /// Bequemlichkeits-Overload: Einzelkorrektur ohne Lernen (Status quo Schritt 7).
    /// Hält bestehende 3-Argument-Aufrufer (Tests, alte Call-Sites) quellkompatibel.
    func recordAdjustment(schaetzungsID: String, faktor: Double, grund: String) async throws {
        try await recordAdjustment(schaetzungsID: schaetzungsID, faktor: faktor, grund: grund, lernen: false)
    }
}

// MARK: - KostenSchaetzung

public struct KostenSchaetzung: Sendable {
    /// Stabile ID der persistierten `EstimateSession` (LearningStore). Referenz für
    /// `recordAdjustment` — eine Anpassung wird immer gegen genau diese Schätzung gebucht.
    public let schaetzungsID: String
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
        schaetzungsID: String,
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
        self.schaetzungsID = schaetzungsID
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

// MARK: - KalkulationsLernStand
// Sichtbarer Stand des Lern-Loops, gemappt aus der Kern-`LearningSummary`. Bewusst
// reine Value-Types in MykilosKit: das Widget sieht nie `CalibrationFactorCandidate`
// & Co. aus MykilosKalkulationsCore (das es nicht importieren darf).

public struct KalkulationsLernStand: Sendable, Equatable {
    public let sessions: Int
    public let adjustments: Int
    public let outliers: Int
    public let aktiveFaktoren: [KalkulationsFaktor]
    public let kandidaten: [KalkulationsKandidat]

    public init(
        sessions: Int,
        adjustments: Int,
        outliers: Int,
        aktiveFaktoren: [KalkulationsFaktor],
        kandidaten: [KalkulationsKandidat]
    ) {
        self.sessions = sessions
        self.adjustments = adjustments
        self.outliers = outliers
        self.aktiveFaktoren = aktiveFaktoren
        self.kandidaten = kandidaten
    }

    /// Nichts gelernt und nichts in Sicht — der Leerzustand der Sektion.
    public var istLeer: Bool { aktiveFaktoren.isEmpty && kandidaten.isEmpty }
}

/// Ein aktiver Kalibrierungsfaktor — verschiebt künftige Schätzungen messbar.
public struct KalkulationsFaktor: Sendable, Equatable, Identifiable {
    public let id: String
    public let grundLabel: String
    public let zielLabel: String
    public let prozent: Double
    public let sampleCount: Int

    public init(id: String, grundLabel: String, zielLabel: String, prozent: Double, sampleCount: Int) {
        self.id = id
        self.grundLabel = grundLabel
        self.zielLabel = zielLabel
        self.prozent = prozent
        self.sampleCount = sampleCount
    }
}

/// Ein noch nicht übernommener Kandidat — der Nutzer kann ihn bewusst promoten.
public struct KalkulationsKandidat: Sendable, Equatable, Identifiable {
    public let id: String
    public let grundLabel: String
    public let zielLabel: String
    public let prozent: Double
    public let sampleCount: Int
    public let statusLabel: String

    public init(id: String, grundLabel: String, zielLabel: String, prozent: Double, sampleCount: Int, statusLabel: String) {
        self.id = id
        self.grundLabel = grundLabel
        self.zielLabel = zielLabel
        self.prozent = prozent
        self.sampleCount = sampleCount
        self.statusLabel = statusLabel
    }
}
