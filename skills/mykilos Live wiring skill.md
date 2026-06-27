---
name: mykilos-live-wiring
description: >
  Session-Skill für die konzentrierte Beta-Wiring-Session in mykilOS 6.
  Verwende diesen Skill immer dann, wenn echte Google Drive-, Mail-, Kalender-
  oder Claude-Assistenten-Daten in die laufende mykilOS-6-App gedrähtet werden
  sollen. Steuert die gesamte Session: Architekturentscheidungen, Phasenplan,
  Codex-Prompts, ExternalMappingRegistry (Bibliothekarin), OAuth-Setup,
  Streaming-Nodes, Review-Gates und Handoff. Trigger auch bei: "Drive anbinden",
  "Live-Import", "echte Daten", "OAuth", "Mapping wiren", "Bibliothekarin",
  "Beta-Test", "Dateien wiren", "Mail in App", "Kalender in App",
  "Assistent in App".
---

# mykilOS 6 — Beta Live Wiring Skill

## Rolle dieses Skills

Du bist Architekt und Session-Dirigent für die konzentrierte Beta-Wiring-Session.
Dein Ziel: Drive, Mail, Kalender und Claude-Assistent zuverlässig, sauber und
recovery-fähig in die App-Nodes drähten — in einer einzigen fokussierten Session.

Alles bisher in der App ist Dummy-Daten. Diese Session ist der erste echte Wire.

---

## Verbindliche Grundregeln (nicht verhandelbar)

- Local-first. Interne IDs primär. Externe IDs sind nur Referenzen.
- Keine externe Quelle schreibt direkt in Core.
- Jeder Import: Archiv → Extraktion → Staging → Review → Core → Audit.
- Keine API-Schreibaktion direkt aus Views.
- Tokens niemals in SQLite, Markdown oder Logs. Nur in der Keychain.
- Drive: strikt lesend. Löschen / Verschieben / Umbenennen existiert nicht.
- Mail: Senden nur nach Vorschau + expliziter Bestätigung.
- Kalender: Anlegen / Ändern nur nach Vorschau + expliziter Bestätigung.
- Assistent: schlägt vor, schreibt nie autonom in Core.
- Externe Daten sind unantastbar: nichts Bestehendes wird verändert.

---

## Das Rückgrat: ExternalMappingRegistry (die Bibliothekarin)

Bevor irgendein Live-Wire gebaut wird, muss dieses Core-Model existieren.
Es ist der einzige Ort, der weiß, wo alles verknotet ist.

### Datenmodell `ExternalMapping`

```swift
struct ExternalMapping: Identifiable, Codable {
    let id: UUID                        // interne mykilOS-ID (primär)
    let internalType: InternalEntityType // .customer | .project
    let internalID: UUID                // FK auf Customer oder Project
    let system: ExternalSystem          // .drive | .mail | .calendar | .clockodo | .sevdesk | .clickup | .contacts
    let externalStableID: String        // unveränderliche externe ID (Drive fileID, etc.)
    var externalDisplayName: String     // Cache: aktueller Name/Label
    var externalPath: String?           // Cache: aktueller Pfad (nur Anzeige)
    var status: MappingStatus           // .unmatched | .suggested | .confirmed | .renamed | .orphaned | .error
    var confidence: MappingConfidence   // .auto | .manual | .ambiguous
    var lastSeenAt: Date
    var confirmedAt: Date?
    var confirmedBy: String?            // User-ID
    let createdAt: Date
    var auditLog: [MappingAuditEntry]
}

enum InternalEntityType: String, Codable { case customer, project }

enum ExternalSystem: String, Codable {
    case drive, mail, calendar, clockodo, sevdesk, clickup, contacts
}

enum MappingStatus: String, Codable {
    case unmatched    // Drive-Ordner gefunden, noch kein interner Match
    case suggested    // Parser hat Match vorgeschlagen, Mensch noch nicht bestätigt
    case confirmed    // explizit bestätigt, Binding läuft über stableID
    case renamed      // stableID gleich, Name/Pfad hat sich geändert, Cache aktualisiert
    case orphaned     // interne Entität existiert, externe ID nicht mehr auffindbar
    case error        // letzter Sync-Versuch fehlgeschlagen
}

struct MappingAuditEntry: Codable {
    let timestamp: Date
    let event: String          // "renamed", "confirmed", "orphaned", "recovered"
    let oldValue: String?
    let newValue: String?
    let triggeredBy: String    // "system" | user-ID
}
```

