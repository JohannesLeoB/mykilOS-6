# mykilOS 6 — Claude Code Projektgedächtnis

**Smarte Projektplanung und Management mit intelligenten Automationen und Integrationen.**
Das Cockpit, das alles kann. macOS 14+, SwiftUI, local-first.

---

## Wo wir stehen

**Akt 5 abgeschlossen.** Politur, Dark Mode, DMG. Post-Akt-5 Aufgabe 5
ist abgeschlossen: Der Assistent kann Claude-Zusammenfassungen aus Signalen
und regelbasierten Insights erzeugen.

| Akt | Status | Inhalt |
|---|---|---|
| Akt 0 | ✅ | Fundament: GRDB, Repository, Cold-Start-Tests, Signal-Engine |
| Akt 1 | ✅ | App-Shell, Galerie, Projekt-Detailseite, 7 Widget-Arten |
| Akt 2 | ✅ | GRDB live, WidgetBoardStore, NoteStore, Heute-Board, SaveStateBar |
| Akt 3, S1 | ✅ | Google OAuth/PKCE + Keychain, Settings-Tab mit Verbinden/Trennen |
| Akt 3, S2 | ✅ | Drive-Widget live (read-only, GoogleDriveClient) |
| Akt 3, S3 | ✅ | Token-Refresh (GoogleAccessTokenProvider) + Kalender-Widget live |
| Akt 3, S4 | ✅ | Kontakte-Widget live (GoogleContactsClient, contactsQuery) |
| Akt 3, S5 | ✅ | Clockodo-Widget live (API-Key-Auth, Settings-Sektion, ClockodoClient) |
| Akt 3, S6 | ✅ | Mail-Widget live (GoogleGmailClient, WidgetKind .mail, mailQuery) |
| Akt 3, S7 | ✅ | Drag & Drop im Widget-Board (Home + Projekt) |
| Akt 3, S8 | ✅ | Airtable-Sync live (AirtableClient, Auth, Settings, Registry.sync) |
| Akt 4 | ✅ | Assistent live (AssistantEngine, Insights, Action-Cards mit Bestätigung) |
| Akt 5 | ✅ | Politur, Dark Mode, DMG, Beta-Vorbereitung |
| Post-Akt 5, Aufgabe 1 | ✅ | Auto-Sync bei App-Start (Airtable nach lokalem Cache-Load) |
| Post-Akt 5, Aufgabe 2 | ✅ | AuditStore persistent + Assistant-Bestätigungen protokolliert |
| Post-Akt 5, Aufgabe 3 | ✅ | About-Fenster über App-Menü mit Version 6.0.0 |
| Post-Akt 5, Aufgabe 4 | ✅ | Eigenes App-Icon (`AppIcon.icns`) im Bundle |
| Post-Akt 5, Aufgabe 5 | ✅ | Claude-LLM-Integration im Assistenten (Keychain + Messages API) |
| Post-Akt 5, Aufgabe 6 | 📋 | Clockodo Zuhörer: Zeiten aus Chat/Kalender/Mail → Draft → Wochenabschluss → POST |
| Post-Akt 5, Aufgabe 7 | 📋 | mykilO$$ Vollintegration: `KalkulationsEngineProviding`-Protokoll (✅), `AppState.kalkulationsEngine`-Slot (✅), `Eingehende-Angebote`-Tabelle (✅), Services/UI noch offen |

---

## Build-Fixes aus Akt 2 (erledigt, Commit `553414b`)

Die 4 ursprünglich dokumentierten Stellen (SaveState-Equatable, SourceChip-
Home-Kinds, doppeltes `Color(hex:)`, doppeltes `GridTexture`) sind gefixt.
Beim ersten echten Build kamen weitere reale Bugs hinzu, die hier nicht
dokumentiert waren — Details in [HANDOFF_AKT2.md](docs/handoffs/HANDOFF_AKT2.md)
Nachtrag bzw. im Commit selbst: ein garantierter Laufzeitcrash durch
`WidgetKind(rawValue:)!` auf nicht existierenden Rohwerten, ein Sendable-
Closure-Capture-Fehler in `WidgetBoardStore.save()`, fehlende Modul-
Abhängigkeiten (`MykilosWidgets → MykilosServices`), und ein Datum-Rundtrip-
Bug in `FileBackedRepository` (`.iso8601`/`.secondsSince1970` verlieren beide
Präzision über die Unix-Epoch-Konvertierung — nur `timeIntervalSinceReferenceDate`
ist bitgenau roundtrip-sicher).

