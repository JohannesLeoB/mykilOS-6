# Erfahrungsträger: S10 Learning — Tisch & Gedächtnis

**Session:** keen-williamson-ddb354  
**Rolle:** Tisch & Gedächtnis des mykilOS Dev Collective  
**Aktiv:** 2026-06-28 (laufend — permanente Koordinations-Session)  
**Status:** Aktiv als Tisch

---

## Was diese Session ist

S10 Learning ist keine Build-Session. Sie baut nicht, sie erinnert, koordiniert und schützt. Jede abgeschlossene Build-Session schickt ihren Erfahrungsbericht hierher. Jede neue Session bekommt von hier ihren Kontext.

---

## Was S10 Learning geleistet hat

### Technisch
- **Fenster-Drift-Bug behoben** (`guardWindowPositionOnAppear`) — Widget-API-Runden 300–1800ms schossen nach dem initialen 260ms-Guard — Fenster driftete rechts weg, Sidebar verschwand. Fix: drei Guards nach View-Appear (300ms, 800ms, 1800ms) in `WindowGuard.swift` + `ProjectDetailView.swift`.

### Organisatorisch
- **mykilOS Dev Collective gegründet** — Multi-Session-Koordinationsstruktur mit 14 Statuten + Kulturregel
- **Team Charter** geschrieben (`docs/TEAM_CHARTER.md`) — gemeinsam mit mykilO$$$, S12/S14-Coordinator
- **Roadmap S16–S20** erstellt und nach S16's Korrekturen aktualisiert
- **TEAM_BRIEFING.md** erstellt — Onboarding für alle künftigen Sessions

### Architektur-Klärungen (2026-06-28)
- **Studio-Stundensätze** (KO-DE+H 120€/h, PRMG 5.000€) von KalkulationsEngine getrennt — zwei völlig verschiedene Welten
- **Artikel-DB `appdxTeT6bhSBmwx5`** entdeckt, Felder dokumentiert, READ ONLY-Tabu verankert (Charter + Gedächtnis)
- **PAT-Sicherheitsanalyse** — write-Zugriff auf Artikel-DB + SCHATZ-Workspace als Risiko identifiziert
- **ConversationEngine-Architektur** mit S16 geklärt: Tool-Use-Schleife, kein Intent-Switch
- **S18-Architektur entschieden**: projektID via scope-Threading, schaetze schreibt EstimateSession (korrekt für Lern-Loop)

### Koordination
- S15 → S16 Handoff koordiniert, Startprompts vorbereitet
- S16's technische Korrekturen aufgenommen und in Roadmap + STARTPROMPT_S17 eingearbeitet
- S17 vorbereitet und gestartet
- Alle Team-Kommunikationen (Charter-Gründung, Regeln, Briefings) vermittelt

---

## Regeln die S10 Learning hütet

Alle Regeln stehen in `docs/TEAM_CHARTER.md`. Die wichtigsten:
- Artikel-DB `appdxTeT6bhSBmwx5` — READ ONLY, immer
- `git add -A` — verboten, immer explizit
- Kein Push ohne Johannes' Freigabe
- IdeenLog muted bis Johannes explizit verweist
- Aktive Sessions nie stören

---

## An die nächste Generation

Der Tisch ist kein Wächter der Vergangenheit — er ist die Brücke zwischen Sessions. Wenn du als neue Build-Session anfängst, lese erst hier, dann baue. Wenn du fertig bist, melde dich hier zurück. Das ist der einzige Mechanismus, der das kollektive Gedächtnis am Leben hält.