### Warum fileID und nicht Pfad

Drive-`fileID` ist permanent und ändert sich nie — auch nicht bei Umbenennung,
Verschiebung oder Neustrukturierung des Schemas. Name und Pfad sind nur ein
zwischengespeichertes Etikett (Cache). Bei jeder Sync-Runde wird der Cache
nachgezogen. Der `NSCocoaErrorDomain Code 260` ist das direkte Symptom des
alten pfad-basierten Ansatzes — dieses Modell behebt ihn strukturell.

### Recovery

Geht der lokale Cache verloren, baut sich die Registry neu auf:
Drive-Ordner per fileID neu abfragen → DisplayName/Path aktualisieren →
Status bleibt `confirmed`. Kein manuelles Eingreifen nötig.

---

## Session-Phasen

Die Session läuft in vier Phasen. Keine Phase überspringen.
Jede Phase endet mit einem expliziten Gate-Check.

---

### Phase 0 — Voraussetzungen prüfen (max. 15 min)

**Ziel:** Sicherstellen, dass der Boden für alles Weitere sauber ist.

Checkliste:
- [ ] Repo `mykilOS-6` ist aktuell, sauber (kein dirty working tree), letzter Build grün.
- [ ] Google Cloud Projekt `mykilOS Studio OS` existiert, OAuth-Client-ID ist konfiguriert.
- [ ] Scopes bereits genehmigt: `userinfo.email`, `userinfo.profile`, `openid`,
      `drive.readonly`, `drive.appdata`, `drive.file` (nur für neu erstellte Ordner),
      `calendar.readonly`, `calendar.events` (write nur nach Confirm), `gmail.send`.
- [ ] `GoogleSignIn` oder `AppAuth` Swift Package im Projekt vorhanden.
- [ ] Keychain-Wrapper für Token-Ablage vorhanden oder als erster Build-Step geplant.
- [ ] `ExternalMapping`-Model noch nicht im Core → wird in dieser Session angelegt.

**Gate:** Alle Häkchen gesetzt → Phase 1 freigeben.
Fehlt etwas → erst beheben, dann weitermachen.

**Codex-Prompt Phase 0:**
```
Prüfe den aktuellen Build-Status von mykilOS-6. Gib mir aus:
1. git status + letzten Commit
2. Ob GoogleSignIn oder AppAuth im Package.swift referenziert ist
3. Ob eine KeychainHelper- oder TokenStore-Klasse bereits existiert
4. Ob ein ExternalMapping-Model existiert
Repariere nichts, nur berichten.
```

---

### Phase 1 — Keychain + OAuth Multi-Account (max. 45 min)

**Ziel:** Jeder Nutzer kann sich mit persönlichem Google-Account UND Team-Account
(info@mykilos.com) einloggen. Tokens landen ausschließlich in der Keychain.
Views haben keinen direkten Zugriff auf Tokens.

#### 1.1 Modelle

```swift
struct UserProfile: Identifiable, Codable {
    let id: UUID
    let displayName: String
    let email: String
    let accountType: AccountType     // .personal | .team
    let role: AppRole                // .admin | .projektleitung | .mitarbeiter
    var isActiveSession: Bool
    let createdAt: Date
}

enum AccountType: String, Codable { case personal, team }
enum AppRole: String, Codable { case admin, projektleitung, mitarbeiter }

struct LinkedAccounts: Codable {
    let userID: UUID
    var personalAccount: OAuthAccountRef?
    var teamAccount: OAuthAccountRef?
}

struct OAuthAccountRef: Codable {
    let email: String
    let keychainKey: String          // Key für sicheren Keychain-Zugriff
    var scopes: [String]
    var lastRefreshedAt: Date?
}
```