---

## Absolute Regeln (nicht verhandelbar)

### Persistenz
- Jeder Schreibvorgang `throws`. Niemals `try?` außer in begründeten, kommentierten Ausnahmen.
- `SaveState` (.idle/.saving/.saved(Date)/.failed(String)) ist in der UI sichtbar.
- Cold-Start-Test für jedes neue persistierbare Feature: schreiben → neue Instanz → lesen → identisch.

### Token-Disziplin (SwiftLint erzwingt das)
- Keine `.font(.system(...))` in Feature-/Widget-Code → `Font.mykHero` etc. aus `MykilosDesign`.
- Keine `Color(red:...)` → `MykColor.drive.color` etc.
- Keine `Color(hex:)` in Widgets/Features → `public` in `MykilosDesign/Tokens.swift` nutzen.

### Secrets
- Tokens, API-Keys, PATs → nur Keychain. Nie in Code, Dateien, Repo, Logs.
- Externe IDs (Airtable-Record, Drive-Folder, ClickUp-Liste) = Referenzen, nie Primärschlüssel.

### Widgets
- Widgets reden NIE direkt miteinander → nur über `StudioContext.emit()`.
- Signale sind VORSCHLÄGE (laut für Einsicht). Schreiben nur über Action-Card → Bestätigung → Audit.
- Jedes Widget hat alle Renderstates: loading / content / empty / permissionRequired / offline / error.
- Quelle ist immer sichtbar (Quellenzeile unten).

### Architektur
- Multi-Target: `App → Widgets → Design`, `Services → Kit`, `Integrations → Kit`.
- `MykilosKit` importiert NIE SwiftUI oder GRDB.
- `MykilosWidgets` importiert NIE GRDB.
- Schreibvorgänge kommen NIE aus Views — nur über Stores.

### Prozess
- Eine Session = ein kleiner PR = ein Handoff (`docs/handoffs/HANDOFF_AKT{n}_S{m}.md`).
- CI ist Merge-Gate: roter Build/Test = kein Merge.
- Keine parallelen Worktrees.

---

## Target-Struktur

```
Sources/
  MykilosKit/          # Foundation ← importiert NICHTS von uns
    Domain/            # Customer, Project, WidgetFoundation, AuditEntry, WidgetBoard
    Persistence/       # Repository, FileBackedRepository, PersistenceError, SaveState
    Signals/           # WidgetSignal, Mediator, StudioContext (@Observable)
  MykilosDesign/       # Tokens (MykColor, MykSpace, MykRadius), Typography, SourceColor
  MykilosServices/     # CachedProjectRegistry, AirtableRegistry, GRDBDatabase,
                       # WidgetBoardStore, NoteStore, GRDB-Records
                       # Google/ — OAuth/PKCE, Loopback-Server, Keychain-Store,
                       #   GoogleAuthService (Akt 3, S1), GoogleDriveClient (S2),
                       #   GoogleAccessTokenProvider + GoogleTokenRefreshService +
                       #   GoogleCalendarClient (Akt 3, S3), GoogleContactsClient (S4),
                       #   GoogleGmailClient (Akt 3, S6)
                       # Clockodo/ — ClockodoClient, ClockodoAuthService,
                       #   KeychainClockodoCredentialsStore (Akt 3, S5)
                       # Airtable/ — AirtableClient, AirtableAuthService,
                       #   KeychainAirtableCredentialsStore (Akt 3, S8)
  MykilosWidgets/      # WidgetContainer, WidgetBoardView, SourceChip, SaveStateBar,
                       # Kinds/ (8 Widgets: drive, tasks, contacts, cash, calendar, notes, mail, assistant)
  MykilosApp/          # Shell (Sidebar), Gallery, Detail, Today, Data (AppState, AppDatabase,
                       # RegistryStore, DemoSeed)

Tests/
  MykilosKitTests/     # Cold-Start-Tests (FileBackedRepository)
  MykilosServicesTests/# WidgetBoardStoreTests (GRDB Cold-Start), GoogleOAuthTests,
                       # GoogleDriveClientTests, GoogleCalendarClientTests,
                       # GoogleContactsClientTests, GoogleGmailClientTests,
                       # ClockodoClientTests, ClockodoAuthServiceTests,
                       # AirtableClientTests, AirtableAuthServiceTests,
                       # GoogleAccessTokenProviderTests (Refresh-Logik mit Fake) —
                       # kein echtes Keychain/Netzwerk im Testlauf, siehe
                       # HANDOFF_AKT3_S1/S2/S3/S4/S5/S6.md
```

