# Handoff — Live-Wiring Session 4 (2026-06-28)

**Thema:** Clockodo Zuhörer — Architektur, Airtable-Schema, persönliche User-Tabellen, Dual-UI.
**Status:** Airtable vollständig live (7 neue Tabellen + Feld-Update), Code noch nicht implementiert.
**Nächste Session:** Code-Implementierung des Clockodo Zuhörers (6 Schichten, Dual-UI).

---

## Was in dieser Session gemacht wurde

### 1. Vollständige Architektur-Analyse

Basis: 400 echte Clockodo-Einträge H1 2026 + Screenshots (Stundentafel,
Stundenkonto, Projektberichte, Dashboard).

**Erkannte Buchungsmuster:**
- 57% intern auf "Mykilos GmbH": Leistung = Tätigkeitsart, Projekt = Textfeld
- Direkt billable nur für aktiv abgerechnete Projekte (Junge/WRA51: 33x, Neuhaus: 19x)
- 4 User: Johannes (421694, 344 Einträge), Jilliana (391140, 45), Daniel (391057, 10),
  Frauke (391141, 1)
- 8 Leistungsarten, alle in `Clockodo-Leistungen` erfasst

**Verfügbare API-Endpunkte:**
- `GET /api/v2/entries?enhanced_list=1` — Einträge mit vollen Namen (aktiv)
- `POST /api/v2/entries` — neue Buchung (aktiv, nicht deprecated)
- `GET /api/v2/clock` — laufender Timer-Status (aktiv)
- `/api/v2/services`, `/api/v3/services` — beide deprecated/404

### 2. Airtable-Schema vollständig live eingespielt

Base: `appuVMh3KDfKw4OoQ`

**Neu: `Clockodo-Nutzer`** (`tblPbly2br8mR2kaU`)
| Feld | Typ |
|------|-----|
| Name | singleLineText (Primary) |
| E-Mail | email |
| Clockodo-User-ID | number (precision 0) |
| Aktiv | checkbox |

Records:
| Record-ID | Name | Clockodo-User-ID | EW-Tabelle |
|-----------|------|-----------------|------------|
| recrHGv8SFviFPrvp | Johannes Berger | 421694 | tbl4vZ2UFyeTRD8hd |
| rec3i3LJLtrFwOJBN | Jilliana | 391140 | tblXQIDrvPVN9ijI9 |
| recmbKjrO9emL6yqt | Daniel | 391057 | tblNDVve3jjJ9s8HB |
| recZ7rauB3erxG8Vb | Frauke | 391141 | tblRrqIQZmm2DosJT |

Neues Feld `Airtable-Entwurf-Tabelle` (ID: `fldsoeQHWDmbBt7FM`) zeigt auf die
persönliche Entwurfstabelle des jeweiligen Users. App liest diesen Wert nach
Clockodo-Login und weiß damit, in welche EW-Tabelle Drafts geschrieben werden.

**Neu: 4 persönliche Arbeitstabellen (`Clockodo-EW-*`)**

| Tabelle | ID | User |
|---------|-----|------|
| Clockodo-EW-Johannes | tbl4vZ2UFyeTRD8hd | Johannes Berger |
| Clockodo-EW-Jilliana | tblXQIDrvPVN9ijI9 | Jilliana |
| Clockodo-EW-Daniel   | tblNDVve3jjJ9s8HB | Daniel |
| Clockodo-EW-Frauke   | tblRrqIQZmm2DosJT | Frauke |

Felder je EW-Tabelle:
| Feld | Typ | Verwendung |
|------|-----|-----------|
| Name (Primary) | singleLineText | Freitext-Beschreibung der Tätigkeit |
| Datum | date | Tag der Arbeit |
| Von | singleLineText | Startzeit HH:MM (z. B. "09:00") |
| Bis | singleLineText | Endzeit HH:MM (z. B. "13:00") |
| Dauer-h | number | Dezimalstunden, berechnet oder manuell |
| Projekt | singleLineText | Projektname / Freitext |
| Kunden-ID | number | Clockodo `customers_id` (nach Resolution) |
| Leistung | singleLineText | Leistungsname (nach Resolution) |
| Leistungs-ID | number | Clockodo `services_id` (nach Resolution) |
| Notiz | multilineText | Zusatznotiz, erscheint im Clockodo-Text-Feld |
| Billable | checkbox | 0 = intern, 1 = direkt billable |
| KW | number | Kalenderwoche (für Wochenabschluss-Filter) |
| Quelle | singleSelect | chat / kalender / mail / manuell |
| Status | singleSelect | Entwurf → Zur Buchung → Gebucht / Verworfen |

