import Foundation
import MykilosKalkulationsCore

// MARK: - DeviceCatalog
// Optionaler Geräte-/Beschlag-Preisbuch-Lookup für den "mit Geräten"-Scope, den der
// evidenzbasierte Schätzer bewusst ausklammert. Quelle ist das reale MYKILOS-Preisbuch
// (Hersteller, Kategorie, Netto-EK, Netto-VK-MYKILOS …) mit ~13k Artikeln.
//
// DATENSICHERHEIT: Die Rohdatei enthält echte Lieferanten-/Einkaufspreise und wird
// NIEMALS ins Repository eingecheckt. Sie liegt außerhalb des Projekts in Application
// Support (siehe defaultURL) und wird zur Laufzeit geladen. `import-devices` kopiert eine
// vom Nutzer gewählte CSV genau dorthin; das Bundle bleibt frei von Preisbuch-Daten.

public struct DeviceCatalogEntry: Sendable, Equatable {
    public let manufacturer: String
    public let category: String
    public let description: String
    public let articleNumber: String
    public let listNet: Decimal?
    public let purchaseNet: Decimal?
    public let mykilosNet: Decimal?

    /// Normalisierter Suchindex (klein geschrieben), aus Suchtext + Feldern.
    public let haystack: String

    /// Bester verfügbarer Verkaufspreis (MYKILOS vor Liste).
    public var sellNet: Decimal? { mykilosNet ?? listNet }

    /// Zubehör/Ersatzteil — bei der Suche hinter Hauptgeräte gereiht, damit nicht eine 17 €-Rosette
    /// vor dem eigentlichen Gerät landet.
    public var isAccessory: Bool {
        let c = category.lowercased()
        return c.contains("zubehör") || c.contains("zubehoer") || c.contains("ersatzteil") || c.contains("filter")
    }
}

public final class DeviceCatalog {
    public let entries: [DeviceCatalogEntry]
    public init(entries: [DeviceCatalogEntry]) { self.entries = entries }

    public convenience init(csv: String) throws {
        let table = try CSVTable(data: csv, lenient: true)
        // Spaltennamen tolerant auflösen (Reihenfolge/Schreibweise kann variieren).
        let h = table.headers
        func col(_ needles: [String]) -> String? {
            for needle in needles {
                if let match = h.first(where: { $0.lowercased().contains(needle) }) { return match }
            }
            return nil
        }
        let cManu = col(["hersteller", "manufacturer", "marke"])
        let cCat = col(["kategorie", "category"])
        let cDesc = col(["artikelbeschreibung", "beschreibung", "description", "artikel"])
        let cArt = col(["artikelnummer", "artikel-nr", "article", "sku"])
        let cList = col(["liste"])
        let cEk = col(["einkauf", "netto-ek", "ek "])
        let cMyk = col(["mykilos"])
        let cSearch = col(["suchtext", "search"])

        let parsed: [DeviceCatalogEntry] = table.rows.compactMap { row in
            func v(_ key: String?) -> String { key.map { row.string($0) } ?? "" }
            func d(_ key: String?) -> Decimal? { key.flatMap { row.optionalDecimal($0) } }
            let manu = v(cManu), cat = v(cCat), desc = v(cDesc), art = v(cArt)
            // Leere Zeilen (kein Name irgendwo) überspringen.
            if manu.isEmpty && cat.isEmpty && desc.isEmpty && art.isEmpty { return nil }
            let haystack = [v(cSearch), manu, cat, desc, art]
                .filter { !$0.isEmpty }.joined(separator: " ").lowercased()
            return DeviceCatalogEntry(
                manufacturer: manu, category: cat, description: desc, articleNumber: art,
                listNet: d(cList), purchaseNet: d(cEk), mykilosNet: d(cMyk), haystack: haystack
            )
        }
        self.init(entries: parsed)
    }

    public convenience init(url: URL) throws {
        try self.init(csv: String(contentsOf: url, encoding: .utf8))
    }

    /// Externer Speicherort außerhalb des Repos (Application Support). Niemals im Bundle.
    public static func defaultURL() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return support
            .appendingPathComponent("MYKILOS/Kalkulationslabor/Devices", isDirectory: true)
            .appendingPathComponent("catalog.csv")
    }

    /// Lädt den Katalog vom Standardort, falls vorhanden (sonst nil — der Lookup ist optional).
    public static func loadDefault() -> DeviceCatalog? {
        let url = defaultURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try? DeviceCatalog(url: url)
    }

    /// Kopiert eine vom Nutzer gewählte CSV an den Standardort (außerhalb des Repos) und gibt
    /// den geladenen Katalog zurück. Überschreibt eine vorhandene Datei bewusst (neuer Preisstand).
    @discardableResult
    public static func importCatalog(from source: URL) throws -> DeviceCatalog {
        let target = defaultURL()
        try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: target.path) {
            try FileManager.default.removeItem(at: target)
        }
        try FileManager.default.copyItem(at: source, to: target)
        return try DeviceCatalog(url: target)
    }

    /// Token-Score-Suche: je Query-Token, das im Suchindex vorkommt, +1; Treffer nach Score,
    /// dann nach günstigstem MYKILOS-Verkaufspreis sortiert.
    public func search(_ query: String, limit: Int = 12) -> [DeviceCatalogEntry] {
        let tokens = query.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init).filter { $0.count > 1 }
        guard !tokens.isEmpty else { return [] }
        let scored = entries.compactMap { entry -> (DeviceCatalogEntry, Int)? in
            let score = tokens.reduce(0) { $0 + (entry.haystack.contains($1) ? 1 : 0) }
            return score > 0 ? (entry, score) : nil
        }
        return scored.sorted { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
            if lhs.0.isAccessory != rhs.0.isAccessory { return !lhs.0.isAccessory }  // Hauptgeräte vor Zubehör
            let lp = lhs.0.sellNet ?? Decimal.greatestFiniteMagnitude
            let rp = rhs.0.sellNet ?? Decimal.greatestFiniteMagnitude
            return lp < rp
        }.prefix(limit).map(\.0)
    }
}
