# Erfahrungsbericht S16 — an den Tisch (S10 Learning)

**Session:** S16 · Claude Code (Opus 4.8) · 2026-06-28
**Branch:** `feat/kalkulation-calibration-loop` (von `feat/kalkulation-record-adjustment`)
**Ergebnis:** ✅ 198 Tests grün (179 swift-testing + 19 XCTest), keine Regressions

---

## Was gebaut wurde

Kalkulations-Port **Schritt 8** — der Lern-Loop ist sichtbar und steuerbar:
- `recordAdjustment` bekommt `lernen: Bool` (Loop-Eingang).
- `lernUebersicht()` + `promote(candidateID:)` in Engine + Protokoll.
- `KalkulationsLernStand`/`-Faktor`/`-Kandidat` als neue MykilosKit-Value-Types.
- `AuditEntry.Action.calibrationPromoted`.
- Widget: Lern-Toggle an der ActionCard + ausklappbare Sektion „Gelernte
  Kalibrierung" (aktive Faktoren, Promote-Button, alle Renderstates).
- Cold-Start-Test `lernLoopUeberlebtNeustartUndVerschiebtSchaetzung`.

Details: `HANDOFF_KALKULATION_CORE_PORT.md` (Schritt 8) + EREIGNISPROTOKOLL.

---

## Was gut lief

- **Fachlogik war fertig.** Der `LearningStore` konnte schon alles (Kandidat ab 3
  Adjustments, `promoteCalibration`, `summary`, Estimator liest aktive Faktoren).
  S16 war fast reine Verdrahtung + Sichtbarkeit — wie im Startprompt versprochen.
- **Schritt-7-Tests blieben unverändert grün.** Der `lernen`-Parameter wurde über
  eine Protokoll-`extension`-Convenience (alte 3-Arg-Signatur → `lernen: false`)
  rückwärtskompatibel gemacht, statt jeden Aufrufer anzufassen.

## Was hart war / Fallstricke

- **Protokoll-Requirements haben keine Default-Argumente.** Man kann `lernen: Bool = false`
  NICHT am Protokoll deklarieren. Lösung: Requirement ohne Default + `extension`-Overload
  mit der alten Signatur. Wichtig: NICHT zusätzlich am konkreten Engine-Impl ein Default
  setzen — sonst wird der 3-Arg-Aufruf mehrdeutig (extension vs. default).
- **Leerer Stub-Provider hätte den Cold-Start-Test wertlos gemacht.** `StubAnchorProvider`
  liefert mitteNetto == 0 → Kalibrierung greift nicht (`applyActiveCalibrations` braucht
  `baseTotal.expected > 0`). Der Test nutzt deshalb `BaselineAnchorProvider` (eingebaut,
  deterministisch, keine externen Daten) für eine echte positive Baseline.
- **Deutsche Typo-Anführungszeichen + Straight-Quote im Swift-String** terminieren das
  Literal vorzeitig (`„…"` mit geradem `"`). Im UI-Text vermieden.

---

## ⚠️ Finding für S17 (ehrlich gemeldet, Kulturregel)

Die Roadmap nennt als S17-Aufgabe 1 das Löschen von `AirtableSyncService.swift`
(3 Regelverstöße). **Diese Datei existiert auf der Kalkulations-Branch-Linie NICHT**
(`find Sources -name AirtableSyncService.swift` → leer; nur Doku-Treffer). Sie liegt
vermutlich auf `main`/`stabilize` oder einem Live-Wiring-Branch. S17 muss zuerst den
echten Integrations-/Merge-Stand klären, bevor sie etwas löscht, das hier nicht liegt.
Steht ausführlich in `STARTPROMPT_S17.md` unter „Wichtiger Vorab-Check".

---

## Berührte Daten (Statut 8)

Nur lokale temporäre `learning.sqlite` in `NSTemporaryDirectory()` (Test-Verzeichnisse,
im `defer` gelöscht). **Keine** externen Datenquellen (Airtable/Drive/Sevdesk/Gmail)
gelesen oder geschrieben. Kein echtes Keychain/Netzwerk im Testlauf.

---

## Status

Branch sauber, alles grün, Token-Disziplin geprüft (manuell — SwiftLint lokal nicht
installiert; kein `.font(.system)`/`Color(red:)`/`Color(hex:)` im Widget).
Kein Push — warte auf Johannes' Freigabe.
