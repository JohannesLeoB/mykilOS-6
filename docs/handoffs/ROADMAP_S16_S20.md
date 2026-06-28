# mykilOS Dev Collective — Roadmap S16–S20

**Erstellt:** 2026-06-28 · S10 Learning  
**Basis:** IdeenLog + S15-Abschlussbericht + EREIGNISPROTOKOLL + Charter

---

## Gesamtbild

| Session | Scope | Komplexität | Voraussetzung |
|---|---|---|---|
| **S16** | Lern-Loop schließen (Kalkulation Schritt 8) | Mittel | S15 gepusht/gemergt |
| **S17** | Security-Härtung + PAT-Cleanup | Klein | S16 grün |
| **S18** | Kalkulations-Chat-Intent im ConversationEngine | Mittel | S17 grün |
| **S19** | Artikel-Suche-Intent (Airtable `appdxTeT6bhSBmwx5`) | Mittel | S18 grün |
| **S20** | Clockodo Zuhörer Phase 1 (Drafts + Airtable EW) | Groß | S19 grün |

---

## S16 — Lern-Loop sichtbar (Kalkulation Schritt 8)

**Ziel:** Aus bestätigten Anpassungen entstehen Kalibrierungs-Kandidaten. Nutzer kann bewusst promoten → künftige Schätzungen verschieben sich real.

**Scope:**
- `lernen: Bool`-Toggle an KalkulationsActionCard + Engine-Weitergabe (`learn: true`)
- `KalkulationsLernStand` Value-Type (MykilosKit, kein Core-Leak ins Widget)
- `lernUebersicht()` + `promote(candidateID:)` in Engine + Protokoll
- `AuditEntry.Action.calibrationPromoted` (neuer Case — bewusste Entscheidung)
- Widget-Sektion: Aktive Faktoren + Kandidaten mit Promote-Button
- **Cold-Start-Test:** 3× `learn: true` → Kandidat → promote → Neustart → Estimator nutzt ihn

**Fachlogik im LearningStore bereits fertig** — nur Verdrahtung und UI fehlen.

**Startprompt:** `docs/handoffs/STARTPROMPT_S16.md` (S15 hat es bereits vorbereitet)

---

## S17 — Security-Härtung + PAT-Cleanup

**Ziel:** Regelverstöße tilgen, Google-Identität anzeigen, PAT-Scope bereinigen.

**Scope:**
1. **`AirtableSyncService.swift`** — per S16-Forensik bestätigt abwesend (No-Op, Guard-Grep reicht).
2. **Google-Identität nach Login** — `GET /oauth2/v2/userinfo` → `GoogleUserInfo(email, displayName)` → Keychain-Cache → `AppState.currentGoogleUser` → Sidebar.
3. **Airtable baseID-Validierung** — `hasPrefix("app")` + Längen-Check in `AirtableAuthService.connect`.
4. **Airtable PAT-Cleanup** — PAT-Scope auf explizite Bases einschränken (SCHATZ entfernen, "Alle Ressourcen" abwählen). Optional: separater Read-Only-PAT für Artikel-DB `appdxTeT6bhSBmwx5`.

**Neue NO-GO-Regel (ab sofort gültig):** Artikel- & Einkaufsdatenbank `appdxTeT6bhSBmwx5` — READ ONLY, kein Schreiben, nie.

---

## S18 — Kalkulations-Chat-Tool

**Ziel:** Natürliche Preisfragen im Assistent-Chat beantworten ("was kostet eine 6m-Küchenzeile mit Linoleum-Fronten?") über die bestehende KalkulationsEngine.

**Architektur-Korrektur (S16, 2026-06-28):** ConversationEngine hat KEINEN Intent-Switch — er ist eine agentische Tool-Use-Schleife. S18 baut ein **neues Tool in der `AssistantToolRegistry`** (`ClaudeToolDefinition` + `run`-Handler), kein neuer "Intent".

**Konkrete Fallstricke (S16):**
1. `schaetze(projektID:freitext:)` hat `EstimateRequestParser.parse(freitext)` intern eingebaut → Claude extrahiert NICHT die Komponenten, sondern reicht den User-Text unverändert durch. Kein Doppel-Parsing.
2. `schaetze` SCHREIBT (`learningStore.saveSession`) — bricht das "Tools sind read-only"-Prinzip. Bewusste Entscheidung: append-only EstimateSession bei jeder Chat-Schätzung akzeptiert (Referenz für späteres `recordAdjustment`).
3. **projektID-Lücke (vor dem Bauen lösen):** Tools bekommen nur `inputJSON`, keinen App-Kontext. `send()` hat `focusedProjectID` aber dieser wird nicht in `registry.run` durchgereicht. Entweder Kontext in Registry einspeisen (sauber) oder Sentinel-projektID (pragmatisch).
4. `ConversationEngine.activityLabel` hat hardcodierten switch über Tool-Namen → neuen Case ergänzen.

**Synergie mit S16:** EvidenceBasedEstimator wendet aktive Kalibrierungsfaktoren automatisch an → Chat-Schätzungen profitieren gratis vom Lern-Loop.

**Wichtig:** Keine Clockodo-Stundensätze, kein Studio-Honorar — reine Material-/Erfahrungsschätzung für Tischlerarbeiten.

---

## S19 — Artikel-Suche-Tool

**Ziel:** Semantische Produktsuche in der Artikel-Datenbank ("Kennst du einen Gaggenau Backofen mit Pyrolyse?").

