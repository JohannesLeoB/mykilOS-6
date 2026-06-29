import Foundation

// MARK: - ContactDraft (S9)
// Ein vom Assistenten vorgeschlagener neuer Kontakt. Das ist bewusst nur ein
// ENTWURF — er wird NIE automatisch geschrieben. Erst eine ausdrückliche
// Bestätigung über die Action-Card legt ihn via People API an (+ Audit-Eintrag).
public struct ContactDraft: Codable, Sendable, Equatable {
    public var givenName: String
    public var familyName: String?
    public var email: String?
    public var phone: String?
    public var organization: String?

    public init(givenName: String, familyName: String? = nil, email: String? = nil,
                phone: String? = nil, organization: String? = nil) {
        self.givenName = givenName
        self.familyName = familyName
        self.email = email
        self.phone = phone
        self.organization = organization
    }

    /// Anzeigename für Karten/Logs (z. B. „Sinem Cirnavuk").
    public var displayName: String {
        [givenName, familyName].compactMap { $0 }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.isEmpty == false }
            .joined(separator: " ")
    }
}

// MARK: - ContactCreateOutcome (S9)
// Ergebnis einer bestätigten Kontaktanlage. Die Bestätigungskarte zeigt darauf
// basierend „angelegt" (mit Anzeigename) oder eine Fehlermeldung. Bewusst kein
// `Result<…, Error>` (Karte muss Sendable bleiben, kein Error-Typ über Module).
public enum ContactCreateOutcome: Sendable, Equatable {
    case created(String)   // Anzeigename des angelegten Kontakts
    case failed(String)    // menschenlesbare Fehlermeldung
}