Workflow:
1. Assistent schreibt neuen Entwurf → Status "Entwurf"
2. User markiert in Wochenvorschau zum Buchen → Status "Zur Buchung"
3. Confirm → POST → Status "Gebucht" + Record in `Clockodo-Buchungen`

**Neu: `Clockodo-Buchungen`** (`tblYQxlauwej7FD1w`)
| Feld | Typ | Details |
|------|-----|---------|
| Clockodo-Entry-ID | number | ID vom Clockodo-Response nach POST |
| Datum | date | European format |
| Nutzer | multipleRecordLinks | → Clockodo-Nutzer |
| Leistung | multipleRecordLinks | → Clockodo-Leistungen |
| Dauer-h | number (precision 2) | Dezimalstunden |
| Text | multilineText | Freitext / Projektname |
| Billable | checkbox | |
| Quelle | singleSelect | chat / kalender / mail / manuell |
| Status | singleSelect | gebucht / storniert |

**Bereits vorhanden:**
- `Clockodo-Leistungen` (`tblRtsegocdpM8CJd`) — 8 Services mit IDs
- `Kunden.Clockodo-Kunden-ID` — gemappt für 10 von 30 Kunden

### 3. Kernregel (User-Scoping)

**Jeder angemeldete User bucht, sieht und editiert ausschließlich seine eigenen Zeiteinträge.**

Durchsetzung auf 3 Ebenen:
1. **GRDB** — `ClockodoDraftEntry` hat `clockodoUserID: Int`, alle Queries filtern darauf
2. **App** — `ClockodoDraftStore` nimmt `currentUserID` als Initialisierungsparameter,
   liefert nur eigene Drafts
3. **Clockodo API** — `POST /api/v2/entries` mit den Credentials des eingeloggten Users;
   Clockodo erlaubt kein Buchen als fremder User ohne Admin-Rechte

---

## 6-Schichten-Architektur (zu implementieren)

```
[INPUTS]
  Chat-Input:     "habe grad 4h CAD für Heinz gemacht"
  Kalender:       GCal-Termine der Woche
  Mail:           Gmail-Threads mit Projektreferenzen
  Manuell:        Quick-Add im ClockodoWidget
        ↓
[Intent Layer]    ClaudeConversationEngine → Intent: .clockodoDraft
                  extrahiert: duration=4h, service="CAD", clientRef="Heinz",
                              date=today, source=.chat
        ↓
[Resolution Layer] ClockodoDraftResolver
                  "Heinz" → Airtable Kunden.Clockodo-Kunden-ID → 4602311
                  "CAD"   → Clockodo-Leistungen → 1418402
                  Fallback: "Mykilos GmbH" (customers_id: intern) + Text
        ↓
[Draft Store — DUAL]
  GRDB lokal:     ClockodoDraftEntry (schnell, offline-fähig)
  Airtable EW:    POST in Clockodo-EW-{UserName} (ID aus Clockodo-Nutzer lookup)
                  → Status: "Entwurf"
        ↓
[ZWEI UI-ORTE — dieselben Daten]
  ClockodoWidget: Heute-Seite, kompakt
  (Heute-Board)   • "+" Button → Quick-Add-Sheet
                  • Wochenbalken mit KW-Summierung
                  • Jeder Eintrag: editierbar, "Zur Buchung" markieren

  Zeiten-Tab:     Im Chat-Assistenten, voll
  (AssistantChat) • NLP-Eingabe via Chat
                  • Detailansicht aller Entwürfe der KW
                  • Wochenabschluss-Button: alle "Zur Buchung" → Batch-POST
        ↓
[Confirm → POST]  POST /api/v2/entries (per User-Credentials)
                  → AuditEntry (GRDB)
                  → Record in Clockodo-Buchungen (Airtable Master-Log)
                  → EW-Tabelle Status → "Gebucht"
```

