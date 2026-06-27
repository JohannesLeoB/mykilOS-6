# MASTER HANDOFF — mykilOS 6 für Codex
**Stand:** 2026-06-28 | **Repo:** https://github.com/JohannesLeoB/mykilOS-6 (privat)
**Branch:** `claude/musing-sammet-3abd94` | **Tests:** 97/97 grün | **Build:** sauber

---

## WAS IST MYKILOS 6?

Persönliches Studio-Cockpit für ein kleines Architektur-/Designbüro. macOS 14+, SwiftUI, **local-first** — alle Daten lokal in GRDB (SQLite), externe Dienste sind Datenquellen, nie Heimat. Die App zieht Daten aus Google Drive, Google Kalender, Gmail, Google Kontakte, Clockodo (Zeiterfassung) und Airtable (System of Record). Sie schreibt Buchungen und Kalkulationen zurück — aber **niemals ohne Nutzer-Bestätigung**.

Ein Nutzer = ein mykilOS. Jeder sieht nur seine eigenen Zeiten. Alle schreiben in dieselbe Airtable-Mastermind-Base.

---

## ARCHITEKTUR — TARGETS UND GRENZEN

```
MykilosKit          → Foundation only. Kein SwiftUI, kein GRDB, nichts von uns.
                      Domain-Typen: Project, Customer, WidgetSignal, AuditEntry, SaveState
                      Signals: StudioContext (@Observable), Mediator, WidgetSignal

MykilosDesign       → Tokens: MykColor, MykSpace, MykRadius, Font.myk*, Color(hex:)
                      KEINE Logik. Nur Aussehen.

MykilosServices     → GRDB, Keychain, Netzwerk. KEIN SwiftUI.
                      Google/: OAuth, Drive, Calendar, Contacts, Gmail, TokenRefresh
                      Clockodo/: Client, Auth, Keychain-Store
                      Airtable/: Client, Auth, Registry, Keychain-Store
                      Claude/: ClaudeMessagesClient, ClaudeAuthService
                      AssistantEngine.swift (liest Signale → Insights, rein synchron)

MykilosWidgets      → SwiftUI-Widgets. Kein GRDB direkt.
                      Kinds/: DriveWidget, CalendarWidget, ContactsWidget, MailWidget,
                              TasksWidget, CashWidget, NotesWidget, AssistantWidget

MykilosApp          → Shell: SidebarView, ContentView, AppState, AppDatabase, DemoSeed
                      Gallery: ProjectGalleryView, ProjectCard
                      Detail: ProjectDetailView, ProjectHeroView, ProjectFilesTabView
                      Today: TodayView, HomeBoardView, FocusWidget, ProjectFavoritesWidget
                      Settings: SettingsView
```

**Schichtregeln (nicht verhandelbar):**
- `MykilosKit` importiert NICHTS von uns
- `MykilosWidgets` importiert KEIN GRDB
- Schreibvorgänge kommen NIE aus Views — nur aus Stores/Services
- Widgets reden nie direkt miteinander — nur über `StudioContext.emit(signal)`

---

## SIGNAL-SYSTEM (wie die App intern kommuniziert)

Widgets emittieren typisierte Signale an `StudioContext`. Der `Mediator` leitet ggf. ein abgeleitetes Signal ab. Signale sind **Vorschläge** — sie erzeugen Insights im `AssistantWidget`, führen aber nie automatisch eine Aktion aus.

```swift
// WidgetSignal (MykilosKit/Signals/WidgetSignal.swift):
case projectFocused(projectID: String)
case driveFileAdded(projectID: String, fileName: String)   // ← NEU: DriveWidget emittiert das nach Load
case offerDetected(projectID: String, label: String)
case reviewSuggested(projectID: String, label: String)
case budgetThresholdCrossed(projectID: String, ratio: Double)
case deadlineNear(projectID: String, days: Int)
```

Schreiben passiert nur über: **Assistent-ActionCard → Nutzer bestätigt → AuditEntry → Service-Aufruf**

---

## AIRTABLE — DAS NERVENSYSTEM

