# mykilOS 6 — Benutzerhandbuch

**Stetige Mitschrift aller Funktionen. Stand: 2026-06-28 · Version 6.4.0**
Jede neue Funktion wird hier beim Build dokumentiert. Dieses Dokument ist kein
Abschlussdokument — es wächst mit der App.

---

## Navigation

Die App öffnet sich mit der **Projektgalerie**. Die linke Sidebar enthält alle
Hauptbereiche. Tastenkürzel:

| Kürzel | Bereich |
|--------|---------|
| ⌘1 | Heute |
| ⌘2 | Projekte |
| ⌘3 | Assistent |
| ⌘4 | Dateien |
| ⌘5 | Angebote |
| ⌘6 | Kalkulation |
| ⌘⇧S | Sidebar ein-/ausblenden |

---

## Heute-Board

**Was es tut:** Übersicht über den aktuellen Arbeitstag — Signal-Strip, Drive-Ordner-Status,
offene Aufgaben und Kalender-Ereignisse auf einen Blick.

**Wo:** Sidebar → Heute (⌘1)

**Funktionen:**
- **DriveFolderRefreshBar**: zeigt wann der Drive-Ordner zuletzt geprüft wurde.
  "Jetzt prüfen" erzwingt einen sofortigen Poll aller aktiven Projektordner auf neue Angebots-PDFs.
- **Signal-Strip**: zeigt Signale aus dem aktuellen Projektkontext (z.B. neue Angebote erkannt).

---

## Projektgalerie

**Was es tut:** Listet alle aktiven Projekte. Quelle: Airtable `Projekte`-Tabelle
(`appuVMh3KDfKw4OoQ`), automatisch synchronisiert beim App-Start.

**Wo:** Sidebar → Projekte (⌘2)

**Funktionen:**
- Projekte nach Nummer (`JJJJ-NR`) sortiert
- Favoriten-Stern (noch in Entwicklung — L25)
- Klick öffnet Projektdetailseite

---

## Projektdetailseite

**Was es tut:** Zeigt alle Informationen und Werkzeuge eines Projekts.

**Tabs:**

### Übersicht
Widget-Board mit bis zu 8 Widget-Arten: Drive, Aufgaben (ClickUp), Kontakte,
Cash/Umsatz, Kalender, Notizen, Mail, Assistent-Insights.

Widgets sind drag-and-drop sortierbar. Jedes Widget zeigt Quelle und SaveState.

### Assistent
Konversationeller Chat, scoped auf dieses Projekt. Claude hat Kontext über
Projektnummer, verknüpfte Drive-Ordner, ClickUp-Liste und Kalender-Suche.
Tool-Use (Drive/Mail/Kalender/Kalkulation) nur bei aktiviertem Opt-in.

### Dateien
Finder-Baum des verknüpften Google-Drive-Projektordners. Unterordner werden
lazy geladen (on-demand). Öffnet Dateien im Browser per Klick.

**Voraussetzung:** Google-Konto verbunden (Settings → Google).

### Angebote
Zeigt alle Angebots-/Rechnungs-PDFs aus dem Drive-Ordner (`04 Angebote`-
Unterordner oder per Keyword erkannt: angebot/rechnung/kostenvoranschlag).
Read-only — öffnet im Browser.

### Timeline
Platzhalter — in Entwicklung (L27).

### Material
Zeigt Drive-Unterordner `05 Material` (tolerant per Name gematcht).

---

## Globale Ansichten (Sidebar)

### Assistent (global)
Konversationeller Chat ohne Projektscope. Zeigt alle Projekte als Kontext.
Tools (Mail, Kalender, Drive) nur bei aktivem Opt-in (Schalter in der Chat-UI).

**Schätzchat-Modus**: Separater Toggle (amber). Aktiviert ausschließlich das
`schaetze_projekt`-Tool — kein Mail/Kalender/Drive-Datenzufluss. Erlaubt
Schätzungen ohne verbundenes Projekt.

### Dateien (global)
Alle Drive-Dateien des Accounts, nach Änderungszeit sortiert.

**Voraussetzung:** Google-Konto verbunden.

### Angebote (global)
Projektliste links, Angebots-PDFs des gewählten Projekts rechts.

### Kalkulation
Kostenschätzungs-Engine (mykilO$$-Integration). Freitext-Eingabe einer
Projektbeschreibung → Min/Mitte/Max-Netto-Schätzung mit Konfidenz-Badge.

