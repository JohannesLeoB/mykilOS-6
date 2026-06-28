# Codex — Sequenzielle Session-Anweisungen

**Stand:** 2026-06-28  
**Repo:** https://github.com/JohannesLeoB/mykilOS-6 (privat, Branch `claude/musing-sammet-3abd94`)  
**Run:** `./script/build_and_run.sh` → `dist/*.app`  
**Tests:** `swift test` — muss vor und nach jeder Session grün sein (aktuell 97/97)

Jede Session hat ein **einziges klar abgrenzbares Ziel**. Nie zwei Sessions bündeln.  
Jede Session endet mit: grüner Build, grüne Tests, Handoff-Dokument, CLAUDE.md aktualisiert.

---

## PRE-FLIGHT (vor jeder Session — immer)

```bash
swift build          # muss grün sein
swift test           # muss 97/97 grün sein (wächst)
git status           # clean working tree
git log --oneline -3 # letzter Commit bekannt
./script/build_and_run.sh  # App startet, kein Crash
```

---

## SESSION A — User-Identität anzeigen

**Ziel:** Nach Google-Login ist der echte Google-Account-Name + Avatar/Email in der App sichtbar.

**Problem heute:** Google OAuth ist live, aber nach dem Login weiß die App nicht wer eingeloggt ist. Es gibt keinen "current user"-State. Der Nutzer sieht keinen Unterschied zwischen verbunden/nicht verbunden außer in den Settings.

**Was zu tun ist:**

1. `GoogleAuthService` um `currentUser: GoogleUserInfo?` ergänzen:
   ```swift
   public struct GoogleUserInfo: Sendable {
       public let email: String
       public let displayName: String?
       public let pictureURL: URL?
   }
   ```
   Nach erfolgreichem Token-Tausch: `GET https://www.googleapis.com/oauth2/v2/userinfo` aufrufen, Ergebnis in Keychain cachen.

2. `AppState` um `currentGoogleUser: GoogleUserInfo?` ergänzen — abgeleitet aus `googleAuth.currentUser`.

3. In `SidebarView` unten: kleine User-Zeile mit Email + Name (nur wenn connected). Kein Avatar nötig für V1 — Email reicht.

4. Test: `GoogleUserInfoTests` — parst JSON-Response korrekt, kein Keychain/Netzwerk im Test.

**Erlaubt:** SidebarView, GoogleAuthService, AppState  
**Nicht anfassen:** Alle anderen Services, GRDB-Schema, Widget-Code  
**Handoff:** `docs/handoffs/HANDOFF_SESSION_A.md`

---

## SESSION B — Clockodo Widget live schalten

**Ziel:** Clockodo-Widget zeigt echte laufende/letzte Zeiteinträge des eingeloggten Users, keine Demo-Daten mehr.

**Problem heute:** `ClockodoClient` ist implementiert und der API-Key ist im Keychain gespeichert. Aber das `ClockodoWidget` rendert `demoActivity`-Fakdaten statt echte API-Aufrufe zu machen.

**Was zu tun ist:**

1. `ClockodoWidget` — `demoActivity` entfernen, echten Lade-Flow einbauen:
   - `loadEntries()` → `ClockodoClient.getEntries(userID:from:to:)` für heute
   - Renderstates: `.loading` → `.content(entries)` / `.empty` / `.error(String)` / `.permissionRequired`
   - `permissionRequired` wenn `clockodoAuth.status != .connected`

2. `ClockodoClient` auf `currentUser`-Kontext abstimmen: Einträge werden **nur für den eingeloggten Clockodo-User** geladen. `ClockodoDraftEntry.clockodoUserID` filtert auf GRDB-Ebene (Kernregel: jeder User sieht nur seine eigenen Einträge).

3. Quellenzeile unten im Widget: `Clockodo · {email}` (aus Credentials).

4. Test: `ClockodoWidgetLoadTests` — mit Fake-Client, prüft alle Renderstates.

**Nicht anfassen:** Kalkulations-Code, Google-Code, andere Widgets  
**Handoff:** `docs/handoffs/HANDOFF_SESSION_B.md`

---

## SESSION C — Projektdetailseite Tab "Dateien" live