**Mastermind-Base:** `appuVMh3KDfKw4OoQ` ← das ist DIE Base. Alles andere ist verboten.
**Keychain-Keys:** Service `com.mykilos6.airtable`, Account `pat` und `baseID`
**PAT lesen:** `security find-generic-password -s "com.mykilos6.airtable" -a "pat" -w`

> ⚠️ BEKANNTER FEHLER: Im Keychain-Feld `baseID` steht aktuell ein zweites PAT-Token statt der Base-ID `appuVMh3KDfKw4OoQ`. Nutzer muss in App-Einstellungen → Airtable die Base-ID korrekt eintragen.

### Alle Tabellen (Stand 2026-06-28)

| Tabelle | ID | Im Code? | Zweck |
|---|---|---|---|
| `Kunden` | `tblsz4i1CqpBZUE0N` | ✅ | Stammdaten Auftraggeber |
| `Projekte` | `tblGJR13OliFt6Ewi` | ✅ | Projektstamm, Drive-Ordner-ID, Queries |
| `Kontakte` | `tblncfQzQa8TzCZQC` | ❌ Code fehlt | 914 Kontakt-Records |
| `Externe Systeme` | `tbl8aoORULVVtphE0` | ❌ Code fehlt | Drittanbieter-Referenzen |
| `Clockodo-Leistungen` | `tblRtsegocdpM8CJd` | ❌ Code fehlt | 8 Services + Stundensätze |
| `Clockodo-Nutzer` | `tblPbly2br8mR2kaU` | ❌ Code fehlt | 4 Team-User mit Clockodo-IDs |
| `Clockodo-Buchungen` | `tblYQxlauwej7FD1w` | ❌ Code fehlt | Master-Audit-Log aller Buchungen |
| `Kalkulationen` | `tblO3y2jdmxDnuiZj` | ❌ Code fehlt | Kalkulations-Ergebnisse je Projekt |
| `Kalkulations-Positionen` | `tblNamx3cHTus6gtk` | ❌ Code fehlt | Zeilen-Positionen der Kalkulation |
| `Eingehende-Angebote` | `tbliKfs5FnufjdB36` | ❌ Code fehlt | PDF-Corpus, SHA256-Dedup |

**Was `AirtableRegistry` heute liest:** nur `Kunden` + `Projekte` → befüllt `RegistryStore`
**Was `AirtableClient` heute schreiben kann:** `createRecord()` via `AirtableCreating`-Protokoll (neu, seit 2026-06-28)

**Absolute Verbote:**
- Fremde Base `appkPzoEiI5eSMkNK` (alte mykilO$$$-Base): KEIN Lesen, KEIN Schreiben
- Google Drive: nur lesen, nie schreiben/verschieben/umbenennen
- Sevdesk: gar nicht berühren
- Secrets: nie in Code, Logs, Commits — nur Keychain

---

## WAS HEUTE WIRKLICH FUNKTIONIERT