**Datenquellen (lokal, kein Netzwerk):**
- `_Daten/Kalkulation/Brain/active_price_anchors.csv` — 203 Tischler-Preisanker
- `_Daten/Kalkulation/Devices/catalog.csv` — 5.565 Geräte/Beschläge
- Fallback: BaselineAnchorProvider (6 konservative Regelanker)

**Lern-Loop:** Bestätigte Anpassungen (Faktor + Grund) werden append-only
gespeichert. Kandidaten können per "Übernehmen" zu aktiven Faktoren promoted
werden → zukünftige Schätzungen verschieben sich.

---

## Integrationen (Settings → Integrationen)

Übersicht aller verbundenen Dienste mit Verbindungsstatus.

### Google
Verbindet Drive, Kalender, Kontakte und Gmail über ein einziges OAuth-Login
(`johannes@mykilos.com`). PKCE-Flow, Token in Keychain.

Scopes: Drive (read-only Metadaten), Calendar (read), Contacts (read),
Gmail (read Metadaten+Snippet), UserInfo (E-Mail + Profil).

### Airtable
Personal Access Token (PAT) + Base-ID. Liest `Kunden` und `Projekte` aus
`appuVMh3KDfKw4OoQ`. Sync bei App-Start und manuell über Force-Poll-Button.

**NO-GO:** Geteilte Base `appkPzoEiI5eSMkNK` und Artikel-DB `appdxTeT6bhSBmwx5`
werden nie beschrieben.

### ClickUp
Personal Token. Liest offene Aufgaben je Projektliste (`list_clickup_tasks`-Tool).

### Clockodo
API-Key pro User (Private Area). Jeder User sieht nur eigene Zeiteinträge.
Datensensitiv — erscheint nur in der Private Area der Settings.

### Sevdesk
API-Token (Private Area). Liest Ist-Umsatz für das Cash-Widget.
**NIE als Assistenten-Tool — nur Widget.**

### Claude (Anthropic)
API-Key in Keychain. Modell: `claude-sonnet-4-6`. Powers den konversationellen
Assistenten. Tool-Daten fließen nur bei aktivem Opt-in an die API.

---

## Identität & Private Area

**Wo:** Settings → Identität / Private Area

- **Identität**: zeigt verbundenes Google-Konto (Avatar, Domain, E-Mail).
  6-Dot Traffic-Light zeigt Verbindungsstatus aller Integrationen.
- **Private Area**: nutzer-eigene Credentials (Clockodo, perspektivisch weitere).
  Visuell getrennt von geteilten Integrationen.
- **Cache leeren**: löscht lokale GRDB-Daten ohne App-Neuinstallation.

---

## Assistent — Tool-Use

Wenn Tools aktiviert sind, kann der Assistent folgende Aktionen ausführen
(alle **read-only**, Bestätigung per Action-Card bei Schreibaktionen):

| Tool | Was es tut | Opt-in |
|------|-----------|--------|
| `search_gmail` | Sucht Mails nach Query | toolsEnabled |
| `list_calendar_events` | Liest Kalender-Termine | toolsEnabled |
| `suggest_calendar_event` | Erzeugt Kalender-URL (kein API-Write) | toolsEnabled |
| `list_drive_folder` | Listet Drive-Ordner-Inhalt | toolsEnabled + driveFolderID |
| `list_clickup_tasks` | Liest ClickUp-Aufgaben | toolsEnabled + clickUpListID |
| `search_contacts` | Sucht Google-Kontakte | toolsEnabled |
| `schaetze_projekt` | Kostenschätzung (lokal) | toolsEnabled oder schaetzModus |
| `query_studio_knowledge` | Fragt Slack-Brain | toolsEnabled |

Alle Tool-Calls werden via `DataFlowLogger` lokal protokolliert.

---

## Schaltzentrum (Datenstrom-Handbuch)

Vollständige Karte aller Datenströme: Airtable `appuVMh3KDfKw4OoQ` →
Tabelle `Datenstrom-Handbuch`. 22 Weichen dokumentiert (Stand 2026-06-28).

---

*Dieses Dokument wird mit jedem Feature-Commit aktualisiert.*
*Letzte Änderung: 2026-06-28 · polish/dampflok*