#### 1.2 TokenStore (Keychain, kein SQLite)

```swift
// Nur Interface hier — Implementierung in KeychainTokenStore.swift
protocol TokenStoring {
    func save(token: String, for key: String) throws
    func load(for key: String) throws -> String
    func delete(for key: String) throws
}
// Keychain-Key-Schema: "mykilOS.oauth.\(userID).\(accountType)"
// Niemals Token in UserDefaults, SQLite, Logs oder Markdown.
```

#### 1.3 Scopes

Lesend (kein Confirm nötig):
- `drive.readonly` — Drive durchsuchen, Metadaten + Dateiinhalte lesen
- `drive.appdata` — App-eigene Konfiguration in Drive speichern
- `calendar.readonly` — Kalendereinträge lesen
- `userinfo.email`, `userinfo.profile`, `openid` — Nutzeridentität

Schreibend (immer Confirm-Flow vorschalten):
- `drive.file` — nur neu von der App erstellte Ordner/Dateien
- `calendar.events` — Kalendereinträge anlegen/ändern
- `gmail.send` — Mail senden

**Gate Phase 1:**
- Build grün, kein Compiler-Fehler.
- Token wird in Keychain gespeichert und geladen (Unit-Test grün).
- Kein Token in SQLite, Logs oder Markdown nachweisbar.
- `UserProfile` + `LinkedAccounts` sind im Core-Model.
- HANDOFF_PHASE1.md committed und gepusht.

**Codex-Prompt Phase 1:**
```
Implementiere in mykilOS-6:
1. KeychainTokenStore.swift mit save/load/delete, Key-Schema:
   "mykilOS.oauth.<userID>.<accountType>"
2. UserProfile.swift + LinkedAccounts.swift als Codable-Structs
   (Felder exakt wie in SKILL.md Phase 1.1)
3. GoogleOAuthService.swift: initiiert OAuth-Flow für personal + team Account,
   speichert Tokens ausschließlich über KeychainTokenStore,
   niemals direkt in SQLite, UserDefaults oder Logs
4. Unit-Test: Token speichern → laden → löschen → verify
Nicht bauen: Views, UI, Drive-Abfragen — nur Foundation.
Build muss grün sein. Dann HANDOFF_PHASE1.md schreiben.
```

---

### Phase 2 — ExternalMappingRegistry + Drive-Scan (max. 60 min)

**Ziel:** Drive-Ordner unter `PROJEKTE/` werden gescannt, mit fileID geankt,
tolerant geparst und in die Registry geschrieben. Alles review-first.

#### 2.1 Drive-Scan-Service

```swift
// DriveProjectScanService.swift
// Liest via Drive API v3: files.list mit q="mimeType='application/vnd.google-apps.folder'
//   and '<PROJEKTE_FOLDER_ID>' in parents" + fields="files(id,name,parents,modifiedTime)"
// Gibt [DriveFolder] zurück — kein direkter Core-Schreibzugriff
struct DriveFolder {
    let fileID: String               // stabile Drive-ID — der Anker
    let name: String                 // z.B. "2026_001_MYKILOS_Serienkueche"
    let parents: [String]
    let modifiedTime: Date
}
```

#### 2.2 Toleranter Ordner-Name-Parser

Das Schema ist nicht konsistent — der Parser darf nie hart fehlschlagen.

```swift
struct ParsedProjectFolder {
    let fileID: String               // immer gesetzt (aus Drive)
    let year: Int?                   // 2026 — optional
    let sequenceNumber: Int?         // 001 — optional, toleriert "20" statt "020"
    let customerSlug: String?        // "MYKILOS", "BenjaminMartin" — optional
    let locationCode: String?        // "FUN16", "HEI64" — optional
    let rawName: String              // immer: Original-Ordnername
    let parseConfidence: ParseConfidence
}
enum ParseConfidence { case full, partial, unreadable }
// Unreadable → Status .unmatched in Registry
// Partial → Status .suggested, Mensch bestätigt
// Full → Status .suggested (immer erst vorschlagen, nie auto-confirmed)
```

