import Foundation
import MykilosKit

// MARK: - KundenBrain (L24)
// Read-only Verzeichnis der lokal synchronisierten Airtable-Kunden. Foundation-only,
// Sendable Value-Type (kein @Observable, kein GRDB, keine UI) — damit es aus der
// App-Schicht in die Services-Schicht gereicht und in MykilosServicesTests echt
// getestet werden kann. KEINE externe Verbindung: arbeitet nur auf einem Snapshot
// der bereits geladenen Registry-Daten ([Customer] + [Project] für Projektzählung).
//
// Trägt bewusst NUR Name + Kundennummer + Projektanzahl — `Customer` hat keine
// E-Mail/Telefon. Kontaktdetails bleiben bei `search_contacts` (Google People).
public struct KundenBrain: Sendable {
    public let customers: [Customer]
    public let projectsByCustomer: [String: Int]   // customerNumber → Projektanzahl

    public init(customers: [Customer], projects: [Project] = []) {
        self.customers = customers
        var counts: [String: Int] = [:]
        for p in projects { counts[p.customerNumber, default: 0] += 1 }
        self.projectsByCustomer = counts
    }

    /// Tokenisierte Fuzzy-Suche über Name und Kundennummer (gleiche Mechanik wie StudioBrain).
    public func lookup(_ query: String) -> [Customer] {
        let tokens = query.lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init).filter { $0.count >= 2 }
        guard tokens.isEmpty == false else { return [] }
        func matches(_ haystack: String) -> Bool {
            let h = haystack.lowercased()
            return tokens.contains { h.contains($0) }
        }
        return customers
            .filter { matches($0.name) || matches($0.customerNumber) }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
            .prefix(15)
            .map { $0 }
    }

    /// Kennzahl + Beispielnamen — Antwort auf eine leere/„Übersicht"-Anfrage.
    public var overview: String {
        let examples = customers
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
            .prefix(8).map(\.name)
        var out = ["Kunden-Verzeichnis (lokaler Airtable-Sync): \(customers.count) Kunden."]
        if examples.isEmpty == false { out.append("Beispiele: " + examples.joined(separator: ", ")) }
        return out.joined(separator: "\n")
    }

    public func describe(_ c: Customer) -> String {
        let n = projectsByCustomer[c.customerNumber] ?? 0
        var parts = ["• \(c.name)", "· Kundennr. \(c.customerNumber)"]
        if n > 0 { parts.append("· \(n) Projekt\(n == 1 ? "" : "e")") }
        return parts.joined(separator: " ")
    }
}