| Bereich | Status | Datei/Details |
|---|---|---|
| Google OAuth (PKCE) | ✅ live | `GoogleAuthService.swift`, Token im Keychain |
| Token-Refresh | ✅ live | `GoogleAccessTokenProvider.swift` |
| Drive-Widget | ✅ live | liest Datei-Liste aus `project.links.driveFolderID` |
| Drive → Assistent-Signal | ✅ live | `DriveWidget` emittiert `driveFileAdded` nach Load |
| Files-Tab (Projektdetail) | ✅ live | `ProjectFilesTabView.swift`, Unterordner-Navigation |
| Kalender-Widget | ✅ live | `GoogleCalendarClient`, Query-gefiltert |
| Kontakte-Widget | ✅ live | `GoogleContactsClient`, Query-gefiltert |
| Mail-Widget | ✅ live | `GoogleGmailClient`, max 10 Treffer |
| Notizen-Widget | ✅ live | GRDB-persistent, Autosave |
| Assistent-Widget | ✅ live | Signal→Insight, Claude-LLM-Zusammenfassung |
| Claude API | ✅ live | `ClaudeAuthService`, Key im Keychain, `claude-sonnet-4-6` |
| Airtable-Sync (Kern) | ✅ live | `RegistryStore.syncFromAirtable()` |
| Airtable createRecord | ✅ live | `AirtableClient` konform zu `AirtableCreating` |
| Audit-Store | ✅ live | GRDB-persistent, AuditEntry |
| Widget Drag & Drop | ✅ live | Home + Projektdetail |
| Clockodo-Auth | ✅ Key gespeichert | Widget zeigt aber nur Demo-Daten |
| Tasks-Widget | ❌ Demo | `demoTasks`, kein ClickUp-Backend |
| Cash-Widget | ❌ Demo | Signal-Simulation, kein echtes Budget |
| Clockodo-Widget | ❌ Demo | `demoActivity`, nie live geschaltet |
| User-Identität | ❌ fehlt | Nach Login kein Name/Email sichtbar |
| Heute → Projektdetail | ❌ fehlt | MiniProjectCard ist nicht klickbar |
| Drive-Ordner-Links | ❌ fehlt | Kein "In Drive öffnen"-Button |
| Projektdetail Tabs | ⚠️ 2/5 live | overview ✅ files ✅ offers/timeline/material ❌ Stubs |
| Hell/Dark/System-Schalter | ❌ fehlt | Folgt automatisch macOS, kein eigener Toggle |
| User Avatar | ❌ fehlt | Nicht implementiert |
| Crash-Reporting | ❌ fehlt | Kein System vorhanden |
| Kalkulations-Engine | ❌ Port fehlt | Protokoll ✅, nil-Slot ✅, 10 Core-Dateien noch nicht portiert |

---

## WAS NICHT GEÄNDERT WERDEN DARF

| Regel | Konsequenz |
|---|---|
| `try?` ohne Kommentar bei Schreibvorgängen | SwiftLint-Fehler |
| Neues persistentes Feature ohne Cold-Start-Test | Nicht mergebar (Projektgesetz) |
| `import GRDB` in MykilosKit oder MykilosWidgets | Build-Fehler / Architekturverletzung |
| Design-Tokens umgehen (`.font(.system(...))`, `Color(red:...)`) | SwiftLint |
| Schreiben aus Views statt aus Stores | Architekturverletzung |
| Secrets in Code / ENV / Logs / Commits | Sofort revertieren |
| Drive schreiben | Absolutes Verbot |
| Sevdesk berühren | Absolutes Verbot |
| Fremde Airtable-Base `appkPzoEiI5eSMkNK` | Absolutes Verbot |

---

## CONNECTOR-CHECK (vor jeder Session)

```bash
# 1. Build + Tests
swift build && swift test

# 2. App starten
./script/build_and_run.sh

# 3. Airtable prüfen (Skript liest PAT aus Keychain)
./script/airtable_verify.sh

# 4. Branch prüfen
git status && git log --oneline -5
```

Erwarteter Stand: 97 Tests grün, letzter Commit enthält "Drive live in Files tab".

**Bekanntes Problem Airtable-Check:**
`airtable_verify.sh` meldet alle Tabellen als 404, weil im Keychain-Feld `baseID` fälschlich ein zweites PAT steht. Fix: App öffnen → Einstellungen → Airtable → Base-ID-Feld: `appuVMh3KDfKw4OoQ` eintragen → Speichern.

---

## SESSION-PLAN FÜR CODEX (Reihenfolge einhalten)

### SESSION A — User-Identität nach Login

**Warum:** Nach Google-Login weiß die App nicht wer eingeloggt ist. Kein Name, keine Email sichtbar.
**Was:** `GoogleAuthService` → nach Token-Tausch `GET /oauth2/v2/userinfo` → `GoogleUserInfo(email, displayName)` → im Keychain cachen → `AppState.currentGoogleUser` → in `SidebarView` unten anzeigen.
**Dateien:** `GoogleAuthService.swift`, `AppState.swift`, `SidebarView.swift`
**Test:** `GoogleUserInfoTests` — JSON-Parsing ohne Netzwerk
**Handoff:** `docs/handoffs/HANDOFF_SESSION_A.md`