---

## Die Palette (Tokens)

```
--paper    #FAF8F3   Grund
--ink      #1A1814   Tinte
--drive    #C26B4A   Terrakotta  → Dateien/Drive
--people   #6E8B6A   Salbei      → Menschen/Kalender
--tasks    #C99A3E   Ocker       → Aufgaben/ClickUp
--cash     #4C6280   Tiefblau    → Geld/Angebote
--personal #8A5B73   Pflaume     → Notizen
--positive #3E7A4E   --critical #B4503C
```
Farbe ist Sprache: man erkennt die Quelle, bevor man liest.

---

## Team-Modell

Persönliches Cockpit, geteilte Instrumente. Jeder hat sein eigenes mykilOS,
sieht durch seine eigene Identität auf die geteilten Drive-Ordner, ClickUp-Tasks, Kalender.
Projekt-Verdrahtung (boardID, Links) über Airtable als System-of-Record.
Kein Sync-Backend in V1.

---

## Nächste Schritte

Akt 0–5 und alle dokumentierten Post-Akt-5-Verfeinerungen sind abgeschlossen.
Die App ist feature-complete für Beta.

**Post-Akt-5 Aufgabe 6 — Clockodo Zuhörer (📋 geplant, Code ausstehend):**
- Ziel: Assistent-Chat-Eingabe → Clockodo-Zeitbuchung. "4h CAD für Heinz" →
  Draft → Wochenabschluss → `POST /api/v2/entries`.
- **Kernregel:** Jeder User bucht/sieht/editiert **nur seine eigenen** Einträge.
  `ClockodoDraftEntry.clockodoUserID` filtert auf GRDB-Ebene.
- **Airtable-Schema live** (Base `appuVMh3KDfKw4OoQ`, seit 2026-06-28):
  - `Clockodo-Nutzer` (`tblPbly2br8mR2kaU`) — 4 Team-Mitglieder mit User-IDs
  - `Clockodo-Buchungen` (`tblYQxlauwej7FD1w`) — Audit-Log bestätigter Buchungen
  - `Clockodo-Leistungen` (`tblRtsegocdpM8CJd`) — 8 Services (bereits vorhanden)
- **6 Schichten:** Intent (Claude parst NLP) → Resolution (Airtable-Lookup) →
  Draft Store (GRDB lokal) → Wochenvorschau → Confirm → POST + AuditEntry.
- Mail/Kalender-Vorschläge: Claude liest GCal + Gmail → schlägt Drafts vor.
  Niemals automatisch buchen — immer erst Bestätigung.
- Vollständige Architektur in
  [HANDOFF_LIVE_WIRING_4.md](docs/handoffs/HANDOFF_LIVE_WIRING_4.md).

**Aus Post-Akt-5 Aufgabe 1 (Auto-Sync bei App-Start):**
- `AppState.bootstrap()` lädt weiterhin zuerst lokale Boards und Registry
  (Demo-Seed + Cache) und stößt danach bei verbundenem Airtable-Status den
  bestehenden `RegistryStore.syncFromAirtable` mit der gespeicherten Base-ID an.
- Der echte Startup-Sync mit Live-Airtable-Credentials bleibt ein manueller
  Beta-Check, weil automatisierte Tests kein echtes Keychain/Netzwerk nutzen.