#### 2.3 Registry-Sync-Ablauf

```
Drive API (fileID + name + path)
    → DriveProjectScanService (lesen, niemals schreiben)
    → FolderParser (tolerant, kein hard-fail)
    → StagingBuffer (temporär, nicht in Core)
    → MappingReviewQueue (UI: Review-Maske)
    → [Nutzer bestätigt] → ExternalMappingRegistry (Core)
    → AuditLog
```

Kein Drive-Ordner darf ohne Nutzer-Bestätigung in Core landen.
Status `suggested` = sichtbar in Review-Maske, noch nicht Core.
Status `confirmed` = nach expliziter Bestätigung, erst dann Core.

#### 2.4 Review-Maske (minimal-UI)

Zeigt pro ungemapptem Ordner:
- Ordnername (roh)
- Geparste Felder (Jahr, Nr., Kunde, Code)
- Vorgeschlagene interne Entität (Kunde/Projekt, falls Match)
- Confidence-Indikator
- Aktionen: "Bestätigen" | "Ablehnen" | "Manuell zuordnen"

Fehler-/Leerzustand: "Keine offenen Mappings" — kein Crash, kein leerer Screen.

**Gate Phase 2:**
- Drive-Scan läuft, gibt [DriveFolder] zurück (Unit-Test mit Mock-Response grün).
- Parser läuft für alle Namens-Varianten aus Bild 9 (2023_010_, 2026_20_, etc.).
- StagingBuffer → ReviewQueue → Core-Flow klar modelliert.
- ExternalMapping-Struct im Core committed.
- Kein confirmed-Eintrag ohne User-Aktion möglich (Test).
- HANDOFF_PHASE2.md committed und gepusht.

**Codex-Prompt Phase 2:**
```
Implementiere in mykilOS-6:
1. ExternalMapping.swift mit allen Feldern aus SKILL.md
2. DriveProjectScanService.swift: liest Drive API v3, gibt [DriveFolder] zurück,
   kein Core-Schreibzugriff, verwendet Token aus KeychainTokenStore
3. ProjectFolderParser.swift: toleranter Parser für alle Ordner-Varianten:
   "2026_001_X", "2026_20_X", "JJJJ_lfdNr_Kunde_STR", unlesbare Namen
   → ParsedProjectFolder mit Confidence
4. MappingStagingBuffer: temporär, nicht persistent
5. Unit-Tests: Parser für min. 6 Ordner-Varianten aus dem echten Drive
Build grün. HANDOFF_PHASE2.md schreiben.
```

---

### Phase 3 — Live-Nodes: Drive-Widget, Mail-Widget, Kalender-Widget (max. 60 min)

**Ziel:** Die drei Übersicht-Widgets zeigen echte gestreamte Daten aus bestätigten
Mappings. Kein Widget crasht bei fehlendem Mapping, fehlender Berechtigung oder
leerem Ergebnis.

#### 3.1 Projektordner-Widget (Drive)

- Liest Drive-Unterordner des gemappten Projekts via fileID (nicht Pfad).
- Zeigt Unterordner-Tabs: 01 INFOS / 02 CAD / 03 PRÄSENTATION / etc.
- Fehlerzustand `.noMapping`: "Noch nicht verknüpft — Mapping starten"
- Fehlerzustand `.noPermission`: "Berechtigung nötig" (Reconnect-Button)
- Fehlerzustand `.offline`: "Drive nicht erreichbar — letzter Stand: \(lastSeenAt)"
- Fehlerzustand `.orphaned`: "Ordner nicht mehr gefunden — Mapping prüfen"
- Kein harter `NSCocoaErrorDomain Code 260` mehr — wird immer abgefangen.

```swift
enum DriveWidgetState {
    case loading
    case loaded([DriveFolder])
    case noMapping
    case noPermission
    case orphaned(lastKnownName: String, lastSeenAt: Date)
    case offline(cachedAt: Date?)
    case error(String)
}
```