---

### SESSION B — Clockodo-Widget live

**Warum:** `ClockodoClient` ist fertig, Key im Keychain. `ClockodoWidget` zeigt aber `demoActivity`.
**Was:** `demoActivity` entfernen. Echter Lade-Flow: `ClockodoClient.getEntries(userID:from:to:)` für heute. Renderstates: loading/content/empty/error/permissionRequired. Quellenzeile: `Clockodo · {email}`. **Kernregel:** Einträge nur für den eingeloggten Clockodo-User (nicht cross-user).
**Dateien:** `Sources/MykilosWidgets/Kinds/ClockodoWidget.swift` (oder Pfad prüfen mit `find`)
**Test:** Fake-Client, alle Renderstates
**Handoff:** `docs/handoffs/HANDOFF_SESSION_B.md`

---

### SESSION C — Heute → Projektdetailseite (Navigation)

**Warum:** `MiniProjectCard` in `ProjectFavoritesWidget` (Heute-Board) ist nicht klickbar. Kein Weg von der Heute-Ansicht zur Projektdetailseite.
**Was:**
1. `selectedProject: Project?` aus `ProjectGalleryView` in `ContentView` hochziehen als `@State`
2. `TodayView` bekommt Callback `onOpenProject: (Project) -> Void`
3. `ProjectFavoritesWidget` bekommt denselben Callback
4. `MiniProjectCard` bekommt `onTap: () -> Void` — klick setzt `module = .projects` + `selectedProject`
5. `ProjectGalleryView` bekommt `deepLink: Binding<Project?>` — `.onChange` öffnet Detail direkt
**Dateien:** `MykilOS6App.swift`, `TodayView.swift`, `ProjectFavoritesWidget.swift`, `ProjectGalleryView.swift`
**Test:** Kein GRDB nötig — nur UI-State-Logik testen
**Handoff:** `docs/handoffs/HANDOFF_SESSION_C.md`

---

### SESSION D — Drive-Ordner-Links überall

**Warum:** User will auf Drive-Ordner klicken können wo immer Projektdateien sichtbar sind. Drive-URL aus Folder-ID: `https://drive.google.com/drive/folders/{folderID}`
**Was:**
1. `ProjectHeroView` → Drive-Icon-Button oben rechts, sichtbar wenn `project.links.driveFolderID != nil` → öffnet Ordner-URL im Browser
2. `DriveWidget` → "Ordner öffnen ↗" in Widget-Header
3. `ProjectFilesTabView` → "In Drive öffnen" rechts im Breadcrumb-Bereich
4. Keine neue Infrastruktur — `NSWorkspace.shared.open(url)` reicht
**Dateien:** `ProjectHeroView.swift`, `DriveWidget.swift`, `ProjectFilesTabView.swift`
**Test:** URL-Konstruktion Unit-Test (`folderID → korrekte URL`)
**Handoff:** `docs/handoffs/HANDOFF_SESSION_D.md`

---

### SESSION E — Settings ausbauen (Theme + Avatar)

**Warum:** Settings hat nur 4 API-Credential-Sektionen. Kein Theme-Toggle, kein Profilbild.
**Was:**
1. **Appearance-Sektion** in `SettingsView`: Segmented Control Light/Dark/System → speichert in `UserDefaults` (kein Keychain nötig) → `.preferredColorScheme()` in `ContentView` setzen
2. **Profil-Sektion**: Avatar hochladen via `NSOpenPanel` (PNG/JPEG, max 512px) → resizen → als Data in UserDefaults → in `SidebarView` als kleines rundes Bild anzeigen
**Dateien:** `SettingsView.swift`, `SidebarView.swift`, `ContentView.swift`
**Test:** Avatar-Resize-Test (keine UI nötig)
**Handoff:** `docs/handoffs/HANDOFF_SESSION_E.md`

---

### SESSION F — Kalkulations-Engine portieren (Teil 1: Core-Target)

