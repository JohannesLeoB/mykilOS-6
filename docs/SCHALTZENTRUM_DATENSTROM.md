# Schaltzentrum — Datenstrom-Handbuch

**Das riesige Schaltzentrum mit allen Büchern, Drähten und Schaltwissen.**
Jede externe Datenweiche von mykilOS 6 — erklärt, gelistet, maschinenlesbar.

- **Maschinenlesbar:** [`datastream_manifest.json`](datastream_manifest.json)
- **Live in Airtable (Mastermind-Base `appuVMh3KDfKw4OoQ`):**
  - `Datenstrom-Handbuch` (`tblaUVftka0GvXzeU`) — diese Karte
  - `Datenstrom-Log` (`tbl71AZC9FGWZuDNU`) — append-only Sync-Protokoll, füllt sich bei jedem echten Datensync

---

## Eiserne Schreibregel

mykilOS schreibt nach Airtable **ausschließlich** in die zwei Schaltzentrum-Tabellen
der **Mastermind-Base**. Das ist hart im Code verankert (`AirtableClient.createRecord`
Whitelist: `writableBaseID` + `writableTables`). **Nie** DELETE/PATCH bestehender
Daten, **nie** die geteilte NO-GO-Base, **nie** Projekt-/Kunden-/Kalkulationsdaten.
Verstöße werfen vor jedem Netzwerkzugriff.

---

## Die Weichen

| ID | System | Richtung | Quelle → Ziel | Trigger | NO-GO | Opt-in |
|---|---|---|---|---|---|---|
| AIRTABLE_KUNDEN_PROJEKTE | Airtable | READ | Mastermind → Registry-Cache | Startup + onDemand | read-only | – |
| DRIVE_POLL_OFFERS | Drive | READ | PROJEKTE-Unterordner → Signal `offerDetected` | 60s/300s + Button | read-only | – |
| DRIVE_FILES_TAB | Drive | READ | Projekt-Ordner → FilesTabView | onDemand | read-only | – |
| DRIVE_OFFERS_TAB | Drive | READ | Angebots-PDFs → OffersTabView | onDemand | read-only | – |
| DRIVE_MATERIAL_TAB | Drive | READ | 03 PRÄSENTATION → MaterialTabView | onDemand | read-only | – |
| GMAIL_SEARCH | Gmail | READ | Gmail-API → `search_gmail` | onDemand | read-only | **Ja** |
| CALENDAR_LIST | Calendar | READ | Calendar-API → `list_calendar_events` | onDemand | read-only | **Ja** |
| CONTACTS_QUERY | Contacts | READ | People-API → `search_contacts` (W1) | onDemand | read-only | **Ja** |
| CLICKUP_TASKS | ClickUp | READ | Liste → `list_clickup_tasks` (W1) | onDemand | read-only | – |
| CLOCKODO_TODAY | Clockodo | READ | Clockodo-API → ClockodoWidget | Intervall | read-only (per-User) | – |
| SEVDESK_INVOICES | Sevdesk | READ | Sevdesk-API → CashWidget | onDemand | **NIE als Tool** | – |
| GOOGLE_USERINFO | Google Identity | READ | OAuth userinfo → Sidebar | Startup | read-only | – |
| KALKULATION_LOCAL | Kalkulation | READ | Baseline/DeviceCatalog → `schaetze_projekt` | onDemand | keine | – |
| CLAUDE_MESSAGES | Claude | BIDIR | Chat (+Opt-in Tool-Daten) → Anthropic API | onDemand | keine | **Ja** |
| DATAFLOW_LOG_WRITE | Airtable | WRITE | DataFlowLogger → Datenstrom-Log | bei jedem Sync | append-only | – |
| DATAFLOW_HANDBOOK_WRITE | Airtable | WRITE | Pflege → Datenstrom-Handbuch | onDemand | append-only | – |
| GMAIL_FULL_CACHE | Gmail | READ | Gmail-API (Paginierung) → GRDB-Cache | Startup | read-only | **Ja** · *Welle 2* |

---

## Handshake-Protokoll (Datenstrom-Log)

Jeder instrumentierte Datensync schreibt über den `DataFlowLogger` einen Eintrag:
Zeitstempel · Integrations-ID · Nutzer · Aktion (START/SUCCESS/ERROR) · gelesene/
geschriebene Records · HTTP-Status · Dauer · Changelog. Erst lokal (GRDB,
`dataFlowLog`-Tabelle, Migration `v6_dataflow_log`), dann **nicht-fatal** nach Airtable
gespiegelt — ein Ausfall der Mastermind-Base stört die App nie.

Wer eine neue Weiche baut, trägt sie hier **und** im Airtable-Handbuch ein.