**Niemals automatisch buchen** — immer erst Wochenvorschau → User-Bestätigung.

---

## POST /api/v2/entries — Pflichtfelder

```json
{
  "customers_id": 4602311,
  "services_id": 1418402,
  "time_since": "2026-06-28T09:00:00+02:00",
  "time_until": "2026-06-28T13:00:00+02:00",
  "billable": 0
}
```

Optional: `projects_id`, `text`, `users_id` (nur für Admins, die für andere buchen).

---

## Offene Entscheidungen für die Implementierungs-Session

1. ✅ **UI:** Beide Orte — ClockodoWidget (Heute-Board, kompakt) UND Zeiten-Tab
   im Chat-Assistenten (voll). Beide lesen denselben Draft-Store.
2. **Timezone in `time_since`/`time_until`:** Beim ersten echten POST prüfen;
   vermutlich lokale TZ des Users (z. B. `+02:00`).
3. **Airtable-Schreibpfad:** `AirtableClient.createRecord(tableID:fields:)` neu
   implementieren — für EW-Tabellen (Drafts) und `Clockodo-Buchungen` (Audit).
4. **Kunden-Lookup-Fallback:** Mehrdeutigkeit → Assistent listet Optionen und
   fragt nach, bevor Draft angelegt wird. Kein stilles Raten.
5. **EW-Table-ID-Lookup:** Nach Clockodo-Login → `GET Clockodo-Nutzer` mit
   `filterByFormula={Clockodo-User-ID}=421694` → Feld `Airtable-Entwurf-Tabelle`
   liefert die persönliche Tabellen-ID. Einmal cachen, nicht bei jedem Draft neu.

---

## Startprompt für Implementierungs-Session

```
Wir implementieren in mykilOS 6 den "Clockodo Zuhörer" — den Smart Time Logger.
Die Architektur ist in HANDOFF_LIVE_WIRING_4.md vollständig definiert.
Das Airtable-Schema ist live (7 neue Tabellen + Feld-Update, alle IDs im Handoff).

Architektur: 6 Schichten, Dual-UI (ClockodoWidget auf Heute-Seite + Zeiten-Tab
im Chat-Assistenten), GRDB-lokal + Airtable-EW-Sync pro User.

Airtable-Nutzer-Tabellen-IDs:
- Clockodo-Nutzer: tblPbly2br8mR2kaU (Self-referenzierend, enthält EW-Table-IDs)
- Clockodo-EW-Johannes: tbl4vZ2UFyeTRD8hd
- Clockodo-EW-Jilliana: tblXQIDrvPVN9ijI9
- Clockodo-EW-Daniel:   tblNDVve3jjJ9s8HB
- Clockodo-EW-Frauke:   tblRrqIQZmm2DosJT
- Clockodo-Buchungen:   tblYQxlauwej7FD1w (Master-Audit-Log)

Beginne mit:
1. ClockodoDraftEntry (Domain-Modell in MykilosKit, inkl. airtableRecordID)
2. ClockodoDraftStore (GRDB-backed, user-scoped, Cold-Start-Test)
3. AirtableClient.createRecord(tableID:fields:) (neuer Schreibpfad)
4. ClockodoDraftResolver (Airtable-Lookup via Kunden + Leistungen + Fallback)
5. ClockodoWidget-Erweiterung: Quick-Add-Sheet + Wochenbalken
6. Zeiten-Tab im Chat-Assistenten (NLP-Eingabe + Wochenabschluss-Button)

Kernregel: jeder User bucht/sieht/editiert nur seine eigenen Einträge.
EW-Tabellen-ID-Lookup: GET Clockodo-Nutzer mit filterByFormula nach User-ID.
```