**Aus Post-Akt-5 Aufgabe 2 (AuditStore):**
- `AuditStore` ist GRDB-backed, `@MainActor @Observable`, nutzt sichtbaren
  `SaveState` und schreibt Audit-Einträge ausschließlich über `append(_:)`.
- `AssistantWidget` schreibt bestätigte `SuggestedAction`s nun als
  `AuditEntry` und zeigt den Audit-Speicherstatus direkt an der Action-Card.
- Der neue Cold-Start-Test `auditEntryUeberlebtNeustart` beweist:
  schreiben → neue Store-Instanz → lesen → identische Audit-Daten.

**Aus Post-Akt-5 Aufgabe 3 (About-Fenster):**
- `MykilOS6App` besitzt ein About-Window (`id: "about"`) und ersetzt den
  macOS-AppInfo-Menüeintrag durch "Über mykilOS 6".
- Das Fenster zeigt App-Name, Version `6.0.0`, Copyright `MYKILOS` und einen
  kurzen Einzeiler mit `MykColor`/`Font.myk...` Design-Tokens.

**Aus Post-Akt-5 Aufgabe 4 (App-Icon):**
- `Sources/MykilosApp/Resources/AppIcon.icns` ist das Bundle-Icon; die
  editierbare 1024px-Quelle liegt daneben als `AppIconSource.png`.
- `script/build_and_run.sh` kopiert das Icon nach `Contents/Resources` und
  schreibt `CFBundleIconFile` in die generierte `Info.plist`.

**Aus Post-Akt-5 Aufgabe 5 (Claude-LLM-Integration):**
- `ClaudeAuthService` speichert Anthropic API-Key und Modell ausschließlich im
  Keychain. Default-Modell: `claude-sonnet-4-6`.
- `ClaudeMessagesClient` ruft die Anthropic Messages API testbar über einen
  injizierbaren HTTP-Client auf; automatisierte Tests prüfen Request-Header,
  Payload und Response-Parsing ohne echten Netzwerkzugriff.
- `AssistantWidget` zeigt weiterhin sofort die regelbasierten Insights und
  lädt nur bei verbundener Claude-Konfiguration zusätzlich eine natürliche
  Zusammenfassung. Schreibaktionen bleiben bestätigungspflichtig und laufen
  weiter über Action-Card → Audit.
- Live-API-Check mit Keychain-Credentials und `claude-sonnet-4-6` war
  erfolgreich; das App-Bundle wurde danach neu gestartet und codesign-verifiziert.

**Bekannte offene Punkte aus Schritt 1 (noch nicht relevant geworden):**
- Ob Google "Desktop App"-OAuth-Clients bei PKCE zusätzlich ein `client_secret`
  verlangen, ist nicht live getestet (V5 unterstützte es optional, V6 aktuell
  nicht) — falls Google beim ersten echten Verbinden `invalid_client` meldet,
  `clientSecret` Parameter in `GoogleOAuthPKCEService` nachziehen.

**Aus Schritt 2 (Drive-Widget):**
- `Sources/MykilosWidgets/WidgetBoardView.swift` (öffentlich, seit Akt 2
  unbenutzt) ist als separater Cleanup-Task geflaggt — falls noch nicht
  erledigt, vor dem nächsten großen Widget-Umbau aufräumen, sonst pflegt man
  zwei Kopien des Dispatch-Switches.

**Aus Schritt 3 (Token-Refresh + Kalender-Widget):**
- Token-Refresh (`GoogleAccessTokenProvider`) ist jetzt zentral verdrahtet und
  von Drive + Kalender genutzt — aber der echte Refresh-Pfad ist nur per
  Unit-Test mit Fake-Refresher abgedeckt, nie live beobachtet (ein Access-Token
  läuft typischerweise erst nach 1 Stunde ab). Beim nächsten Live-Client
  (Mail/Kontakte) im Hinterkopf behalten, falls der erste echte Ablauf
  überraschend anders reagiert als der Test.
