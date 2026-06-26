import Foundation
import Observation

// MARK: - StudioContext
// Der gemeinsame, beobachtbare Zustand, mit dem alle Widgets reden. Eine
// Quelle der Wahrheit für "welches Projekt ist im Fokus" und für den
// Signalstrom. Dockt später an den Widget-Board-Store an.
@Observable
public final class StudioContext {
    public private(set) var focusedProjectID: String?
    public private(set) var signals: [WidgetSignal] = []

    public init() {}

    // Obergrenze für den Signal-Log. Verhindert unbegrenztes Wachstum über eine
    // lange Sitzung (jedes onAppear/Poll hängte bisher an). Alle Konsumenten
    // lesen via `.contains(where:)`/`.filter` — das Trimmen vom Anfang ändert
    // nichts an deren Ergebnis, hält aber Speicher und Filterkosten konstant.
    private static let maxSignals = 200

    /// Ein Tap auf "Meyer" → alle projektbezogenen Widgets färben sich an.
    public func focus(project id: String) {
        // Nur emittieren, wenn sich der Fokus wirklich ändert — sonst hängt
        // jedes erneute onAppear desselben Projekts ein weiteres
        // `.projectFocused` an (Signal-Leck + unnötige LLM-Re-Trigger).
        let changed = focusedProjectID != id
        focusedProjectID = id
        if changed { emit(.projectFocused(projectID: id)) }
    }

    /// Ein Widget meldet ein Ereignis. Der Mediator leitet ggf. einen
    /// Vorschlag ab — ohne Rekursion, ohne Aktion.
    public func emit(_ signal: WidgetSignal) {
        signals.append(signal)
        if let derived = Mediator.derive(from: signal) {
            signals.append(derived)
        }
        if signals.count > Self.maxSignals {
            signals.removeFirst(signals.count - Self.maxSignals)
        }
    }

    public func isFocused(_ projectID: String) -> Bool {
        focusedProjectID == projectID
    }

    /// Slice für ein einzelnes Widget: nur die Signale seines Projekts.
    public func signals(for projectID: String) -> [WidgetSignal] {
        signals.filter { signalProjectID($0) == projectID }
    }

    private func signalProjectID(_ s: WidgetSignal) -> String {
        switch s {
        case let .projectFocused(p),
             let .driveFileAdded(p, _),
             let .offerDetected(p, _),
             let .reviewSuggested(p, _),
             let .budgetThresholdCrossed(p, _),
             let .deadlineNear(p, _):
            return p
        }
    }
}
