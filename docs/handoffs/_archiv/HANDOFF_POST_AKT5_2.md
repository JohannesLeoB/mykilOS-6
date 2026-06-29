# Handoff — Post-Akt 5, Aufgabe 2: AuditStore verdrahten

**Status:** abgeschlossen

---

## Was gebaut wurde

Ein persistenter `AuditStore` ist jetzt in `MykilosServices` verdrahtet. Er folgt
dem bestehenden Store-Muster:

- `@MainActor @Observable`
- GRDB-backed über die vorhandene Tabelle `auditEntries`
- `SaveState` sichtbar
- Schreibvorgang `append(_:)` wirft Fehler weiter

`AppState` besitzt den Store als zentrale Property und lädt ihn beim Bootstrap.
Das `AssistantWidget` erhält den Store und schreibt beim Bestätigen einer
`SuggestedAction` einen `AuditEntry`. Die Action-Card zeigt danach, ob der
Audit-Eintrag gespeichert wurde oder ob ein Fehler auftrat.

## Geänderte Dateien

| Datei | Was |
|---|---|
| `Sources/MykilosServices/Database/AuditStore.swift` | Neuer persistenter AuditStore |
| `Sources/MykilosServices/Database/WidgetBoardRecord.swift` | Mapping `AuditRecord` → `AuditEntry` |
| `Sources/MykilosApp/Data/AppState.swift` | `audit`-Store hinzugefügt und beim Bootstrap geladen |
| `Sources/MykilosWidgets/Kinds/AssistantWidget.swift` | Bestätigung schreibt AuditEntry + SaveState-Anzeige |
| `Sources/MykilosWidgets/WidgetBoardView.swift` | AuditStore an AssistantWidget weitergereicht |
| `Sources/MykilosApp/Detail/ProjectDetailView.swift` | Projekt-Assistant bekommt AuditStore |
| `Sources/MykilosApp/MykilOS6App.swift` | Assistant-Seite bekommt AuditStore |

## Tests

Neu:

- `WidgetBoardStoreTests.auditEntryUeberlebtNeustart`

Der Test schreibt einen `AuditEntry`, erzeugt eine neue `AuditStore`-Instanz mit
derselben In-Memory-Datenbank und liest den Eintrag wieder identisch aus.

Verifiziert:

- `swift test` — 81 Tests grün
- `swift build` — erfolgreich

## Bewusst offen

- Es gibt noch keine eigene Audit-Historienansicht; die Einträge werden
  persistent gespeichert und sind über den Store lesbar.
- `actorUserID` ist aktuell bewusst lokal als `"local-user"` gesetzt, bis ein
  echtes Benutzer-/Identitätsmodell eingeführt wird.
- Bestehende Warnungen aus vorherigen Sessions wurden nicht angefasst.

## Nächster Schritt

Post-Akt 5, Aufgabe 3: About-Fenster mit Versionsnummer und mykilOS-Design-Tokens.