- Schlägt ein Refresh fehl (z. B. Refresh-Token wurde widerrufen), landet das
  als generischer `.error("httpError(...)")` im Widget, nicht als
  `.permissionRequired` mit klarem "Bitte neu verbinden"-Hinweis — das ist für
  V1 bewusst einfach gehalten, könnte aber verwirrend sein, falls es in der
  Praxis öfter vorkommt als gedacht.

**Aus Schritt 4 (Kontakte-Widget):**
- `ProjectLinks.contactsQuery` ist eine Freitext-Suche über die echten
  Kontakte des verbundenen Accounts (People API `searchContacts`), keine
  eigene Kontaktliste je Projekt — gleiches Muster wie `calendarQuery`.
  Die Demo-Fantasie-Rollen ("Bauherr"/"Architektin") sind entfallen, die
  People API liefert sie nicht.
- Gleicher offener Punkt wie seit Schritt 1: ob Google "Desktop App"-Clients
  zusätzlich ein `client_secret` verlangen, ist weiterhin nicht live getestet.

**Post-Akt-5 Aufgabe 7 — mykilO$$ Vollintegration (📋 teilweise fertig):**
- **Entscheidung:** mykilO$$ wird nicht mehr als eigenständige App gebaut.
  Alle Kalkulations-Capabilities (EvidenceBasedEstimator, BottomUpCostEngine,
  LearningStore, ReviewCenter 815 Positionen, DeviceCatalog 13.419 Preise,
  PDF Import Pipeline) als Modul in mykilOS 6 integriert. Alle Schreibrechte
  bei mykilOS 6.
- **Erledigt:**
  - `KalkulationsEngineProviding`-Protokoll + Typen in
    `Sources/MykilosKit/Domain/KalkulationsEngineProviding.swift`.
  - `AppState.kalkulationsEngine: (any KalkulationsEngineProviding)?` (nil-Slot).
  - Airtable-Tabelle `Eingehende-Angebote` (`tbliKfs5FnufjdB36`) live.
- **Airtable-Tabellen (alle live):**
  - `Kalkulationen` (`tblO3y2jdmxDnuiZj`)
  - `Kalkulations-Positionen` (`tblNamx3cHTus6gtk`)
  - `Eingehende-Angebote` (`tbliKfs5FnufjdB36`) — SHA256, Lieferant,
    Netto-Summe, Anker-Anzahl, Status, Lern-Gewicht, Importiert-am
- **Verifizierte Architektur (2026-06-28, nach Lesung des echten mykilO$$-Codes):**
  - `KalkulationsCore` (10 Dateien) importiert nur Foundation → eigenes Target
    **`MykilosKalkulationsCore`** (NICHT `MykilosServices/Kalkulation/`, das hat GRDB).
  - Zweistufig: `parse(_:) -> EstimateRequest` (Semantik) dann `estimate(_:)` (Preis).
  - LearningStore in eigener `learning.sqlite` (nicht Haupt-GRDB-Migration).
  - `AirtableSyncService.swift` löschen (ENV-Secrets, fremde Base `appkPzoEiI5eSMkNK`, Blocking).
  - `CostModel.stages` hardcoded → leere Stundensatz-Spalte blockiert Kostenboden nicht.
  - Vollständig + Port-Reihenfolge: [HANDOFF_LIVE_WIRING_5.md → Teil 2](docs/handoffs/HANDOFF_LIVE_WIRING_5.md).
- **✅ BLOCKER GELÖST (2026-06-28):** Alle Geschwister-Typen liegen in den 10
  KalkulationsCore-Dateien (`CarryforwardRule`=Review.swift:33, `GermanNumberParser`=Parsing.swift:3,
  Calibration-Typen in LearningModels.swift). Kompletter verbatim Port der 10 Dateien.
  Reconciliation: `EstimateSession.id` ist `String` → `KostenSchaetzung.id` + `recordAdjustment`
  auf String umstellen. Port-Reihenfolge in Handoff Teil 3.
- **✅ Destillation ENTSCHIEDEN (Johannes): V2-Swift-Pipeline.** `activeAnchors()` liest CSVs;
  die 3.383→204-Destillation (heute externer Python-Code) wird in Swift reimplementiert →
  geschlossener Lernkreis, neue `Preis-Beobachtungen` destillieren automatisch nach. V1 nutzt
  vorhandene CSVs. Plus offen: `gen_lexicon.py` fehlt → MaterialLexicon (149) bleibt manuell.
