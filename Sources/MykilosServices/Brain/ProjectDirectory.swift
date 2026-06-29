import Foundation
import MykilosKit

// MARK: - ProjectDirectory (S2)
// Foundation-only Snapshot: Projekt (Nummer/Titel/Kunde) → Drive-Ordner-ID. Erlaubt
// dem Assistenten, im GLOBALEN Chat (ohne fokussiertes Projekt) ein per Freitext
// genanntes Projekt aufzulösen ("such Angebote zu Zitscher") und dessen Drive-Ordner
// an OffersCollector zu geben. Read-only, kein Netzwerk.
public struct ProjectDirectory: Sendable {
    public struct Entry: Sendable, Equatable {
        public let projectNumber: String
        public let title: String
        public let customerName: String?
        public let driveFolderID: String?
        public init(projectNumber: String, title: String, customerName: String?, driveFolderID: String?) {
            self.projectNumber = projectNumber; self.title = title
            self.customerName = customerName; self.driveFolderID = driveFolderID
        }
    }

    public let entries: [Entry]

    public init(entries: [Entry]) { self.entries = entries }

    public init(projects: [Project], customers: [Customer]) {
        let nameByNumber = Dictionary(customers.map { ($0.customerNumber, $0.name) },
                                      uniquingKeysWith: { a, _ in a })
        self.entries = projects.map { p in
            Entry(projectNumber: p.projectNumber, title: p.title,
                  customerName: nameByNumber[p.customerNumber], driveFolderID: p.links.driveFolderID)
        }
    }

    /// Bestes Projekt für eine Freitext-Anfrage: exakte Projektnummer zuerst, sonst
    /// Teilstring in Nummer/Titel/Kundenname.
    public func resolve(_ query: String) -> Entry? {
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.isEmpty == false else { return nil }
        if let exact = entries.first(where: { $0.projectNumber.lowercased() == q }) { return exact }
        return entries.first { e in
            e.projectNumber.lowercased().contains(q)
                || e.title.lowercased().contains(q)
                || (e.customerName?.lowercased().contains(q) ?? false)
        }
    }
}