**Voraussetzung:** Sessions A–E abgeschlossen oder unabhängig startbar (F ist unabhängig)
**Vollständige Anweisung:** `docs/handoffs/CODEX_HANDOFF_KALKULATION.md` — dort steht alles.
**Kurzfassung:**
1. `KostenSchaetzung.id: String` + `erstelltAm: Date` in `KalkulationsEngineProviding.swift` ergänzen; `recordAdjustment(schaetzungsID:)` von UUID auf String ändern
2. `MykilosKalkulationsCore` Target in `Package.swift` + neues Verzeichnis `Sources/MykilosKalkulationsCore/`
3. 10 Dateien verbatim aus `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilO$$$/ClaudeCode_Final_Handoff_2026-06-26/04_PROJECT/MYKILOSKalkulationslabor/Sources/MYKILOSKalkulationslabor/` kopieren (alle Foundation-only)
4. `AirtableSyncService.swift` löschen (3 Regelverstöße: ENV-Secrets, fremde Base, DispatchSemaphore)
5. `swift build` grün
**Handoff:** `docs/handoffs/HANDOFF_SESSION_F.md`

---

### SESSION G — Kalkulations-Engine portieren (Teil 2: Adapter + LearningStore)

**Voraussetzung:** Session F abgeschlossen
**Was:**
1. `KalkulationsEngine: KalkulationsEngineProviding` in `Sources/MykilosServices/Kalkulation/` — bindet `MykilosKalkulationsCore` ein, `parse()` → `estimate()` chain
2. `KalkulationsLearningStore` in eigener `learning.sqlite` (NICHT in Haupt-GRDB-Migration!)
3. Cold-Start-Test für LearningStore (Pflicht, Merge-Gate)
4. `AppState.bootstrap()` setzt `kalkulationsEngine = KalkulationsEngine(seedDirectory:)` wenn Seed-Dateien vorhanden
**Handoff:** `docs/handoffs/HANDOFF_SESSION_G.md`

---

### SESSION H — Angebote-Tab (Kalkulations-UI)

**Voraussetzung:** Session G abgeschlossen
**Was:** Tab "Angebote" in Projektdetailseite — zeigt Preisspanne/Kostenboden/Evidence, Freitext-Eingabe → `schaetze()` → ActionCard → Bestätigung → Airtable `Kalkulationen`-Record + AuditEntry. Sichtbar nur wenn `appState.kalkulationsEngine != nil`.
**Handoff:** `docs/handoffs/HANDOFF_SESSION_H.md`

---

### SESSION I — Clockodo Zuhörer (Chat → Zeitbuchung)

**Voraussetzung:** Session B abgeschlossen
**Vollständige Architektur:** `docs/handoffs/HANDOFF_LIVE_WIRING_4.md`
**Was:** Assistent-Chat erkennt "4h CAD für Heinz" → Claude parst Intent → Airtable-Lookup `Clockodo-Nutzer` + `Clockodo-Leistungen` → GRDB-Draft → Wochenvorschau → Nutzer bestätigt → POST Clockodo API + AuditEntry. **Niemals automatisch buchen.**
**Kernregel:** Jeder User bucht/sieht/editiert nur seine eigenen Einträge. `clockodoUserID` filtert auf GRDB-Ebene.
**Handoff:** `docs/handoffs/HANDOFF_SESSION_I.md`

---

## WIE HANDOFFS FUNKTIONIEREN

Jede Session schreibt beim Abschluss:
1. `docs/handoffs/HANDOFF_SESSION_{X}.md` — was entstand, neue Tests, was bewusst offen blieb, nächster Schritt
2. `CLAUDE.md` Status-Tabelle aktualisieren (Zeile des entsprechenden Akts/Tasks)
3. `swift build` + `swift test` grün bestätigen
4. `./script/build_and_run.sh` — App startet, Feature manuell prüfen
5. Commit mit sprechendem Message, push auf `claude/musing-sammet-3abd94`

**Commit-Stil:** `feat: kurze Beschreibung (Session X)` oder `fix: was und warum`
**Nie:** `try?` ohne Kommentar, Secrets im Commit, zwei Sessions in einem Commit bündeln

---

## DESIGN-SYSTEM (Tokens — immer verwenden)

