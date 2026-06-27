import Foundation
import MykilosKit

// MARK: - AssistantGrounding
// Baut den System-Prompt für den Chat. Erdet die Antworten an echten App-Kontext
// (Datum, fokussiertes Projekt, offene Signale, Projektliste), damit der Assistent
// nicht halluziniert. Phase 1: KEINE Live-Tools — der Prompt sagt das explizit,
// damit der Assistent keine erfundenen „Suchergebnisse" behauptet.
public enum AssistantGrounding {

    public static func systemPrompt(
        focusedProjectID: String?,
        signals: [WidgetSignal],
        projects: [Project],
        now: Date
    ) -> String {
        var lines: [String] = []
        lines.append(
            "Du bist der mykilOS-Projektassistent für ein Design-/Küchenstudio. "
            + "Antworte knapp, konkret und auf Deutsch."
        )
        lines.append("Heute ist \(dateString(now)).")

        if let focusedProjectID, let project = projects.first(where: { $0.projectNumber == focusedProjectID }) {
            var p = "Aktuell im Fokus: \(project.title) (\(project.projectNumber))"
            if let phase = project.phase { p += ", Phase \(phase)" }
            p += "."
            lines.append(p)
        }

        lines.append("")
        lines.append("Offene Signale:")
        lines.append(signals.isEmpty ? "- keine" : signals.map(describe(signal:)).joined(separator: "\n"))

        if projects.isEmpty == false {
            lines.append("")
            lines.append("Projekte im Studio:")
            lines.append(projects.prefix(40).map { "- \($0.projectNumber): \($0.title)" }.joined(separator: "\n"))
        }

        lines.append("")
        lines.append(
            "Wichtig: Erfinde keine Fakten. Du hast in dieser Version KEINE Live-Zugriffe auf "
            + "Mails, Kalender, Drive oder Aufgaben — beziehe dich nur auf den oben gegebenen Kontext "
            + "und sage offen, wenn dir Informationen fehlen. Schreibaktionen (Mails, Termine) darfst "
            + "du nur als Vorschlag formulieren, nie als bereits erledigt darstellen."
        )
        return lines.joined(separator: "\n")
    }

    // MARK: - Helfer (deterministisch)

    private static func dateString(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin") ?? .current
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "de_DE")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "EEEE, d. MMMM yyyy"
        return formatter.string(from: date)
    }

    private static func describe(signal: WidgetSignal) -> String {
        switch signal {
        case .projectFocused(let p):                 "- Projekt fokussiert: \(p)"
        case .driveFileAdded(let p, let name):       "- Drive-Datei in \(p): \(name)"
        case .offerDetected(let p, let label):       "- Angebot in \(p): \(label)"
        case .reviewSuggested(let p, let label):     "- Review-Vorschlag in \(p): \(label)"
        case .budgetThresholdCrossed(let p, let r):  "- Budget in \(p): \(Int(r * 100)) Prozent"
        case .deadlineNear(let p, let days):         "- Deadline in \(p): \(days) Tage"
        }
    }
}