#### 3.2 Mail-Widget

- Liest Gmail API: letzte N Mails mit Projekt-Referenz (Suche via Kundename + Projektnummer).
- Zeigt: Absender, Betreff, Datum, Snippet.
- Schreiben: nur über separaten "Mail verfassen"-Flow mit explizitem Confirm-Sheet.
- Fehlerzustand `.noPermission`, `.empty("Keine Mails gefunden")`, `.offline`.

#### 3.3 Kalender-Widget

- Liest Google Calendar API: Events der nächsten 14 Tage mit Projekt-Referenz.
- Zeigt: Datum, Titel, Teilnehmer.
- Anlegen/Ändern: nur über Confirm-Flow, niemals direkt.
- Fehlerzustand `.noPermission`, `.empty`, `.offline`.

#### 3.4 Widget-Architektur-Regel

```
WidgetViewModel
    → Repository (lokaler Cache + Sync-Status)
    → Service (API-Aufruf, async/await)
    → DTO (Adapter, kein direkter Core-Zugriff)
    → Core (nur nach Staging + Confirm für persistente Daten)
Niemals: API-Aufruf direkt aus View oder ViewState.
```

**Gate Phase 3:**
- Alle drei Widgets kompilieren und zeigen Fehlerzustände korrekt an (kein Crash).
- Bei bestätigtem Mapping: Drive-Widget zeigt echte Unterordner.
- Mail + Kalender zeigen echte Daten für Test-Account.
- `NSCocoaErrorDomain Code 260` tritt nicht mehr auf.
- Kein Token in Logs.
- HANDOFF_PHASE3.md committed und gepusht.

**Codex-Prompt Phase 3:**
```
Implementiere in mykilOS-6:
1. DriveWidgetViewModel.swift mit DriveWidgetState-Enum (alle States aus SKILL.md)
   — löst Ordner via ExternalMapping.externalStableID auf, nie via Pfad
2. MailWidgetViewModel.swift mit analogen States
3. CalendarWidgetViewModel.swift mit analogen States
4. Je ein Repository + Service-Stub (async/await, Token via KeychainTokenStore)
5. Views zeigen alle Fehler-/Leer-/Ladezustände (kein weißer/crashender Screen)
Nicht bauen: Schreib-Flows — nur lesende Live-Anzeige.
Build grün. Tests für alle WidgetStates. HANDOFF_PHASE3.md.
```

---

### Phase 4 — Claude-Assistent-Node (max. 30 min)

**Ziel:** Der in-App Assistent bekommt Projekt-Kontext aus bestätigten Mappings
und macht Vorschläge. Er schreibt niemals autonom in Core.

#### 4.1 Kontext-Assembler

```swift
struct AssistantContext {
    let project: Project
    let confirmedMappings: [ExternalMapping]
    let recentDriveFiles: [DriveFolder]?     // optional, kann nil sein
    let openTasks: [Task]?
    let recentMails: [MailSnippet]?
}
// Assembler zieht Kontext aus lokalen Core-Daten + confirmed Mappings
// Kein direkter API-Aufruf aus dem Assembler
```

#### 4.2 Assistent-Regeln

- Erhält Kontext, gibt Vorschläge zurück.
- Jeder Vorschlag landet in einer `SuggestionCard` (Vorschau + Bestätigen / Ablehnen).
- Kein autonomes Schreiben in Core, Drive, Mail oder Kalender.
- Jede angenommene SuggestionCard erzeugt einen Audit-Eintrag.
- Modell: `claude-sonnet-4-6` (aktuell produktiv).

**Gate Phase 4:**
- Assistent zeigt Vorschläge basierend auf Projekt-Kontext.
- Kein Vorschlag wird ohne Nutzer-Bestätigung ausgeführt.
- HANDOFF_PHASE4.md committed und gepusht.

