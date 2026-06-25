import Foundation

// MARK: - GoogleConnectionStatus
// Reiner Status der Google-Verbindung, analog zu SaveState — sichtbar in der
// UI, ohne dass die UI-Schicht MykilosServices (Keychain/Netzwerk) kennen muss.
public enum GoogleConnectionStatus: Equatable, Sendable {
    case disconnected
    case connecting
    case connected
    case error(String)
}