- **Korpus-Entscheidung (V4_MoneyObservations, 3.383 Beobachtungen):** beides —
  Tabelle `Preis-Beobachtungen` in Mastermind-Base + destilliertes Seed-`sqlite` zur
  Laufzeit; alte Base `appkPzoEiI5eSMkNK` wird stillgelegt.
- **Offene Datenfragen:**
  - Stundensätze in `Clockodo-Leistungen.Stundensatz (€/h)` (`fld4NBokj4MoOy8Uq`)
    noch leer — manuell einzutragen (blockiert Kostenboden aber NICHT, siehe oben).
  - Welche Kategorie-Unterordner unter `05 eingehende Angebote`? (Tischler,
    Stein + was noch?) — nur Johannes kann bestätigen.

---

## Hilfreiche Kommandos

```bash
swift package resolve          # GRDB + Dependencies holen
swift build                    # Kompilieren
swift test                     # Tests (zuerst Cold-Start-Tests)
swift run                      # App starten (ohne Bundle)
./script/build_and_run.sh      # Echtes .app-Bundle in dist/ bauen + starten
                                # (das ist auch die "Run"-Action in Codex)
swiftlint --strict              # Token-Disziplin prüfen
```

**Repo:** https://github.com/JohannesLeoB/mykilOS-6 (privat). Codex-Workflow
und Session-Regeln: `docs/codex/WORKFLOW.md`.

---

## Doku

- `docs/handoffs/HANDOFF_AKT0.md` — Fundament
- `docs/handoffs/HANDOFF_AKT1.md` — App-Shell, Galerie, Widgets
- `docs/handoffs/HANDOFF_AKT2.md` — GRDB, Heute-Board, SaveState
- `docs/handoffs/HANDOFF_AKT3_S1.md` — Google-OAuth-Fundament
- `docs/handoffs/HANDOFF_AKT3_S2.md` — Drive-Widget live
- `docs/handoffs/HANDOFF_AKT3_S3.md` — Token-Refresh + Kalender-Widget live
- `docs/handoffs/HANDOFF_AKT3_S4.md` — Kontakte-Widget live
- `docs/handoffs/HANDOFF_AKT3_S5.md` — Clockodo-Widget live
- `docs/handoffs/HANDOFF_AKT3_S6.md` — Mail-Widget live
- `docs/handoffs/HANDOFF_AKT3_S7.md` — Drag & Drop im Widget-Board
- `docs/handoffs/HANDOFF_AKT3_S8.md` — Airtable-Sync live
- `docs/handoffs/HANDOFF_AKT3.md` — Akt 3 Gesamtübersicht
- `docs/handoffs/HANDOFF_AKT4.md` — Assistent live
- `docs/handoffs/HANDOFF_AKT5.md` — Politur, Dark Mode, DMG
- `docs/handoffs/HANDOFF_POST_AKT5_1.md` — Auto-Sync bei App-Start (Airtable)
- `docs/handoffs/HANDOFF_POST_AKT5_2.md` — AuditStore + Assistant-Protokollierung
- `docs/handoffs/HANDOFF_POST_AKT5_3.md` — About-Fenster mit Versionsnummer
- `docs/handoffs/HANDOFF_POST_AKT5_4.md` — Eigenes App-Icon im Bundle
- `docs/handoffs/HANDOFF_POST_AKT5_5.md` — Claude-LLM-Integration im Assistenten
- `docs/MYKILOS_6_TEAM_MODELL.md` — Team, Airtable, Identität
- `docs/codex/WORKFLOW.md` — Session-Regeln für Codex-Sessions in diesem Repo
- `docs/PARTNER_APP_SCHEMA.md` — Airtable-Gesamtschema (nach Vollintegration): alle Tabellen-IDs, Clockodo-Records, Stundensatz-Priorität
- `docs/KALKULATION_INTEGRATION.md` — mykilO$$ Vollintegrations-Plan: 10 Schritte, GRDB-Migration, UI-Slots, 59 Tests