**Ziel:** Der Tab "Dateien" in der Projektdetailseite ist kein Stub mehr, sondern zeigt die echten Drive-Dateien des Projekts gegliedert nach Unterordnern.

**Problem heute:** `ProjectDetailView` hat 5 Tabs. Nur `overview` ist live. `files` zeigt `ComingTabView`. Der Drive-Ordner-ID-Slot (`project.links.driveFolderID`) ist aber schon verdrahtet.

**Was zu tun ist:**

1. `ProjectFilesTabView` in `Sources/MykilosApp/Detail/ProjectFilesTabView.swift` bauen:
   - Liest `project.links.driveFolderID`
   - Ruft `GoogleDriveClient.listFolder(folderID:)` auf
   - Unterordner-Navigation: Root → Unterordner anklicken → zurück
   - Renderstates: `.loading` / `.content([DriveFile])` / `.empty` / `.permissionRequired` / `.error`
   - Datei anklicken → im Browser öffnen (`NSWorkspace.shared.open(url)`)
   - Quellenzeile: `Google Drive · {folder-name}`

2. In `ProjectDetailView`: `case .files: ProjectFilesTabView(project: project, googleDrive: appState.googleDrive)` statt `ComingTabView`.

3. Kein Schreiben in Drive — nur lesen.

4. Test: `ProjectFilesTabTests` — Fake-DriveClient, prüft alle Renderstates.

**Nicht anfassen:** `offers`-, `timeline`-, `material`-Tabs (bleiben Stubs), Kalkulations-Code  
**Handoff:** `docs/handoffs/HANDOFF_SESSION_C.md`

---

## SESSION D — Projektdetailseite Tab "Angebote" (Kalkulation V1 UI)

**Voraussetzung:** CODEX_HANDOFF_KALKULATION.md (Aufgaben 1–6) muss abgeschlossen sein.

**Ziel:** Tab "Angebote" zeigt Kalkulationsdaten aus der integrierten Engine — Preisspanne, Kostenboden, Evidence-Liste. Kein Stub mehr.

**Was zu tun ist:**

1. `ProjectOffersTabView` in `Sources/MykilosApp/Detail/ProjectOffersTabView.swift`:
   - Liest letzte `KostenSchaetzung` für dieses Projekt (aus Airtable `Kalkulationen` oder lokal gecacht)
   - Zeigt: Min/Mitte/Max-Preisspanne, Kostenboden + Ratio, Top-3-Evidence-Cards
   - Freitext-Eingabe: "Schätz neu" → `appState.kalkulationsEngine?.schaetze(projektID:freitext:)`
   - Schätzung speichern: `KalkulationsActionCard` → Bestätigung → `AirtableClient.createRecord()` + `AuditEntry`
   - Sichtbar nur wenn `appState.kalkulationsEngine != nil`
   - Quellenzeile: `{evidenceCount} Anker · {corpus-Stand}`

2. In `ProjectDetailView`: `case .offers: ProjectOffersTabView(project: project, engine: appState.kalkulationsEngine)`

3. Design-Tokens verwenden: `MykColor.cash.color` für Preis-Balken, `Font.mykBody` etc.

4. Test: `ProjectOffersTabTests` — Fake-Engine, prüft alle Renderstates inkl. nil-engine.

**Nicht anfassen:** Kalkulations-Engine-Internals (die sind schon fertig), andere Tabs  
**Handoff:** `docs/handoffs/HANDOFF_SESSION_D.md`

---

## SESSION E — Assistent kann Drive-Daten lesen

**Ziel:** Der Assistent-Widget-Chat kann auf Drive-Dateien eines Projekts hinweisen — "Im Projekt Meyer liegen 3 neue PDFs unter Angebote/Tischler."

**Problem heute:** `AssistantEngine` liest nur Signale aus `StudioContext`. Drive-Daten fließen nur ins `DriveWidget`, nicht in den Assistenten.

**Was zu tun ist:**

1. Neues Signal `driveFilesChanged(folderID:count:newestFileName:)` in `WidgetSignal` definieren.

2. `DriveWidget` emittiert dieses Signal nach erfolgreichem Load, wenn neue Dateien da sind (`newestFiles.count > lastKnownCount`).

