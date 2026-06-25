# Handoff — Post-Akt 5, Aufgabe 3: About-Fenster

**Status:** abgeschlossen

---

## Was gebaut wurde

mykilOS 6 hat jetzt ein eigenes About-Fenster.

Die App definiert ein zusätzliches Window mit `id: "about"` und ersetzt den
macOS-AppInfo-Menüpunkt durch "Über mykilOS 6". Der Menüpunkt öffnet das Fenster
und ist zusätzlich per `Cmd+,` erreichbar.

Das Fenster zeigt:

- App-Name `mykilOS 6`
- Version `6.0.0`
- Copyright `MYKILOS`
- Einzeiler: local-first Studio-Cockpit für Projektplanung, Quellen und Entscheidungen

## Geänderte Dateien

| Datei | Was |
|---|---|
| `Sources/MykilosApp/MykilOS6App.swift` | About-Window, About-View und App-Menüeintrag |
| `CLAUDE.md` | Status, offene Punkte und Doku-Liste aktualisiert |

## Design

Die About-View nutzt ausschließlich vorhandene Design-Tokens:

- `MykColor.paper.color` für Hintergrund
- `MykColor.ink.color` und `MykColor.inkSoft.color` für Text
- `Font.mykDisplay`, `Font.mykBody`, `Font.mykCaption`, `Font.mykMono`

Keine `.font(.system(...))`, kein lokaler Hex-Farbwert.

## Tests

Keine neuen Tests. Die Änderung ist reine macOS-SwiftUI-UI ohne neue Persistenz
oder Fachlogik.

Verifiziert:

- `swift build` — erfolgreich
- `swift test` — 81 Tests grün

## Bewusst offen

- Das App-Icon ist weiterhin offen und nutzt noch kein eigenes Asset.
- Die About-Version ist aktuell statisch `6.0.0`; eine spätere Bundle-Version-
  Verdrahtung kann folgen, sobald Release-Metadaten zentral gepflegt werden.

## Nächster Schritt

Post-Codex-Aufgaben sind damit abgeschlossen. Sinnvolle nächste Verfeinerung:
App-Icon oder LLM-Integration im Assistenten.