**Architektur:** Neues Tool in `AssistantToolRegistry` (kein Intent-Switch). Claude extrahiert Hersteller + Kategorie + Features → Airtable-Query auf `appdxTeT6bhSBmwx5` (`tbl3dAbQtbF51wb4a`) mit `filterByFormula` auf `{Suchtext}` → Ergebnisse als Chat-Antwort.

**READ ONLY — kein Schreiben in die Artikel-DB.**

**Voraussetzung:** S17 PAT-Split muss abgeschlossen sein (Read-Only-PAT für Artikel-DB im Keychain).

**`Suchtext`-Feld** ist vorgebaut (Hersteller + Kategorie + Beschreibung + Artikelnummer) — ideal für Text-Filter ohne Vektor-Embeddings.

**Drei getrennte Datenquellen — nicht vermischen:**
- DeviceCatalog-CSV → Tischler-Material für KalkulationsEngine
- Artikel-DB Airtable → Studio-Produktkatalog (Leuchten, Armaturen, Geräte)
- KalkulationsEngine → Erfahrungsanker + Lernfaktoren

---

## S20 — Clockodo Zuhörer Phase 1

**Ziel:** Chat-Eingabe → Zeitbuchungs-Entwurf → persönliche Airtable-EW-Tabelle.

**Basis aus IdeenLog** (vollständig ausgearbeitete 6-Schichten-Architektur):
1. Intent Layer: `ConversationEngine` neuer Intent `clockodoDraft`, Claude extrahiert Dauer + Leistungstyp + Kunden-/Projektreferenz
2. Resolution Layer: `ClockodoDraftResolver` → Airtable-Lookup → echte IDs, Mehrdeutigkeit → Assistent fragt nach
3. Draft Store: `ClockodoDraftEntry` (GRDB lokal, user-scoped) + Sync → persönliche `Clockodo-EW-{Name}`-Tabelle
4. EW-Tabellen-ID aus `Clockodo-Nutzer.Airtable-Entwurf-Tabelle`

**Airtable-Schema bereits live** (`tblPbly2br8mR2kaU`, 4 persönliche EW-Tabellen, `tblRtsegocdpM8CJd` Leistungen)

**Offene Entscheidungen für S18:**
- Format `time_since`/`time_until`: UTC oder lokale TZ? (Clockodo-Doku prüfen)
- Mehrdeutiger Kunde: Fallback "Mykilos GmbH intern" + Freitext oder explizit nachfragen?

**S19 baut darauf auf:** UI + POST → Clockodo-API + AuditEntry + Buchungen-Tabelle

---

## S19 — Assistent Kontakt-Intelligenz

**Ziel:** Assistent und AssistantWidget kennen alle Personen zu einem Projekt.

**Datenbasis bereits vorhanden:**
- Airtable `Kontakte`-Tabelle: 914 Einträge (891 CSV + 23 Gmail)
- 6 Projekte mit direktem Kundenkontakt-Link; 25 offen

**Scope:**
- `AssistantWidget`: Kontakte-Kontext aus Airtable laden (pro Projekt: Ansprechpartner, Architekt, Lieferanten)
- `ConversationEngine` + Gmail-Suche nach Projektnamen (ASSISTANT_CAPABILITIES_PLAN.md A3/A4)
- Restliche 25 Projekte: assistierte Zuordnung via Gmail-Suche (read-only, kein Schreiben)
- Beziehungsgraph-Snippet im Widget: "HS-Architekten · Tischler · Bauherr Loidl"

**Qualitätslücken bewusst akzeptiert:** 371 Kontakte ohne E-Mail bleiben erstmal so.

---

## S20 — Timeline-Tab Phase 1 + Material-Tab

**Ziel:** Zwei weitere Projekt-Tabs mit echten Daten füllen.

**Timeline-Tab Phase 1:**
- Quelle: Google Calendar (bestehender `GoogleCalendarClient`, `calendarQuery`)
- Zeitstrahl der nächsten 30 Tage für dieses Projekt
- Phase 2 (nicht S20): ClickUp-Aufgaben, sobald ProjectKind-Mapping steht

**Material-Tab:**
- Quelle: Drive `03 PRÄSENTATION`-Unterordner
- Einfache Dateiliste (wie Angebote-Tab, kein PDF-Preview nötig)
- `GoogleDriveClient.listFiles(folderID:)` bereits vorhanden

**Bewusst kein ClickUp-ProjectKind-Mapping in S20** — eigene Session wenn Datenbasis reifer ist.

---

## Dauerhaft zurückgestellt (nicht in S16–S20)

- `importPDF` (Drive-Download + PDF-Pipeline + Destillation V2) — mehrere Sessions, eigene Spur
- `ClickUp als Quelle für ProjectKind` — Mapping-Schema noch nicht entschieden
- `Archiv-Übersetzungsregistry (_PROJEKTE_ARCHIV)` — bewusst zurückgestellt
- `Abnahme-Bereich` — Drive-Quelle noch ungeklärt
- `Drive-Ordner anlegen`-Automatisierung — erster Drive-Schreibzugriff, braucht separate Entscheidung
- `ReviewCenterView (815 Positionen)` — Admin-only, niedrige Priorität
- `SQLite-Backup`, `Crash-Reporting`, `Cache-Management` — Komfort, kein Beta-Blocker

---

*Dieses Dokument wächst. S10 Learning aktualisiert nach jedem Session-Abschluss.*