3. `AssistantEngine.generateInsights()` wertet `driveFilesChanged`-Signale aus → erzeugt Insight-Text: "3 neue Dateien im Drive-Ordner · {newestFileName}"

4. Signal ist ein **Vorschlag** — kein automatisches Handeln. Nur Anzeige im Assistenten.

5. Kein Schreiben in Drive.

6. Test: `DriveSignalTests` — DriveWidget feuert Signal bei neuem File, AssistantEngine erzeugt Insight-Text.

**Nicht anfassen:** Drive-Widget-UI, Google-Auth-Code  
**Handoff:** `docs/handoffs/HANDOFF_SESSION_E.md`

---

## SESSION F — Clockodo Zuhörer (Post-Akt-5, Aufgabe 6)

**Ziel:** Assistent erkennt Chat-Eingaben wie "4h CAD für Heinz" → erzeugt Draft-Buchung → Wochenvorschau → Bestätigung → POST /api/v2/entries.

**Dies ist die komplexeste Session. Vollständige Architektur steht in:**  
`docs/handoffs/HANDOFF_LIVE_WIRING_4.md`

**Kernregel:** Jeder User bucht/sieht/editiert **nur seine eigenen** Einträge. `clockodoUserID` filtert auf GRDB-Ebene.

**6 Schichten:**
1. Intent-Erkennung (Claude parst NLP-Eingabe)
2. Resolution (Airtable `Clockodo-Nutzer` + `Clockodo-Leistungen` Lookup)
3. Draft Store (GRDB `clockodo_drafts` Tabelle, Cold-Start-Test Pflicht)
4. Wochenvorschau-UI (Draft-Liste mit Bearbeitungsmöglichkeit)
5. Bestätigung (ActionCard → AuditEntry)
6. POST + AuditEntry

**Niemals automatisch buchen — immer Bestätigung.**

**Nicht anfassen:** Kalkulations-Code, Drive-Code  
**Handoff:** `docs/handoffs/HANDOFF_SESSION_F.md`

---

## REIHENFOLGE & ABHÄNGIGKEITEN

```
A (User-Identität)     ←  unabhängig, sofort startbar
B (Clockodo live)      ←  unabhängig, sofort startbar
C (Files-Tab)          ←  unabhängig, sofort startbar

Kalkulations-Port      ←  CODEX_HANDOFF_KALKULATION.md (Aufgaben 1–6)
D (Angebote-Tab)       ←  braucht Kalkulations-Port fertig
E (Assistent + Drive)  ←  braucht C fertig

F (Clockodo Zuhörer)   ←  braucht B fertig, kann parallel zu D/E laufen
```

**Empfohlene Startfolge:** A → B → C → Kalkulations-Port → D → E → F

---

## ABSOLUTE REGELN (für jede Session gültig)

| Regel | Konsequenz bei Verstoß |
|---|---|
| `try?` bei Schreibvorgängen: verboten ohne Kommentar | Build schlägt SwiftLint fehl |
| Neues persistentes Feature ohne Cold-Start-Test | Nicht mergebar |
| Secrets in Code/Logs/Commits | Sofort revertieren |
| Drive schreiben | Absolutes Verbot |
| Sevdesk berühren | Absolutes Verbot |
| Fremde Airtable-Base `appkPzoEiI5eSMkNK` | Absolutes Verbot |
| `import GRDB` in MykilosKit oder MykilosWidgets | Architekturverletzung |
| Schreibvorgänge aus Views (nicht aus Stores) | Architekturverletzung |
| Design-Tokens umgehen (`.font(.system(...))` etc.) | SwiftLint |

---

## SESSION-ABSCHLUSS-CHECKLISTE (jede Session)

- [ ] `swift build` grün, keine neuen Warnings
- [ ] `swift test` grün, neue Tests dabei
- [ ] `./script/build_and_run.sh` → App startet, Feature manuell getestet
- [ ] `docs/handoffs/HANDOFF_SESSION_{X}.md` geschrieben
- [ ] `CLAUDE.md` Status-Tabelle aktualisiert
- [ ] Commit mit sprechendem Message
- [ ] Push auf `claude/musing-sammet-3abd94`
