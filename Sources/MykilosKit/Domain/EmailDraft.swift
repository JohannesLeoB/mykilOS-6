import Foundation

// MARK: - EmailDraft (S14)
// Ein vom Assistenten vorgeschlagener Mail-Entwurf. Wird NIE automatisch geschrieben
// und NIE versendet — erst eine ausdrückliche Bestätigung legt ihn als Gmail-Entwurf
// an (erscheint dann auch in Apple Mail, da das Mac-Postfach das Gmail-Konto spiegelt).
// Versenden bleibt ein hartes NO-GO; dies ist reine Entwurfs-Ablage.
public struct EmailDraft: Codable, Sendable, Equatable {
    public var to: String?
    public var subject: String
    public var body: String

    public init(to: String? = nil, subject: String, body: String) {
        self.to = to
        self.subject = subject
        self.body = body
    }

    /// Kurze Kopfzeile für die Karte/Logs (nie der ganze Body).
    public var headline: String {
        let empfaenger = (to?.isEmpty == false) ? to! : "(kein Empfänger)"
        return "\(subject) · an \(empfaenger)"
    }
}

// MARK: - DraftCreateOutcome (S14)
// Ergebnis einer bestätigten Entwurfs-Anlage. created = menschenlesbarer Hinweis
// (z. B. „Entwurf in Gmail abgelegt"); failed = Fehlermeldung.
public enum DraftCreateOutcome: Sendable, Equatable {
    case created(String)
    case failed(String)
}