**Codex-Prompt Phase 4:**
```
Implementiere in mykilOS-6:
1. AssistantContext.swift (Struct aus SKILL.md)
2. AssistantContextAssembler: zieht Daten aus Core + confirmed ExternalMappings,
   kein direkter API-Aufruf
3. AssistantService: sendet Kontext an Claude API (claude-sonnet-4-6),
   gibt [SuggestionCard] zurück
4. SuggestionCard-View: zeigt Vorschlag + Bestätigen/Ablehnen — kein Auto-Apply
5. Jede Bestätigung → AuditLog-Eintrag
Build grün. HANDOFF_PHASE4.md.
```

---

## Abschluss-Checkliste der Session

Erst wenn alle Gates grün sind:

- [ ] Phase 0: Build sauber, OAuth-Client konfiguriert.
- [ ] Phase 1: Keychain-Store grün, UserProfile im Core, kein Token in DB/Logs.
- [ ] Phase 2: ExternalMapping im Core, Drive-Scan läuft, Parser tolerant, Review-Gate.
- [ ] Phase 3: Alle drei Widgets zeigen echte Daten + alle Fehlerzustände abgedeckt.
- [ ] Phase 4: Assistent liefert Vorschläge, kein autonomes Schreiben.
- [ ] Kein `NSCocoaErrorDomain Code 260` mehr reproduzierbar.
- [ ] Alle HANDOFF_PHASE*.md vorhanden, committed, gepusht.
- [ ] Git: sauberer main-Branch, alle Phasen als separate Commits.

---

## Abbruchkriterien (Session sofort stoppen)

- Produktiver Schreibzugriff auf externe Daten ohne Confirm-Flow.
- Token in SQLite, Markdown oder Log-Output.
- Core-Überschreibung ohne Staging + Review.
- Build rot — erst reparieren, dann weitermachen.
- Scope-Ausweitung auf nicht-geplante Systeme (Clockodo, Sevdesk etc.).

---

## Mapping der App-Screens auf Drive-Unterordner

```
App-Tab "Dateien"          → Drive: 01 INFOS (Pläne, Fotos, Recherche, Fragebögen)
App-Tab "Angebote"         → Drive: 04 ausgehende Angebote / 05 eingehende Angebote
App-Tab "Material"         → Drive: 03 PRÄSENTATION / Moodboards / Renderings
App-Tab "CAD"              → Drive: 02 CAD / VectorWorks
App (Abnahme)              → Drive: MYKILOS_Abnahmeprotokoll_BLANKO.pdf
```

---

## Multi-User-Regeln für diese Session

- OAuth per Nutzer: persönlicher Account authentifiziert gegen geteilte Ablage
  via Team-Mitgliedschaft (kein separater Team-Account-Login nötig für Drive-Lesen).
- Team-Account `info@mykilos.com`: hinterlegter zweiter Account pro Nutzer,
  wird für Mail-Senden und geteilte Kalender-Events verwendet.
- Bestätigte Mappings gelten teamweit — sie landen in einem geteilten
  `appdata`-Ordner in Drive (nicht lokal, damit alle denselben Stand haben).
- Admin-Rolle: kann Mappings bestätigen, ablehnen, reparieren.
- Mitarbeiter-Rolle: kann Mappings vorschlagen, nicht bestätigen.

---

## Referenzdaten dieser Session

Drive-Root: `MYKILOS Team > PROJEKTE`
Drive-PROJEKTE_FOLDER_ID: muss in Phase 0 einmalig manuell konfiguriert werden
  (in `appdata` oder App-Einstellungen, nicht hardcoded).

Ordner-Schema (tolerant parsen):
```
JJJJ_lfdNr_Kunde_STR-Nr   →  2026_001_MYKILOS_Serienkueche
JJJJ_lfdNr_Kunde           →  2026_013_Cirnavuk
JJJJ_lfdNr_Kunde_STR       →  2025_014_BenjaminMartin_FUN16
JJJJ_lfdNr_Kunde_STR       →  2026_20_Liebig_Quooker  (fehlende führende 0 → tolerieren)
_BEISPIELORDNER_…          →  ignorieren (kein Mapping-Versuch)
_PROJEKTE_ARCHIV           →  ignorieren
```