```swift
// Farben (MykColor.X.color):
.paper        // #FAF8F3  Hintergrund
.ink          // #1A1814  Text
.drive        // #C26B4A  Terrakotta — Drive/Dateien
.people       // #6E8B6A  Salbei     — Kontakte/Kalender
.tasks        // #C99A3E  Ocker      — Aufgaben
.cash         // #4C6280  Tiefblau   — Geld/Angebote
.personal     // #8A5B73  Pflaume    — Notizen/Mail
.positive     // #3E7A4E  Grün
.critical     // #B4503C  Rot
.muted        // Gedämpft
.faint        // Sehr gedämpft
.line         // Trennlinien

// Schriften: Font.mykDisplay, .mykTitle, .mykHeadline, .mykBody, .mykSmall, .mykCaption, .mykMono(size)
// Abstände: MykSpace.s3 (4pt) bis MykSpace.s9 (32pt)
// Radien: MykRadius.sm, .md, .lg
```

Farbe ist Sprache: man erkennt die Quelle, bevor man liest.

---

## WICHTIGE DATEIPFADE

```
Package.swift                                    → Target-Definitionen, Dependencies
Sources/MykilosKit/Domain/Project.swift          → Project, Customer, ProjectLinks
Sources/MykilosKit/Domain/KalkulationsEngineProviding.swift → Protokoll-Socket (UUID→String noch offen)
Sources/MykilosKit/Signals/WidgetSignal.swift    → alle Signal-Typen
Sources/MykilosKit/Signals/StudioContext.swift   → emit(), signals(for:), focus()
Sources/MykilosServices/Airtable/AirtableClient.swift → fetch + createRecord
Sources/MykilosServices/Airtable/AirtableAuthService.swift → Keychain-Keys: com.mykilos6.airtable
Sources/MykilosServices/Google/GoogleDriveClient.swift → listFolder(), GoogleDriveFile
Sources/MykilosServices/AssistantEngine.swift    → mapSignal() → AssistantInsight
Sources/MykilosApp/Data/AppState.swift           → bootstrap(), alle Service-Instanzen
Sources/MykilosApp/Shell/MykilOS6App.swift       → ContentView, AppModule, Navigation
Sources/MykilosApp/Detail/ProjectDetailView.swift → Tabs, Widget-Dispatch
Sources/MykilosApp/Detail/ProjectFilesTabView.swift → Drive-Browser, neu (2026-06-28)
Sources/MykilosApp/Gallery/ProjectGalleryView.swift → selectedProject-Navigation
Sources/MykilosApp/Today/ProjectFavoritesWidget.swift → MiniProjectCard (noch nicht klickbar)
Sources/MykilosApp/Today/TodayView.swift         → Heute-Board
script/build_and_run.sh                          → baut .app in dist/
script/airtable_verify.sh                        → prüft alle 10 Tabellen via curl
docs/handoffs/CODEX_HANDOFF_KALKULATION.md      → vollständige Kalkulation-Portierung
docs/handoffs/CODEX_SESSIONS.md                 → Session-Übersicht (A–F, ältere Version)
docs/KALKULATION_INTEGRATION.md                 → Gesamtplan Kalkulation
docs/PARTNER_APP_SCHEMA.md                      → vollständiges Airtable-Schema
```

---

## mykilO$$$ QUELL-CODEBASE

Nur lesen. Nie verändern.
```
/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilO$$$/
  ClaudeCode_Final_Handoff_2026-06-26/04_PROJECT/MYKILOSKalkulationslabor/
    Sources/MYKILOSKalkulationslabor/   ← 10 Swift-Dateien, Foundation-only
```
Die 10 Dateien: `AirtableOffer.swift`, `BottomUpCost.swift`, `ComponentResolver.swift`, `Estimation.swift`, `LearningModels.swift`, `MaterialLexicon.swift`, `Models.swift`, `Parsing.swift`, `Review.swift`, `Version.swift`

**Einstieg zweistufig:** `parse(freitext) → EstimateRequest` → `estimate(request) → EstimateResult`
`estimate()` nimmt KEINEN Freitext.
