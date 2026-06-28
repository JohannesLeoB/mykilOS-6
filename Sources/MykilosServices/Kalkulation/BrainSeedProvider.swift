import Foundation
import MykilosKalkulationsCore

// MARK: - BrainSeedProvider
// Lädt die ECHTEN Preis-Anker aus dem destillierten Korpus
// (~/Library/Application Support/MYKILOS/Kalkulationslabor/Brain/active_price_anchors.csv,
// ~200 release-fertige Anker aus realen Lieferanten-PDFs). Damit liefert `schaetze`
// echte Zahlen statt der 6 konservativen Regelanker.
//
// Datenschutz: die CSV enthält reale Einkaufspreise → NIE ins Repo gebündelt.
// Sie liegt nur lokal in Application Support. Fehlt sie, fällt der Provider
// transparent auf die hartcodierten BaselineAnchors zurück (App bleibt funktional).
public struct BrainSeedProvider: PriceAnchorProviding {
    private let csvURL: URL
    private let fallback: PriceAnchorProviding

    public init(csvURL: URL? = nil, fallback: PriceAnchorProviding = BaselineAnchorProvider()) {
        self.csvURL = csvURL ?? BrainSeedProvider.defaultURL
        self.fallback = fallback
    }

    /// Standardpfad des destillierten Anker-Korpus.
    public static var defaultURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return appSupport
            .appendingPathComponent("MYKILOS/Kalkulationslabor/Brain/active_price_anchors.csv")
    }

    public var isCorpusAvailable: Bool {
        FileManager.default.fileExists(atPath: csvURL.path)
    }

    public func activeAnchors() throws -> [CandidateReleaseDecision] {
        guard let raw = try? String(contentsOf: csvURL, encoding: .utf8) else {
            return try fallback.activeAnchors()
        }
        let table = try CSVTable(data: raw, lenient: true)
        let anchors = table.rows.compactMap(Self.anchor(from:))
        // Leerer/kaputter Korpus → lieber konservative Regelanker als gar keine.
        return anchors.isEmpty ? try fallback.activeAnchors() : anchors
    }

    // MARK: - Zeilen-Mapping

    static func anchor(from row: [String: String]) -> CandidateReleaseDecision? {
        let id = row.string("candidate_id")
        guard id.isEmpty == false else { return nil }
        let price = row.decimal("price_net")
        guard price > 0 else { return nil }                     // Anker ohne Preis sind nutzlos
        if row.string("superseded_by_candidate").isEmpty == false { return nil } // veraltete überspringen

        let materials   = row.string("materials")
        let dimension   = row.string("dimension_raw")
        let original    = row.string("original_text")
        let classRaw    = row.string("component_class")
        let componentClass = CalculationComponentClass(rawValue: classRaw)

        // Matchbarer Text: Klasse + Material + Dimension + Originalzitat. Der Estimator
        // scort Anker über genau diese Felder (z. B. „eiche", „60cm", „linoleum").
        let label = [componentClass?.displayName ?? classRaw, materials, dimension]
            .filter { $0.isEmpty == false }.joined(separator: " ")
        let status = row.string("status").isEmpty ? "release_candidate" : row.string("status")

        return CandidateReleaseDecision(
            candidateID: id,
            sourceFile: row.string("document"),
            page: row.int("page_start"),
            supplier: row.string("supplier"),
            project: row.string("project"),
            component: [materials, dimension].filter { !$0.isEmpty }.joined(separator: " "),
            trade: row.string("doc_type"),
            priceNetGuess: price,
            confidence: row.double("confidence"),
            duplicateCount: 0,
            currentStatus: status,
            proposedStatus: status,
            supersededBy: nil,
            decisionScore: row.double("confidence"),
            decisionReason: row.string("risk_flags"),
            helpNeeded: "",
            title: label.isEmpty ? "Anker \(id)" : label,
            evidenceQuote: original.isEmpty ? label : original,
            carryforwardRuleStatus: "",
            ruleSafePriceNet: nil,
            ruleNotes: row.string("scope_json"),
            componentClass: componentClass,
            sourceKind: .pdfOffer
        )
    }
}
