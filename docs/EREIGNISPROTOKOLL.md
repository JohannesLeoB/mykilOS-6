# mykilOS 6 — Ereignisprotokoll

**Lebendes Dokument. Jede Session, jeder Agent, jedes Tool trägt hier ein.**
Ziel: lückenlose Nachverfolgung aller Entwicklungsschritte — was wurde gebaut,
was ist kaputt gegangen, was ist offen, wer hat was gemacht, auf welchem Branch.

---

## Pflicht-Header für jeden Eintrag

```
## [DATUM] [AGENT/TOOL] — [KURZTITEL]
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: <branch>
Build:  ✅/❌
Tests:  N grün / M fehlgeschlagen
```

---

## Kanonischer Ordner (immer)

```
/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
GitHub: https://github.com/JohannesLeoB/mykilOS-6
```

Temporäre Worktrees liegen unter `~/Desktop/CLAUDE/` — das sind Wegwerfkopien,
nie dauerhafter Arbeitsort.

---

## 2026-06-29 · Claude Code (Opus) — S17: Kompletter Review-Lauf + Aufräumen

```
Branch: polish/dampflok; 373 → 385 Tests grün
Build:  ✅ swift build grün · Working Tree clean
```

Auf Wunsch („Kompletter Review lauf, no screenuse, räume alles sauber auf"): Voll-Audit
der gesamten Session (S1–S16) per Multi-Agent-Workflow (16 Agenten, 5 Dimensionen,
adversarisch gegengeprüft) + deterministische Hard-Fact-Checks.

**Ergebnis: KEINE funktionalen, Verdrahtungs-, Vollständigkeits- oder Safety-Defekte.**
- Hard Facts: Build grün, 385 Tests, Tree clean; Manifest-JSON ↔ Airtable-Handbuch ↔
  Benutzerhandbuch = **33 Weichen, identische Mengen**; kein `try!`/TODO/Stub; SwiftLint
  Token-Regeln 0 Verstöße; Tool→Manifest-Map (26) vollständig.
- Safety-Sweep (selbst, da Review-Agent abbrach): **kein** Gmail-Send-API-Aufruf, **kein**
  Sevdesk-Write; externe Writes nur OAuth/TokenRefresh/Claude/createContact/createDraft/
  Airtable-Log (alle bestätigungs-gated bzw. whitelisted).
- Behoben (nur Doku/Tests, keine Logikfehler): stale Test-Zahl + Datum in HYPERBUILD.md
  (270→373, 2026-06-29), Datum BENUTZERHANDBUCH; **+12 Tests** für die neuen Schreib-/Lese-
  Tools (create_contact-Tool, create_draft-Ränder, read_email-Index/Fehlerpfade,
  lookup_kontakt Null-Treffer + Feld-Formatierung).

Alle vom Nutzer bestellten Funktionen sind implementiert, registriert, getestet UND
dokumentiert. Offen bleiben nur die Johannes-Aktionen M2/M3 und der bewusst zurückgestellte
S3 (QuickLook-Vollvorschau). Kein Push.

---

## 2026-06-29 · Claude Code (Opus) — S16: Review-Fix (Projekt-Scope + PII-Log)

```
Branch: polish/dampflok; 371 → 373 Tests grün
```

Adversariale Multi-Agent-Review der S10–S13-Implementierung (13 Agenten) fand einen
ECHTEN Defekt (mehrfach bestätigt, high/critical): Die **mutierenden** Tools
`update_note`/`delete_note`/`complete_task`/`delete_task` zogen die injizierte `_projektID`
NICHT heran — `find(matching:)` suchte über ALLE Projekte. Folge: im Projekt-Chat hätte
„lösche Notiz X" eine gleichnamige Notiz/Aufgabe eines ANDEREN Projekts treffen können.

- Fix: `scopedTo`-Parameter in `AssistantNotesStore`/`AssistantTasksStore`
  (`find`/`update`/`delete`/`setDone`) — bei gesetztem Projekt nur Projekt+global durchsuchen.
  Die vier Tools reichen `AssistantScope.projectID(from:)` durch (wie create/list bereits).
- Zusätzlich (medium-Fund): `AppState.syncKontakte` schreibt keinen Roh-Fehlertext mehr in
  den DataFlow-Log (ggf. Airtable-gespiegelt) — Detail nur lokal via os.Logger (PII-Schutz).
- +2 Regressionstests: Cross-Projekt-Update/Delete/Complete wird blockiert, eigenes Projekt geht.

Single-User-lokale App → kein echtes Multi-User-Leck, aber Korrektheits-/Isolationsfix.

---

## 2026-06-29 · Claude Code (Opus) — S14/S15: Gmail-Entwürfe + voller Mailzugriff

```
Branch: polish/dampflok; 361 → 371 Tests grün
Build:  ✅ swift build grün
```

Johannes (Live-Screenshot): Assistent sagte „keinen Schreibzugriff auf Gmail" beim
Versuch, einen Entwurf abzulegen. Außerdem: „ALLE Mails durchsuchbar und lesbar".

**S14 — Gmail-Entwurf anlegen:** `GoogleGmailWriting.createDraft` (Gmail `drafts.create`,
RFC822-MIME mit RFC2047-Subject + base64url-`raw`). `EmailDraft`/`DraftCreateOutcome` (Kit),
`create_draft`-Tool (liefert nur Entwurf, schreibt nichts), `.draftAction`-Block +
`DraftActionCard` (Bestätigung → `AppState.createDraft` → Gmail-API + Audit `.draftCreated`).
Entwurf landet in Gmail und damit auch in Apple Mail. **VERSENDEN bleibt hartes NO-GO** (Send-API
nie aufgerufen). Neuer `gmail.compose`-Scope → Live braucht M2. Weiche GMAIL_DRAFT_CREATE.

**S15 — alle Mails lesbar:** `search_gmail` durchsucht serverseitig das ganze Postfach
(Limit nur Trefferzahl, S12); neues `read_email`-Tool liest den VOLLEN Body
(`GoogleGmailFetching.fetchBody`: text/plain bevorzugt, sonst HTML entschlackt, base64url-dekodiert).

+10 Tests (MIME/Header/base64url/parseBody/stripHTML/read_email/create_draft). Bestehende
Lese-Fakes via Protokoll-Default-Extension unberührt.

---

## 2026-06-29 · Claude Code (Opus) — S11: ClickUp projektübergreifend

```
Branch: polish/dampflok; 358 → 361 Tests grün
```

Memo P2 „ClickUp projektübergreifend — Aufgaben nur im Fokus-Projekt sichtbar".
Neues Tool `list_all_clickup_tasks` (`AllClickUpTasksTool`) aggregiert offene Tasks über
ALLE Projekte mit verknüpfter Liste, gruppiert nach Projekt, optional Projekt-Filter.
Robust: Cap 20 Listen (Rest wird ausgewiesen), einzelne kaputte Liste wird übersprungen.
`ProjectClickUpRef` (Kit); AppState baut die Listings aus `registry.projects` (Felder mit
`clickUpListID`); mappt auf bestehende Weiche CLICKUP_TASKS. +3 Tests (Aggregation,
Filter+Skip-Fehler, fehlt-ohne-Listings).

**Hinweis:** liefert erst Daten, wenn ClickUp-Listen-IDs in Airtable gepflegt sind (M3) —
die Mechanik steht, das Feld `Projekte.ClickUp-Liste` ist aktuell überwiegend leer.

---

## 2026-06-29 · Claude Code (Opus) — S12: Gmail-Suche parametrisierbar (mehr als 10)

```
Branch: polish/dampflok; 357 → 358 Tests grün
```

Memo P2 „Gmail historisch — nur letzte ~10 Mails". `SearchGmailTool` hatte `maxResults`
hart auf 10. Jetzt Parameter `anzahl` (Default **25**, Cap 100); ein Cache-Hit wird nur
verwendet, wenn er genug Treffer hat; die Tool-Beschreibung nennt Datums-Operatoren
(`after:2025/01/01`, `newer_than:`) für Rückblicke. +1 Test (`resultLimit`).
Voller Mailbox-Vollcache-Sync (GmailSyncService über das ganze Postfach) bleibt ein
größerer Folgeschritt — der Cache speichert bisher nur Query-Ergebnisse.

---

## 2026-06-29 · Claude Code (Opus) — S13: Airtable-Kontaktverzeichnis (lookup_kontakt)

```
Branch: polish/dampflok; 351 → 357 Tests grün
Build:  ✅ swift build grün
```

Memo P1 „Adresse Familie Cirnavuk?". Befund: Die Airtable-**Kunden**-Tabelle hat nur
Name/Nummer — aber es gibt eine eigene **`Kontakte`**-Tabelle (`tblncfQzQa8TzCZQC`,
**914 Records**) mit Name/Organisation/Telefon/E-Mail/**Adresse**/Projekt. Das beantwortet
die Frage **lokal, ohne Google/M2**.

- `StudioContact` (Kit) + `AirtableClient.mapContacts` (pure/testbar) + `ContactDirectory`
  (Snapshot, rang-sortierte Freitextsuche Name/Org/Projekt).
- `LookupKontaktTool` (`lookup_kontakt`) liefert Name·Organisation + Telefon/E-Mail/Adresse/
  Projekt. Grounding-Hinweis: Adress-/Telefon-Fragen → dieses Tool (lokal, nicht auf Google warten).
- `AppState.syncKontakte` lädt die `Kontakte`-Tabelle einmalig read-only beim Start in den
  Snapshot (Fehler nicht-fatal, os.Logger), Registry wird mit `ContactDirectory` neu gebaut.
- Weiche AIRTABLE_KONTAKTE_LOOKUP (Manifest + Map + Airtable-Handbuch, jetzt 32 Weichen).
- +6 Tests (mapContacts, Suche/Ranking, Tool liefert Adresse, Fehlerpfade).

Read-only, erlaubte Mastermind-Base. Kein externer Schreibzugriff.

---

## 2026-06-29 · Claude Code (Opus) — Memo-Reconciliation + S10: Notizen/Aufgaben pro Projekt

```
Branch: polish/dampflok; 348 → 351 Tests grün
Build:  ✅ swift build grün
```

Johannes leitete ein Memo des **In-App-Assistenten** weiter (fehlende Integrationen).
Statt es 1:1 zu glauben: Multi-Agent-Audit (37 Agenten) jeder Memo-Zeile gegen den echten
Code. Kernbefund: **P1 „Drive blind" + „Kontakte nicht abrufbar" sind code-fertig** (S2/S5/S8/S9)
und nur durch **M2 (Google Re-Consent)** blockiert — nicht durch fehlenden Code. Echte,
ohne M2 baubare Lücken: Notizen/Aufgaben pro Projekt, ClickUp projektübergreifend,
Gmail-Limit, Airtable-Kundendetails.

**S10 — Notizen & Aufgaben pro Projekt** (Memo P2 „Notizsystem pro Projekt"):
- `projectID` an `AssistantNote`/`AssistantTask` (Kit) + Records + Stores (`scoped(to:)` =
  Projekt-Einträge + globale). GRDB-Migration **v10** additiv (Spalte nullable, NULL=global,
  kein Datenverlust an Alt-Einträgen).
- Tools taggen automatisch via injiziertem `_projektID` (`AssistantScope`-Helfer): im
  Projekt-Chat angelegte Notiz/Aufgabe gehört dem Projekt. `list_notes`/`list_tasks` zeigen
  standardmäßig Projekt+global, `alle=true` = alle Projekte. Kataloge-Tabs zeigen Projekt-Badge.
- +3 Tests (Scope-Filter, projectID-Cold-Start, Projekt-Chat-Tagging via Registry).

---

## 2026-06-29 · Claude Code (Opus) — S9: Google Contacts Schreibzugriff (create_contact)

```
Branch: polish/dampflok; 344 → 348 Tests grün
Build:  ✅ swift build grün · SwiftLint Token-Regeln sauber
```

Auf Wunsch von Johannes: der Assistent soll neue Google-Kontakte anlegen können.
Externer Schreibzugriff → eiserne Regel: nur über **Action-Card → Bestätigung → Audit**.

- **Kit**: `ContactDraft` (Entwurf) + `ContactCreateOutcome` (created/failed) +
  `ChatContentBlock.contactAction` + `AuditEntry.Action.contactCreated`.
- **Services**: `GoogleContactsWriting`-Protokoll + `GoogleContactsClient.createContact`
  (People API `people:createContact`), testbare `buildCreateBody`/`parsePerson`.
  `CreateContactTool` (`create_contact`) erzeugt NUR einen `ContactDraft` —
  schreibt nichts. `ToolRunResult.contactDraft`; ConversationEngine rendert daraus
  einen `.contactAction`-Block; Grounding `contactsWriteEnabled`; Weiche CONTACTS_CREATE.
- **Widgets**: `ContactActionCard` (Entwurf + „Kontakt anlegen"-Button, Zustände
  idle/saving/done/failed). `onCreateContact`-Closure von der App injiziert (Widgets
  kennt keinen Schreib-Client).
- **App**: `AppState.createContact` ruft People API + schreibt `AuditEntry(.contactCreated)`;
  an beiden Chat-Aufrufen (global + Projekt) verdrahtet. Audit-Fehler via os.Logger sichtbar.
- +4 Tests (buildCreateBody nur gesetzte Felder / nur Vorname, parsePerson, displayName).

**Live-Test ausstehend (M2):** Anlegen braucht den `contacts`-Scope → Johannes muss
Google einmal neu verbinden (Trennen → Verbinden). Code-Pfad + Bestätigung + Audit sind fertig.

---

## 2026-06-29 · Claude Code (Opus) — S8: Kontakte-Widget im Projektdetail repariert

```
Branch: polish/dampflok; 342 → 344 Tests grün
Build:  ✅ swift build grün
```

Befund „Kontakte in den Projektdetailseiten geht noch nicht": Das ContactsWidget war
korrekt verdrahtet, aber die Google **People-API `searchContacts`** liefert beim
**kalten Index deterministisch eine leere Liste** — der erste Aufruf nach Cache-Start
gibt nie Treffer zurück (dokumentierte Warmup-Pflicht). Jede frisch geöffnete
Projektseite bekam daher „keine Kontakte", egal ob es Treffer gäbe.

- Fix in `GoogleContactsClient.searchContacts`: stiller **Warmup** (Aufruf mit leerer
  Query, Ergebnis verworfen) → echte Suche → bei leerem Ergebnis **einmal kurz
  nachfassen** (500 ms; Index evtl. noch nicht warm).
- Zusätzlich **Query-Normalisierung**: Unterstriche der Projekt-Tokens (z. B.
  „Fuckner_Huetter") werden zu Leerzeichen, Whitespace kollabiert — kommen in echten
  Kontaktnamen nie vor und verhinderten sonst jeden Treffer.
- Neue testbare Bausteine `buildWarmupURL` + `normalizedQuery` (+2 Tests). Bestehende
  Tests (URL/Parser/notConnected) unverändert grün.

Read-only (Kontakte lesen), kein Schreibzugriff — der kommt separat in S9.

---

## 2026-06-29 · Claude Code (Opus) — S7: Kataloge mit umsortierbaren Unter-Tabs

```
Branch: polish/dampflok; 342 Tests grün (unverändert; reine UI-Erweiterung)
Build:  ✅ swift build grün · SwiftLint Token-Regeln + file_length sauber
```

Auf Wunsch von Johannes: die Kataloge-Seite bekommt neben „Geräte" weitere, frei
umsortierbare Unter-Tabs.

- `KatalogeView` ist jetzt eine Hülle mit 4 Tabs (`KatalogTab`): Geräte, Kontakte,
  Notizen, Aufgaben. Tabs per Drag umsortierbar (`.draggable`/`.dropDestination`),
  Reihenfolge persistent in `@AppStorage("kataloge.taborder")`.
- **Geräte**: der bisherige read-only DeviceCatalog (unverändert).
- **Kontakte**: Freitextsuche über die Google-Kontakte (People API, read-only),
  alle Phasen (idle/loading/notConnected/error/loaded).
- **Notizen** (S4) / **Aufgaben** (S6): lesen die lokalen Assistenten-Stores und
  erlauben Inline-Anlegen/Abhaken/Löschen mit **sichtbarer Fehlerzeile** (kein `try?`,
  iron rule). Rein lokal.
- Inhalte in `KatalogeContentTabs.swift` ausgelagert (file_length < 400).
- Handbuch: Kataloge-Abschnitt aktualisiert (4 Tabs).

Reine UI über bestehende Stores/Clients — keine neuen Weichen, kein externer Schreibzugriff.

---

## 2026-06-29 · Claude Code (Opus) — S6: Aufgaben-Funktion im Assistenten

```
Branch: polish/dampflok; 334 → 342 Tests grün (59 Suites)
Build:  ✅ swift build grün
```

Auf Wunsch von Johannes: eine interne Aufgabenliste, die er sich selbst per Assistent
setzt und entfernt — kleine Memos und Erinnerungen. Spiegelt die Notiz-Funktion (S4).

- `AssistantTask` (MykilosKit): id/title/done/dueDate?/createdAt/updatedAt, `ref` (6-Zeichen).
- `AssistantTasksStore` (actor, GRDB v9 `assistantTasks`): create/all/open/setDone/delete/find;
  Sortierung offene-zuerst, dann nach Fälligkeit. Rein lokal, jeder Schreibvorgang wirft.
- Tools `create_task`/`list_tasks`/`complete_task`/`delete_task` (Schreib-Tools, nur lokal) in
  `AssistantToolRegistry.standard` (neuer `tasksStore`-Slot); optionales Fälligkeitsdatum
  (tolerant: ISO/yyyy-MM-dd/dd.MM.yyyy). Grounding-Zeile + ConversationEngine `tasksEnabled`.
- Weiche `ASSISTANT_TASKS`: Manifest + Map + Airtable Datenstrom-Handbuch (jetzt 30 Weichen).
- AppState: `assistantTasks` verdrahtet (Init + refreshAssistantKundenWissen).
- +8 Tests (`AssistantTasksStoreTests`): Anlegen/Sortierung/Fälligkeit/Finden/Löschen/Tools +
  Cold-Start `aufgabeUeberlebtNeustart` (Merge-Gate). Manifest-GATE-Test erweitert.

Read-only gewahrt; Aufgaben sind rein lokal (kein externer Schreibzugriff). Kein Merge ohne Freigabe.

---

## 2026-06-29 · Claude Code (Opus) — Proof-of-Function-Sprint S1–S5 (Live-Tour-Befunde)

```
Branch: polish/dampflok; 320 → 334 Tests grün (58 Suites)
Build:  ✅ swift build grün   ·   alle Schritte build+test grün
```

Die Live-Durchführung der App deckte echte Funktionslücken auf, die grüne Tests übersehen
hatten. Jeder Schritt schließt eine **real beobachtete** Lücke (Proof of Function statt
Proof of Existence).

- **S1** Schaltzentrale zeigte „0 Weichen": `loadManifest` lädt jetzt `Bundle.module` zuerst
  (+ korrigierter `#filePath`-Fallback); Build-Skript kopiert SPM-Resource-Bundles ins `.app`
  (sonst Schaltzentrum/StudioBrain leer im DMG). `f7048ee`
- **S2** Assistent fand keine Drive-Angebote: `find_offers`-Tool (wraps `OffersCollector`,
  rekursiv 04/05 in „01 INFOS") + `ProjectDirectory.resolve` (global per Projektnummer/Name
  → driveFolderID). Weiche DRIVE_OFFERS_FIND. `a1f9f61`
- **S4** Notiz-Funktion: `AssistantNotesStore` (actor, GRDB v8) + `create/list/update/delete_note`
  — die einzigen Schreib-Tools, rein lokal. Weiche ASSISTANT_NOTES. Dazu Kalender-Link-Fix
  (-50: LLM fabrizierte Inline-Link → Tool gibt URL nur an die Karte, kanonischer Google-Link). `288554a`
- **S5** Drive-Dateiinhalt lesen: `DriveFileReader` (PDF via PDFKit, Google Docs/Sheets/Slides
  via Export, Text via utf8, 6000-Zeichen-Cap) + `GoogleDriveClient.exportFile`; `read_drive_file`-Tool
  findet die Datei rekursiv per (Teil-)Name. Weiche DRIVE_FILE_READ. +3 Tests → 334. (dieser Commit)
- **S3** Volle Dokumentenvorschau (QuickLook/Voll-PDF) bleibt **offen** — braucht M2 (Google
  Re-Consent für `drive.readonly`).

Read-only gewahrt, kein externer Schreibzugriff (Notizen sind rein lokal). Kein Merge ohne Johannes' Freigabe.

---

## 2026-06-29 · Claude Code (Opus) — Polish-Loop L24–L30 abgeschlossen

```
Branch: polish/dampflok (gepusht → PR #3); 296 → 320 Tests grün (54 Suites)
Build:  ✅ swift build grün   ·   DMG-Pipeline verifiziert (dist/mykilOS-6.dmg)
```

Nach Core Repair A–G die offene UI-/Hirn-Politur fertiggestellt. Recon per 5-Agenten-
Workflow (echter Stand + Plan je Item), dann sequentiell mit build+test grün je Schritt.

- **L24** Kunden-Kontext: `KundenBrain` + `lookup_kunde` (read-only lokaler Sync-Cache,
  keine Kontaktdetails → search_contacts). Weiche AIRTABLE_KUNDEN_LOOKUP. `b1bed54`
- **L25** Favoriten: `FavoritesStore` (GRDB v7, Cold-Start) + Stern-Toggle Galerie/Detail;
  Widget zeigt echte Favoriten statt prefix(6)-Platzhalter. `b1bed54`
- **L26** Dark Mode + Token-Disziplin: NotesWidget (Tinte/Pergament), Ordner-Blau,
  Hero-Verläufe → adaptive MykColor-Tokens; alle `.font(.system)`/`Color(hex|red:)` aus
  Feature-Code; SwiftLint-Token-Regeln scharfgestellt + lokal verifiziert (0 Verstöße). `b17ac81`
- **L27** Timeline-Tab: `TimelineMerger` (rein/testbar) verschmilzt Drive/Angebote/
  Kalender/Audit; `TimelineTabView` verdrahtet (vorher Platzhalter). `2646769`
- **L28** RecentActivityWidget echt: DataFlow-Handshakes + Audit, neueste-zuerst
  (`RecentActivityFeed`); Leerzustand über kanonischen WidgetContainer. `6b1b77e`
- **L29** Test-Decke: Unit + Cold-Start für alle neuen Stores/Tools (320 Tests). `6b1b77e`
- **L30** Abschluss: Ledger/Protokoll/Benutzerhandbuch final; **DMG-Pipeline verifiziert**
  (Bundle ohne GUI-Start gebaut, `MykGitCommit`=6b1b77e injiziert, `dist/mykilOS-6.dmg` 6,6 MB).

Read-only gewahrt, kein externer Schreibzugriff. Kein Merge ohne Johannes' Freigabe.

---

## 2026-06-28 · Claude Code (Opus) — Core Repair Session (PR #3, Mandate A–G)

```
Branch: polish/dampflok (lokal, KEIN Push ohne Freigabe)
Build:  ✅ swift build grün
Tests:  fortlaufend grün (Start 270 → siehe je Mandat)
```

Ausgangslage (Recon, 7 read-only Mapper): Commit `ac1c914` hat für fast jedes
Mandat *Bausteine* angelegt, aber kaum etwas *verdrahtet* — exakt das Proxy-Muster.
Verifizierter Befund: B `LocalDriveRootResolver` 0 Caller (orphaned); D `localURL`
nie übergeben → PDF öffnet Safari; E `ConversationEngine` loggt Roh-Tool-Namen →
Schaltzentrum 0 Handshakes; F `try!` bleibt in Prod-DB, kein `os.Logger`; G
`BackupService` orphaned, WAL-Test ist Fake-String-Copy; A Commit immer „unbekannt",
Diagnose nur im About-Fenster. C ist verdrahtet, aber Ordnernamen-Klassifikation 0 Tests.

**Mandate E — Typed I/O (toolName→manifestID) ✅ (275 Tests grün)**
- `AssistantToolManifest` (MykilosServices): statische Map aller 9 Tools → kanonische
  Manifest-ID + Umbrella-Fallback `ASSISTANT_TOOL_CALL`.
- `ConversationEngine` loggt jetzt `manifestID(forTool:)` statt `toolUse.name` (Fix F12)
  → Schaltzentrum-Zeile `GMAIL_SEARCH` lightet nach echtem `search_gmail`-Lauf.
- 3 neue, ehrliche Weichen im Manifest: `DRIVE_ASSISTANT_LIST`, `CALENDAR_SUGGEST`,
  `STUDIO_KNOWLEDGE_QUERY` (jedes Tool eine eigene Zeile statt Sammel-Umbrella).
- Divergente `docs/datastream_manifest.json` gelöscht (F12: „Docs-Version löschen") —
  Resources-Manifest ist jetzt einzige Quelle der Wahrheit.
- Bug-zementierenden Test korrigiert (`integrationID == "schaetze_projekt"` →
  `"KALKULATION_LOCAL"`); neuer Gate-Test `gmailToolLoggtUnterManifestIDGmailSearch`;
  neue `AssistantToolManifestTests` (Map↔Manifest-Konsistenz, Drift-Guard).
- BENUTZERHANDBUCH: 22 → 25 Weichen, 3 neue Zeilen, `ASSISTANT_TOOL_CALL`-Notiz korrigiert.

**Mandate A — App-Diagnose in Settings + echter Git-Commit ✅ (275 Tests grün)**
- `AppDatabase.productionURL` extrahiert → EINE Pfad-Quelle; `AppIdentity.dbPath`
  delegiert dorthin (kann nie vom real geöffneten Pfad divergieren, Forensik A).
- `AppIdentity` um `gitCommit`/`gitBranch`/`buildDate` erweitert (liest Info.plist-
  Keys `MykGitCommit`/`MykGitBranch`/`MykBuildDate`). Das kaputte `#if GIT_COMMIT`-
  Makro (kompilierte nie zu echtem Wert) ist raus — Commit war immer „unbekannt".
- `build_and_run.sh` injiziert `git rev-parse --short HEAD`, Branch und UTC-Build-
  Datum via `plutil -insert` in die Info.plist (end-to-end verifiziert).
- Neuer `diagnoseSection` in `SettingsView` (Version·Build·Commit·Branch·Gebaut·
  Bundle·DB) — erfüllt das Hustadt-Gate „Settings → Diagnose zeigt Version+Commit".
  About-Fenster nutzt jetzt dieselbe `AppIdentity`-Quelle (+ Build-Datum-Zeile).
- BENUTZERHANDBUCH: neuer Abschnitt „Diagnose".

**Mandate B — Lokales Drive-Routing verdrahtet ✅ (280 Tests grün)**
- Neuer Foundation-only `DriveLocalResolver` (MykilosServices): liest xattr
  `com.google.drivefs.item-id#S`, `firstChild(of:withItemID:)`, rekursives
  `find(itemID:in:fileName:maxDepth:)` mit Namens-Fallback — **echt testbar**.
- `LocalDriveRootResolver` (vorher 0 Caller, orphaned) delegiert jetzt an
  `DriveLocalResolver`, bekommt `localURL(forFileID:…)` (Datei im Projektbaum),
  `driveFolderPath`-Fast-Path (Forensik F9 konsumiert) und `revealInFinder(localURL:)`.
- `FilesTabView`/`DriveTreeStore` VERDRAHTET: löst den Projektordner lokal auf
  (Quellzeile „· LOKAL"), Datei-Tap löst lokalen Pfad auf → `FilePreviewView(localURL:)`,
  Kontextmenü „Im Finder zeigen". `ProjectDetailView` reicht `driveFolderPath` durch.
- Neue `DriveLocalResolverTests` (5, echte `setxattr`/Temp-Baum, inkl. Hustadt-
  Struktur „05 eingehende Angebote/Vorplanung/angebot.pdf" + maxDepth + Namens-Fallback).
- BENUTZERHANDBUCH: „Dateien"-Abschnitt auf lokales Öffnen/Finder-Zeigen aktualisiert.
- ⚠️ Live-Verify (Johannes): echtes xattr `…item-id#S` am Hustadt-Mount + materialisierter Ordner.

**Mandate D — Echte Dokument-Vorschau statt Safari ✅ (280 Tests grün)**
- `FilePreviewView`: PDFKit-Render lokal-zuerst, sonst optionaler read-only
  Remote-Fallback (`remotePDFData`-Closure → Drive `downloadContent` → `PDFDocument(data:)`).
  Vorher war der `localURL`-Pfad toter Code (nie befüllt) → immer Browser (F11).
- `OffersTabView`/`OfferRow` VERDRAHTET: Datei-Tap löst lokalen Pfad auf →
  `FilePreviewView(localURL:remotePDFData:)`; Namens-Button öffnet **lokal-zuerst**
  (`openFile(localURL:fallbackURL:)`) statt blind `NSWorkspace.open(webViewLink)`;
  Kontextmenü „Im Finder zeigen". `driveFolderID`/`driveFolderPath` durchgereicht
  (ProjectDetail + GlobalOffersView). `FilesTabView`-Vorschau ebenfalls mit Remote-Fallback.
- BENUTZERHANDBUCH: „Angebote"-Abschnitt auf echte Vorschau/lokales Öffnen aktualisiert.
- Offen (bewusst, kein Gate): Material-Tab öffnet weiter im Browser; QuickLook für
  Nicht-PDF-Typen wäre Folge-Politur. ⚠️ Live-Verify: Hustadt-PDF rendert + öffnet lokal.

**Mandate C — Angebote testbar gemacht + echte Tests ✅ (290 Tests grün)**
- Reine Logik aus `OffersLoader` (MykilosApp, untestbar) in `OffersCollector`
  (MykilosServices) herausgelöst: `subfolder`/`collect`/`load`→`Result`. `OffersLoader`
  ist jetzt nur noch der dünne @Observable-Wrapper (Render-State/Generation/Fehler). F7 behoben.
- Neue echte Tests: `OffersCollector.collect` (Rekursion bis Hustadt-Tiefe, parentName-
  Fluss, maxDepth-Schnitt) + `OffersCollector.load` end-to-end (eingehend=Lieferanten-
  Angebot, ausgehend „Rechnung"+SR→Schlussrechnung, Ordner-nicht-gefunden) — gegen die
  ECHTE Produktionslogik statt eines Test-Klons.
- **Ordnernamen-Klassifikation** (das Kernsignal, vorher 0 Tests): 7 Tests für
  `resolveType` (Rechnung+SR/TR/Standard, Angebot gewinnt gegen Präfix, Auftrag,
  Bestellungen incoming, Vorplanung bleibt eingehendesAngebot).
- **Echte Pagination-Schleife** getestet: `listFolderFolgtNextPageTokenUeberZweiSeiten`
  mit gestubbter `URLSession` (StubURLProtocol) — Seite 1 (nextPageToken) → Seite 2
  (pageToken=PAGE2) → zusammengeführt. Der frühere Fake-Test ist als solcher markiert.
- **Divergenz dokumentiert (bewusst):** Der Angebote-TAB klassifiziert reich über
  `OfferDocumentClassifier` (Ordnername + Präfix); das `offerDetected`-SIGNAL nutzt weiter
  `DriveOfferWatcher.detectOffers` (konservative Dateinamen-Keywords). Zwei Zwecke, kein Bug.
- ⚠️ Live-Verify (Johannes): Hustadt `05 eingehende Angebote/Vorplanung…` zeigt das PDF.

**Mandate F — Crash-Diagnostik: wiederherstellbare DB, kein try!, os.Logger, Export ✅ (294 Tests grün)**
- **try! eliminiert** (Forensik F13): `AppDatabase` ist jetzt `boot() -> Boot(.ready/.failed)`
  (do/catch, crasht nie) + `recoverByResettingDatabase()` (Quarantäne statt Löschen);
  `GRDBDatabase.inMemory()` nutzt reguläres `try`. Grep bestätigt: 0 `try!`/`fatalError` in Sources.
- **Wiederherstellbarer Start**: `MykilOS6App` führt `BootPhase`; bei `.failed` rendert die neue
  `DatabaseRecoveryView` (Fehlertext + DB-Pfad + „Datenbank zurücksetzen") statt eines Absturzes
  vor dem ersten View. Kein eager force-unwrapped `AppState` mehr.
- **os.Logger**: neues `MykLog` (Subsystem `de.mykilos.mykilos6`, Kategorien lifecycle/db/
  drive/offers/chat/backup). Launch-Marker (Version+Build+Commit) in `MykilOS6App.init`,
  DB-Öffnen/-Reset protokolliert. Nie Secrets im Log.
- **Redaktierter Export**: reiner `DiagnosticsReport.build(...)` (MykilosServices, nimmt per
  Konstruktion keine Geheimnisse) + „Diagnose kopieren"-Button (Settings → Diagnose) → Zwischenablage.
- Neue Tests: `GRDBDatabaseRecoverabilityTests` (gültiger Pfad → Roundtrip; unbeschreibbarer Pfad →
  wirft statt Crash), `DiagnosticsReportTests` (Identität+Handshakes enthalten; keine Secret-Marker).
- BENUTZERHANDBUCH: „Diagnose"-Abschnitt um Export + Wiederherstellung erweitert.

**Mandate G — Backup/Restore verdrahtet + echter WAL-Round-Trip ✅ (296 Tests grün)**
- `BackupService` war komplett, aber orphaned + Checkpoint nur dokumentiert. Jetzt:
  `createConsistentBackup(db:…)` ERZWINGT `db.checkpoint()` vor dem Kopieren (nicht mehr umgehbar)
  + `latestBackupFolder()`.
- **Backup verdrahtet**: `AppState.createBackup()` (off-main, `SaveState`) + „Backup jetzt"-Button
  in Settings → Diagnose (mit Status). Prune >30 Tage. Read-only auf die DB, kein externer Schreibzugriff.
- **Restore verdrahtet — sicher**: `AppDatabase.restoreLatestBackupThenBoot()` nur aus der
  `DatabaseRecoveryView` erreichbar (DB ist dort NICHT offen → kein Risiko durch offenes Handle).
  `BackupService.restore` ist atomar (temp+move), prüft SHA-256, legt vorher Rettungsbackup an.
- **Echter WAL-Round-Trip** (ersetzt den String-Copy-Fake): reale on-disk GRDB-DB (WAL) → Zeile
  schreiben → `createConsistentBackup` (Checkpoint) → ALLE DB-Dateien löschen → `restore` →
  neu öffnen → Zeile (777) wieder da. Plus SHA-256-Known-Vector („abc") + `latestBackupFolder`-Test.

---

### Core Repair (PR #3) — Mandate A–G alle code-fertig ✅

Branch `polish/dampflok`, lokal (KEIN Push/Merge ohne Johannes' Freigabe). **296 Tests grün, 48 Suites.**
Reihenfolge gefahren: E → A → B → D → C → F → G (Hustadt-kritische zuerst). Jeder Schritt build+test grün.
Offen = ausschließlich Live-Abnahme am echten Gerät (Hustadt-Gate, siehe Handoff). Keine externen Schreibzugriffe.

---

## 2026-06-28 · Claude Code — Forensik-Session + Übergabe Core Repair

```
Branch: polish/dampflok HEAD 00d3833
Build:  ✅ swift build grün
Tests:  ✅ 243 Tests grün — keine Änderung
```

**Keine Code-Änderungen.** Reine Forensik-Session.

**Forensik-Audit (60 Agenten, 51 Befunde, 42 bestätigt):**
- Wurzel-Ursache identifiziert: Proxy-Optimierung (Tests grün, Ledger-Checkmark) statt
  Ziel-Verifikation (Feature läuft live mit echten Daten für echten Nutzer).
- L23 GmailCacheStore: committed ✅ aber nie in Production verdrahtet ❌.
- DataFlowLogger Bug: `toolUse.name` ("search_gmail") statt Manifest-ID ("GMAIL_SEARCH")
  → Schaltzentrum zeigt 0 Handshakes für alle 8 Tool-Zeilen.
- `driveReadonly` Scope fehlt in `readOnlyDefaults` → nie angefragt bei Login.
- `driveFolderPath` existiert, wird nie befüllt.
- OffersTabView: kein Rekursion, kein nextPageToken, keine Tests.
- `AppDatabase.production` verwendet `try!` → 7 IPS Crash-Reports.
- Zwei divergente Datenstrom-Manifests (docs vs Resources).
- AGENTS.md: veralteter Stand (Akt-5, 80 Tests), nicht synchron mit CLAUDE.md.

**Übergabe:** 13 Forensik-Fragen vollständig beantwortet mit Ursache/Datei/Test-Gap/
Gegenmaßnahme → `docs/handoffs/HANDOFF_POLISH_DAMPFLOK.md`.

**Nächste Session:** Core Repair (Codex-Mandate A–G). Abnahme-Kriterium: Hustadt-Projekt
(`driveFolderID: 13ITPqAMdz6JrS13u8y7JvkTVXAWznA_S`) besteht Live-Gate.

---

## 2026-06-28 · Dampflok Iter. 0 + L1 — polish/dampflok Branch Setup + BrainSeedProvider

```
Branch: polish/dampflok (von main)
Build:  ✅ swift build grün
Tests:  ✅ 207 Tests grün (+6 neue: BrainSeedProviderTests)
```

**Iteration 0 (Setup):**
- Branch `polish/dampflok` angelegt + gepusht.
- `docs/POLISH_LOOP_LEDGER.md` erstellt (L1–L30, alle pending).
- Airtable-Tabelle `Polish-Log` (`tblberJMgRArGSypE`) in `appuVMh3KDfKw4OoQ` angelegt.
- `SCHALTZENTRUM_DATENSTROM.md`: Weiche `POLISH_LOG_WRITE` eingetragen.

**L1 — Kalkulation echt:**
- `AppState.swift`: `BaselineAnchorProvider()` → `BrainSeedProvider()` (Fallback bleibt).
- `BrainSeedProvider.swift` in MykilosServices tracked und wirksam.
- `Parsing.swift`: `parseRun` um Küche-Pattern erweitert (`5m Eichenküche` → 5 lfm).
- `BrainSeedProviderTests.swift`: 6 Tests — CSV-Parse, Fallback, Smoke DoT > 0.
- Commit: 51b8ed0. Polish-Log L1: done.

**L4 — Lern-Loop-Politur:**
- `KalkulationsWidget.anpassen()`: nach `.saved` 2,5 s → `.idle` + Felder-Reset
  (faktor/grund/lernen), damit sofortige Folgeanpassung möglich.
- `KalkulationsWidget.promote()`: `promoteBestaetigung` nach 3 s auto-clear.
- `promoteSchreibtAuditEntry()` GATE-Test: end-to-end Audit-Pfad verifiziert
  (3× recordAdjustment → Kandidat → promote → AuditEntry.calibrationPromoted,
  3× AuditEntry.estimateAdjusted in GRDBDatabase).
- Bestehende Cold-Start-Tests grün (Regression geprüft).
- 216 Tests grün. Commit: 60c9abd. Polish-Log L4: done.

**L3 — Geräte & Stundensätze:**
- `StundensatzLoader.swift`: `merge(airtableRecords:base:)` merged Airtable-Werte
  aus Clockodo-Leistungen gegen CostModel.stages-Hardcode (8 Keys). Name-Matching
  für alle 8 Gewerk-Keys. Null-Raten und unbekannte Namen ignoriert. Beide Formate
  (fieldName + fieldID) unterstützt.
- `StundensatzLoaderTests`: 6 Tests — Hardcode, Leer, Override, Unbekannt, NullRate, fieldID.
- `DeviceCatalog.loadDefault()` war bereits live seit L1. Weiche `DEVICE_CATALOG_LOAD`
  in Airtable Datenstrom-Handbuch registriert.
- 215 Tests grün. Commit: 573c16e. Polish-Log L3: done.

**L6 — Knoten-Link + DatastromManifest (e17d07e):**
- `Sources/MykilosApp/Resources/DatastromManifest.json`: 22 Weichen als JSON-Array mit
  `integrationID`, `name`, `system`, `direction`, `link` (`mykilos://datastream/<ID>`).
- `DatastromManifestTests.swift`: 6 GATE-Tests — Datei vorhanden, gültiges JSON, count ≥ 3,
  alle integrationIDs gesetzt, alle Pflichtfelder, Link-Format korrekt.
- 223 Tests grün (+6). Commit: e17d07e.

**Datenpfad-Fix (5b955b6) — BrainSeedProvider + DeviceCatalog:**
- `BrainSeedProvider.defaultURL`: sucht zuerst `~/Claude/Projects/mykilOS/MYKILOS 6/_Daten/Kalkulation/Brain/active_price_anchors.csv`, dann Application Support als Fallback.
- `DeviceCatalog.defaultURL()`: analog für `Devices/catalog.csv`.
- Beide CSVs liegen bereits bereit (203 echte Tischler-Anker, 5.565 Geräte/Beschläge). Keine Test-Änderung nötig.
- 217 Tests grün. Commit: 5b955b6.

**L5 — Alle Ströme instrumentieren (DataFlowLogger):**
- `ConversationEngine.swift`: `dataFlowLogger: DataFlowLogger?` in `init` aufgenommen.
  `runLoop`: nach jedem `registry.run(...)` → `dataFlowLogger?.log(integrationID: toolUse.name, ...)`.
  Loggt `.success` oder `.error` je Tool-Ergebnis.
- `AppState.swift`: `ConversationEngine(... dataFlowLogger: dataFlow)` — `dataFlow` wird live injiziert.
- `ConversationEngineTests.swift`: `dataFlowLoggerLogtJedesToolRun()` GATE-Test — scripted
  `schaetze_projekt` tool_use → Logger enthält genau 1 Entry mit integrationID==„schaetze_projekt",
  action==.success.
- 217 Tests grün. Commit: 5d50c26. Polish-Log L5: done.

**L7 — SchaltzentrumView in Settings (1af4888):**
- `SettingsView.swift`: `SchaltzentrumView()` nach `privateAreaSection` eingefügt.
- `KatalogeView.swift`: Quote-Fix — unterminated string literal durch deutsche „"-Anführungszeichen → escapte ASCII-Quotes.
- 225 Tests grün. Commit: 1af4888. Polish-Log L7: done.

**L2 — Schätzchat-Toggle:**
- `AssistantTool.swift`: `schaetzDefinitions()` → nur `schaetze_projekt`.
- `ConversationEngine.swift`: `schaetzModusEnabled: Bool` Parameter, isoliert Tool-Liste,
  setzt `effectiveProjectID = "schaetzung"` wenn kein Projekt; Mail/Kalender/Drive-Sperre.
- `AssistantChatView.swift`: `@AppStorage("assistant.schaetzModus")`, optInBar zweigeteilt,
  Composer-Tint amber + Placeholder-Wechsel bei aktivem Modus.
- `ConversationEngineTests.swift`: 2 GATE-Tests + `FakeKalkulationsEngine`.
- 209 Tests grün. Commit: d5b1c1a. Polish-Log L2: done.

---

## 2026-06-28 · S17 — Security-Härtung + Google Identity (feat/security-haertung)

```
Branch: feat/security-haertung (von main)
Build:  ✅ swift build grün
Tests:  ✅ 209 Tests grün (190 swift-testing + 19 XCTest, +11 neue)
```

**Aufgabe 1 (No-Op bestätigt):** `AirtableSyncService.swift` existiert in keinem Swift-File/Ref. Guard-Grep leer (Exit 1).

**Aufgabe 3 — baseID-Validierung:**
- `AirtableError.invalidBaseID(String)` (neu in `AirtableClient.swift`)
- `AirtableAuthService.connect` validiert: `hasPrefix("app") && (15...22).contains(count)`
- 4 neue Tests in `AirtableAuthServiceTests.swift`
- Bestehende Tests: `"appXYZ"` → `"appuVMh3KDfKw4OoQ"` (zu kurz für Validierung)

**Aufgabe 4 — PAT-Cleanup:** Dokumentiert in `docs/PAT_CLEANUP_S17.md`.
Manueller Schritt ausstehend (Johannes): SCHATZ-Workspace + Artikel-DB-Write aus PAT entfernen.
Mastermind-Schreibrechte bleiben erhalten (Kalkulations-Port schreibt dort).

**Aufgabe 2 — Google Identity:**
- `GoogleUserInfo(email, displayName)` in `MykilosKit/Domain/`
- `GoogleOAuthScope.readOnlyDefaults` + `userinfoEmail` + `userinfoProfile`
- `GoogleTokenStoring`-Protokoll + `KeychainGoogleTokenStore` um userInfo erweitert
- `GoogleUserInfoClient.swift` (neu): `GoogleHTTPClient`-Protokoll, testbar via FakeHTTP
- `GoogleAuthService`: `currentUser`, userInfoClient injizierbar, Hook nach Token-Tausch (nicht-fatal)
- `AppState.currentGoogleUser` (computed, forwarding)
- `SidebarView` navFoot zeigt Google-Name + E-Mail wenn verbunden
- 7 neue Tests in `GoogleUserInfoClientTests.swift`

**Offen:** Re-Consent live verifizieren (Johannes neu verbinden für neue Scopes).

---

## 2026-06-28 · S10 Learning — Tisch-Session: Architektur-Klärungen + S17 gestartet

```
Branch: main (S17 auf feat/security-haertung)
Build:  ✅ 198 Tests (S16-Stand)
```

**Entscheidungen und neue Regeln:**
- **Studio-Stundensätze** (KO-DE+H 120€/h, PRMG 5.000€) — KOMPLETT GETRENNT von KalkulationsEngine. Engine schätzt nur Tischlerarbeiten.
- **Artikel- & Einkaufsdatenbank** `appdxTeT6bhSBmwx5` entdeckt. 13.419 Studio-Produkte (Leuchten, Armaturen, Öfen). **READ ONLY** — write-Tabu in Charter + Gedächtnis verankert.
- **PAT-Sicherheitslücke** identifiziert: bestehender PAT hat write-Zugriff auf Artikel-DB + MYKILOS-SCHATZ-Workspace (alter mykilO$$$-Tryout). S17 bereinigt.
- **ConversationEngine-Architektur** (S16-Korrektur): Tool-Use-Schleife, kein Intent-Switch. S18 + S19 bauen neue Tools in `AssistantToolRegistry`.
- **S18 Kalkulations-Chat-Tool**: projektID via `scope`-Threading, `schaetze` darf schreiben (EstimateSession für Lern-Loop-Referenz).
- **Roadmap aktualisiert**: S17 Security+PAT, S18 Kalkulations-Chat-Tool, S19 Artikel-Suche-Tool, S20 Clockodo.
- **TEAM_BRIEFING.md** erstellt (`docs/TEAM_BRIEFING.md`) — Onboarding-Dokument für alle künftigen Sessions.

**S17 gestartet** — `claude-sonnet-4-6`, Normal Effort.

---

## Branch-Übersicht (Stand 2026-06-28)

| Branch | Basis | Tests | Zweck |
|---|---|---|---|
| `main` | — | **198** ✅ | **Aktueller Stand (S16-FF, 2026-06-28):** Live-Wiring + Assistent + Kalkulation 1–8. Subsumiert `stabilize` + die gesamte Kalkulations-Branch-Kette. |
| `stabilize/from-0b7c366-2026-06-28` | `0b7c366` | 169 | Codex Recovery — **jetzt in `main` enthalten** (Vorfahre der S16-Kette) |
| `sprint/shared-drive-widget-oauth` | `0b7c366` | 169 | Aktive Features (Wiring-Sessions 1–3) + Session-Docs |
| `feat/conversational-assistant` | älter | 163 | Konversationeller Assistent Phase 1–2 |
| `clickup-integration` | älter | 103 | ClickUp-Widget (gemergt in sprint?) |
| `drive-offer-watcher` | älter | 114 | DriveOfferWatcher (gemergt in sprint?) |
| `claude/musing-sammet-3abd94` | sehr alt | ~97 | Claude Code Desktop Worktree — VERALTET |
| `claude/hungry-ardinghelli-8e798a` | sehr alt | ? | Claude Code Desktop Worktree — VERALTET |
| `claude/loving-shamir-c7ff05` | sehr alt | ? | Claude Code Desktop Worktree — VERALTET |

**Aktiver Entwicklungs-Branch:** `main` (S16-Kette als Fast-Forward gemergt, 2026-06-28).
Verbleibende Abzweigungen, bewusst NICHT in `main` (eigene Entscheidung von Johannes):
`claude/musing-sammet-3abd94` (PR #1, läuft aktiv — Statut 2, nicht anfassen),
`sprint/shared-drive-widget-oauth` (+70, divergent). PR #2 `feat/kalkulation-core-port`
ist durch die S16-Kette subsumiert → geschlossen.

---

## Einträge (neueste zuerst)

---

### 2026-06-28 · Claude Sonnet 4.6 (Dampflok) — L16–L22 abgeschlossen (polish/dampflok)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `polish/dampflok` · HEAD: `3e5c60e`
**Build:** ✅ swift build grün
**Tests:** ✅ 237 Tests grün (37 Suites)
**Status:** ✅ L16–L22 fertig, auf origin gepusht

**Was gebaut wurde:**
- L16/L17/L18: Bereits vollständig implementiert (parallel agent) — `downloadContent`, `FilePreviewView`, DriveTreeRow-Popover
- L19: `format=full`, `GmailAttachment`-Struct, `extractAttachments` (rekursiv), Tool-Output mit Dateinamen (+4 Tests)
- L20: Angebote-Tab Suchfeld + Datum/Name-Sortierung + Preview-Popover (Icon-Klick → FilePreviewView)
- L21: `GlobalOffersView` bereits vollständig implementiert
- L22: `CashWidget` emittiert `budgetThresholdCrossed` nach Sevdesk-Load (ratio ≥ 90%)
- Fix: zip-Dateien (files.zip, skills/) aus Tracking entfernt + .gitignore ergänzt

**Offen (L23–L30):** GmailCacheStore, Kontakt-Kontext, Favoriten, Timeline, Leerzustände, Test-Decke, Abschluss-Handoff

---

### 2026-06-28 · Claude Sonnet 4.6 (Dampflok) — L6–L15 abgeschlossen (polish/dampflok)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `polish/dampflok` · HEAD: `be51948`
**Build:** ✅ swift build grün
**Tests:** ✅ 233 Tests grün (37 Suites) — inkl. Drive-Thumbnail-Fix (urlEnthaeltOrdnerIDUndFelder)
**Status:** ✅ L6–L15 fertig, auf origin gepusht

**Was gebaut wurde (Block 2–4):**
- L6: `DatastromManifest.json` (22 Weichen) + 6 GATE-Tests (`DatastromManifestTests`) → Knoten-Links live
- L7: `SchaltzentrumView` (Live-Anzeige Weichen + letzter Handshake) in `BrandsView` + `SettingsView`
- L8: `DatastromAuditTests` — scannt `.swift`-Dateien auf hardkodierte `integrationID`-Strings vs. Manifest
- L9: `BrandsView` → „Integrationen" (Umbenennung), `AppModule.brands.rawValue` angepasst
- L10: `KatalogeView` (read-only Gerätekatalog, Suche, 200 Zeilen max, Hover) + `AppModule.kataloge` (⌘8)
- L11: `SearchKatalogTool` in `AssistantToolRegistry.standard()` + 5 GATE-Tests
- L12: `ToolCallRow` bekommt Zeitstempel (relative Anzeige); `activityLabel()` um 5 Tool-Namen erweitert
- L13: Gmail-Labels bereits vollständig — kein Change nötig
- L14: `ThinkingIndicator` (3-Punkt-Bounce, Timer 0.42s) + Streaming-Cursor `▌` in `AssistantChatView`
- L15: `katalogEnabled` in `ConversationEngine.send()` → `AssistantGrounding.systemPrompt()`, Tool-Hint im Prompt

**Offene Punkte nach L15:**
- L16: Drive-Scope + `downloadFileContent` (Block 5 beginnt)
- BENUTZERHANDBUCH + EREIGNISPROTOKOLL in diesem Commit nachgezogen

---

### 2026-06-28 · Claude Sonnet 4.6 (angry-benz-2df776) — P0 Fix-Versuch 1 ABGEBROCHEN

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `main` · HEAD: `dd235ab` (keine neuen Commits, alle Änderungen ungestaged)
**Build:** ✅ (swift build + build_and_run.sh — alle uncommitted Changes eingebaut)
**Tests:** nicht ausgeführt
**Status:** 🚨 ABGEBROCHEN — Live-Test negativ

**Änderungen (ungestaged, nicht committet):**
- `ProjectGalleryView.swift`: `ZStack(alignment: .topLeading)` + `ProjectDetailView.frame(maxWidth: .infinity, maxHeight: .infinity)`
- `ProjectDetailView.swift`: `Color.clear`-Filler aus Grid entfernt + Grid bekommt `.frame(maxWidth: .infinity, alignment: .topLeading)`
- `CLAUDE.md`, `IDEEN_UND_BACKLOG.md`, `EREIGNISPROTOKOLL.md`, `TEAM_CHARTER.md`: P0-Dokumentation + Team-Rufname
- `MykilOS6App.swift` (andere Session): `detailPane` → GeometryReader + `.frame(width: proxy.size.width, ...)` + `.contentShape(.interaction, Rectangle())`

**Live-Test-Ergebnis:** Tab-Leiste zeigte nur `Angebote | Timeline | Material` — Tabs 1–3 verdeckt hinter Sidebar. Sidebar weiterhin nicht anklickbar. Inhalt ca. 1 Sidebar-Breite nach links verschoben. Kein Fortschritt gegenüber Vorstand.

**Verbleibende Root-Cause-Hypothese (für Codex):**
`ZStack(alignment: .bottom)` + `VStack(spacing: 0)` (ohne alignment, = center) in `ProjectDetailView.body` Zeile 25–26. Fix: beide auf `.bottomLeading` / `alignment: .leading` setzen. Details in `HANDOFF_P0_OVERVIEW_SIDEBAR_HITTEST.md` — Abschnitt „CRASH-REPORT: Gescheiterter Fix-Versuch 1".

---

### 2026-06-28 · Codex + Johannes — P0 bestätigt: Übersicht blockiert sichtbare Sidebar

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `main` · HEAD bei Untersuchung: `dd235ab`
**Build:** nicht neu ausgeführt (forensische Dokumentation, keine Codeänderung)
**Tests:** 192 laut Commit `dd235ab`, in dieser Dokumentationsrunde nicht neu ausgeführt

**Status: 🚨 OFFEN · P0 · RIESIGER PRODUKTBUG.**

Johannes hat den Fehler mit fünf Live-Screenshots vom 2026-06-28 um
09:38/09:39 eindeutig belegt:

- `Bildschirmfoto 2026-06-28 um 09.38.54.png` — Tab „Angebote“, Sidebar und
  Detailinhalt korrekt.
- `Bildschirmfoto 2026-06-28 um 09.38.59.png` — Tab „Timeline“, Sidebar und
  Detailinhalt korrekt.
- `Bildschirmfoto 2026-06-28 um 09.39.02.png` — Tab „Material“, Sidebar und
  Detailinhalt korrekt.
- `Bildschirmfoto 2026-06-28 um 09.39.09.png` und `09.39.12.png` — Tab
  „Übersicht“: Hero-/Tab-Inhalte links abgeschnitten, Sidebar sichtbar, aber
  nicht anklickbar.

**Forensischer Schluss:**

Die Sidebar wird weder logisch ausgeblendet noch verliert sie ihren
Navigations-State. Ausschließlich die Übersicht erzeugt über
`ProjectWidgetBoardView` eine überbreite Detail-/Hit-Test-Fläche. Diese Fläche
ragt unsichtbar über die Sidebar und fängt deren Klicks ab. Dass der Hero-Titel
`SCHMIDT` nur noch als `DT` und `Assistent` nur noch als `sistent` sichtbar ist,
belegt die horizontale Verschiebung des gesamten Detailinhalts.

Der tab-spezifische Größen-Treiber ist das SwiftUI-`Grid` der Übersicht mit:

```swift
if row.needsFiller {
    Color.clear.gridCellColumns(row.fillerSpan)
}
```

`Color.clear` ist im Grid eine flexible Zelle. Zusammen mit intrinsisch breiten,
asynchron wechselnden Widget-Inhalten kann das Board breiter als das rechte
Content-Pane werden. Der in `dd235ab` ergänzte `.clipped()`-Schutz maskiert die
überstehende Darstellung, begrenzt aber nicht zuverlässig die Interaktionsfläche.

**Harter Fixvertrag:**

1. `Color.clear`-Filler entfernen oder mindestens horizontal von der
   Grid-Größenbestimmung ausschließen.
2. Widget-Board-Breite explizit aus der verfügbaren Content-Pane-Breite ableiten;
   Widget-Inhalte dürfen diese niemals vergrößern.
3. Interaktionsfläche des rechten Panes ausdrücklich auf dessen sichtbaren Frame
   begrenzen; Sidebar muss in der Trefferreihenfolge geschützt bleiben.
4. `WindowGuard`, `.clipped()`, `.fixedSize` und Unit-Tests gelten allein nicht
   als Abschlussbeweis.
5. Live-Abnahme: Übersicht öffnen, unmittelbar sowie nach 300/800/1800 ms alle
   Sidebar-Ziele anklicken; Hero `SCHMIDT`, Back-Button und komplette Tab-Leiste
   müssen sichtbar bleiben.

**Dauerhafte Regel:** Dieser Eintrag darf erst auf ✅ gesetzt werden, wenn die
Live-Abnahme dokumentiert ist. „Build grün“ oder „192 Tests grün“ schließen den
P0 nicht.

**Handoff:** [HANDOFF_P0_OVERVIEW_SIDEBAR_HITTEST.md](handoffs/HANDOFF_P0_OVERVIEW_SIDEBAR_HITTEST.md)

---

### 2026-06-28 · S10 Learning — S20 Sprint-Vorbereitung (keen-williamson-ddb354)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`  
**Branch:** `claude/elegant-nobel-ee5ece` (Zielbranch für S20)  
**Build:** kein Build (Learning-Session)

**Root Causes aufgedeckt und dokumentiert:**
- Keychain-Prompts (18×): ACL gebunden an Binary-Hash des jeweiligen Builds
- Board-Layout-Bug (AssistantWidget Pos 0): alte GRDB-Daten, kein Migration-Reset
- Drive permissionRequired: S17 hat neue userinfo-Scopes hinzugefügt → Re-Consent nötig
- Airtable-Sync still: `baseID`-Feld im Keychain enthält zweiten PAT statt `appuVMh3KDfKw4OoQ`
- Airtable-Writes (Eingehende-Angebote, Kalkulations-Positionen): nie gebaut

**Was gemacht wurde:**
- `AssistantGrounding.swift` Ton-Fix: Emojis, Floskeln, KI-Selbstbezug unterdrückt
- `docs/handoffs/STARTPROMPT_S20.md` vollständig geschrieben (8 Aufgaben, Reihenfolge, NO-GOs)
- `docs/erfahrungstraeger/S10_Learning_S20_Prep.md` verfasst

**Offen (S20):** Keychain-ACL-Migration, Board-Layout-Reset, Zeichnungen-Tab,
Timeline-Tab, Airtable `createRecord`, BaseID-Fehleranzeige.

---

### 2026-06-28 · Claude Code (Opus 4.8, S16) — Lern-Loop sichtbar: Kalibrierungs-Kandidaten + Promote-Flow (Schritt 8)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `feat/kalkulation-calibration-loop` (abgezweigt von `feat/kalkulation-record-adjustment`)
**Build:** ✅ | **Tests:** 198 grün (179 swift-testing + 19 XCTest)

**Was gemacht wurde:**
- `KalkulationsEngineProviding` (MykilosKit): `recordAdjustment` bekommt einen
  `lernen: Bool`-Parameter. Kein Default am Protokoll-Requirement (Swift erlaubt das
  nicht) — stattdessen eine `extension`-Convenience-Overload mit der alten 3-Argument-
  Signatur (`lernen: false`), damit alle Schritt-7-Aufrufer (Tests, Call-Sites)
  quellkompatibel bleiben und unverändert grün sind.
- Neue Protokoll-/Engine-Methoden `lernUebersicht() -> KalkulationsLernStand` und
  `promote(candidateID:)`. `KalkulationsLernStand`/`KalkulationsFaktor`/
  `KalkulationsKandidat` sind neue Sendable-Value-Types in MykilosKit — die Core-Typen
  (`CalibrationFactorCandidate` etc.) leaken NICHT ins Widget (das MykilosKalkulationsCore
  nicht importieren darf). `KalkulationsEngine.mapLernStand` mappt die Kern-`LearningSummary`.
- `KalkulationsEngine.recordAdjustment` reicht `learn: lernen` an `appendAdjustment`
  durch; `promote` ruft `LearningStore.promoteCalibration` und schreibt einen `AuditEntry`
  mit `action: .calibrationPromoted` (Sentinel-`projectID` "kalkulation", da Kalibrierung
  projektübergreifend ist).
- `AuditEntry.Action.calibrationPromoted` ergänzt (rawValue-persistiert → migrationssicher).
- `KalkulationsWidget`: „Für künftige Schätzungen lernen"-Toggle an der ActionCard
  (setzt `lernen: true`) + neue ausklappbare Sektion „Gelernte Kalibrierung" mit allen
  Renderstates (loading / leer / Inhalt / Fehler): aktive Faktoren (grün), promotebare
  Kandidaten mit „Übernehmen"-Button → `engine.promote` → Bestätigung sichtbar,
  Outlier-Zähler dezent. Schreiben weiterhin nur bestätigungspflichtig über die Engine.

**Neuer Cold-Start-Test (Merge-Gate):** `lernLoopUeberlebtNeustartUndVerschiebtSchaetzung`
— 3× `recordAdjustment(lernen: true)` über die Engine (BaselineAnchorProvider für eine
echte, positive Baseline) → Kandidat → `promote` → frische Store-Instanz auf derselben
`learning.sqlite` → aktiver Faktor lesbar UND der `EvidenceBasedEstimator` nutzt ihn:
`mitteNetto` verschiebt sich messbar (+10 %) gegenüber der unkalibrierten Baseline.

**Berührte Daten:** nur lokale temporäre `learning.sqlite` in `NSTemporaryDirectory()`
(Test-Verzeichnisse, im `defer` gelöscht). Keine externen Daten (Airtable/Drive/Sevdesk)
gelesen oder geschrieben.

**Status:** Branch sauber, 198 Tests grün, keine Regressions, Token-Disziplin geprüft
(kein `.font(.system)`/`Color(red:)` im Widget). Kein Push ohne Freigabe von Johannes.

---

### 2026-06-28 · Claude Code (Opus 4.8, S15) — recordAdjustment-Flow + KalkulationsActionCard (Schritt 7)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `feat/kalkulation-record-adjustment` (abgezweigt von `feat/kalkulation-core-port`)
**Build:** ✅ | **Tests:** 197 grün (178 swift-testing + 19 XCTest)

**Was gemacht wurde:**
- `KalkulationsEngine.recordAdjustment` implementiert (vorher Stub): bestätigte
  Anpassung → `LearningStore.appendAdjustment` (append-only) + `AuditEntry`
  (`action: .estimateAdjusted`). `faktor → percentDelta = (faktor-1)*100`,
  `reason: .gutFeeling`, `target: .wholeEstimate`, `learn: false`, `grund → note`.
- `schaetze` persistiert jetzt die `EstimateSession` (`saveSession`) und gibt deren
  ID als neues Feld `KostenSchaetzung.schaetzungsID` zurück — vorher wurde keine
  Session persistiert, es gäbe keine ID, gegen die man eine Anpassung buchen kann.
- `AuditEntry.Action.estimateAdjusted` ergänzt (rawValue-persistiert → migrationssicher).
- `KalkulationsEngine.init` nimmt optionalen `auditStore`; `AppState` übergibt `audit`.
  In-Memory-Map `projektIDBySession` liefert das `projectID` für den Audit-Eintrag.
- `KalkulationsActionCard` im `KalkulationsWidget`: Faktor-Schieberegler + Freitext-
  Begründung + „Anpassung buchen"-Button + Statuszeile. Erscheint erst nach einer
  Schätzung, Bestätigungspflicht (kein Auto-Write), schreibt nur über die Engine.
- **Vorab-Commit** (eigener Commit): `WindowGuard.guardWindowPositionOnAppear()` +
  Verdrahtung in `ProjectDetailView` gegen Fenster-Drift durch async Widget-Loads
  (lag uncommitted im Worktree).

**Neuer Cold-Start-Test:** `recordAdjustmentUeberlebtNeustart` — Anpassung über den
echten Engine-Pfad geschrieben, nach Neustart aus frischer Store-Instanz lesbar.
Plus `recordAdjustmentBuchtAnpassungGegenSchaetzung` und
`recordAdjustmentMitUnbekannterSessionWirft` (Engine-Tests).

**Status:** Branch sauber, 197 Tests grün, keine Regressions. Kein Push ohne Freigabe.

---

### 2026-06-28 · Claude Code (Sonnet 4.6, S14) — KalkulationsWidget + Kalkulations-Tab (Schritt 6)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `feat/kalkulation-core-port`
**Build:** ✅ | **Tests:** 175 grün

**Was gemacht wurde:**
- `WidgetKind.kalkulation` in `WidgetFoundation.swift` ergänzt
- `SourceChip.swift` um `.kalkulation` → `"eurosign.square"` erweitert
- `WidgetContainer.swift` um `.kalkulation` → `.tasks` (Ocker-Akzent) erweitert
- `KalkulationsWidget.swift` neu: alle 6 Renderstates, Freitext-Eingabe, Schätz-Button,
  Min/Mitte/Max-Netto, Konfidenz-Badge, Top-3-Evidenzen, Kostenboden, Quellenzeile
- `AppModule.kalkulation` + `KalkulationsPageView` in `MykilOS6App.swift` (Sidebar-Tab
  nach "Angebote", ⌘6, reicht `appState.kalkulationsEngine` durch)
- `HANDOFF_KALKULATION_CORE_PORT.md` um Schritt 6 ergänzt

**Kein neues persistierbares Feature → kein neuer Cold-Start-Test nötig.**

---

### 2026-06-28 · Claude Code (Sonnet 4.6) — Session-Abschluss Kalkulations-Port + App-Preview

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `feat/kalkulation-core-port`
**Build:** ✅ | **Tests:** 194 grün

**Was gemacht wurde:**
- **App-Preview** via `./script/build_and_run.sh` — App gestartet, Heute-Board mit
  personalisierten Begrüßung + Projekten + Navigation + Dark Mode vollständig funktionsfähig.
  Kein Crash durch die neu verdrahtete `KalkulationsEngine` in `AppState`. ✅
- **Handoff-Dokument** `docs/handoffs/HANDOFF_KALKULATION_CORE_PORT.md` erstellt:
  vollständige Dokumentation aller 5 Schritte (Verbatim-Prinzip, Cold-Start-Gate,
  Architektur-Entscheidungen, offene Stubs, Nächste Schritte).
- **CLAUDE.md** aktualisiert: Kalkulations-Port Schritt 5 in die Fortschritts-Tabelle
  eingetragen, Link auf Handoff gesetzt.
- **Session-Modus geändert:** Modell auf `claude-sonnet-4-6` für Abschluss-Session.

**Status:** Branch `feat/kalkulation-core-port` ist sauber, 194 Tests grün,
kein Push ohne Johannes' Freigabe.

**Offene Stubs (bewusst, kein Merge-Blocker):**
- `importPDF` → braucht `GoogleDriveClient.downloadFile()`
- `recordAdjustment` → braucht ActionCard → Bestätigungs-Flow (UI-Schritt)

**Nächste natürliche Schritte (nach Freigabe):**
1. Kalkulations-Widget / UI (`KalkulationsView`-Tab, `KalkulationsActionCard`)
2. Seed-Provider mit destillierten Ankern (SQLite + CSVs aus mykilO$ App-Support)
3. PREISLISTEN CSV nach Application-Support kopieren (explizite Freigabe)

---

### 2026-06-28 · Claude Code (Opus 4.8) — Engine in AppState verdrahtet + Baseline-Anker (Schritt 5)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `feat/kalkulation-core-port`
**Build:** ✅ | **Tests:** 194 grün (175 swift-testing + 19 XCTest)

**Was gemacht wurde:**
- `BaselineAnchors.swift` verbatim portiert (6 hartcodierte Regelanker, Foundation-only,
  KEINE externen Daten) + eigener `BaselineAnchorProvider: PriceAnchorProviding`.
- **`AppState.kalkulationsEngine` live verdrahtet** (konstruiertes `let`, Muster wie
  `assistantLLM`): `KalkulationsEngine(provider: BaselineAnchorProvider(),
  learningStore: LearningStore(), deviceCatalog: DeviceCatalog.loadDefault())`.
  → Die Engine ist jetzt Teil der laufenden App und liefert echte konservative
  Schätzungen ohne externe Datei; `geraetepreis` wird real, sobald die Preisbuch-CSV
  in Application-Support liegt.
- Test `schaetzeMitBaselineAnkernLiefertEchteZahlen`: mitteNetto > 0, evidenceCount > 0,
  min ≤ mitte ≤ max — beweist den nicht-leeren Pfad.
- SwiftLint-Ausnahme um `BaselineAnchors.swift` erweitert (vendored); `BaselineAnchorProvider`
  ist eigener Code, voll gelintet.

**Doku-Hinweis:** Johannes' Airtable-Entscheidung (1 Base bleibt, Airtable=Master/GRDB=Cache)
in CLAUDE.md + IDEEN_UND_BACKLOG.md bleibt seine uncommittete Änderung — bewusst nicht in
diesem Commit gemischt.

**Adapter-Stand:** `schaetze` ✅ + `geraetepreis` ✅ live in der App. Stubs: `importPDF` (Drive),
`recordAdjustment` (Bestätigungs-Flow). Kein Push ohne Freigabe.

---

### 2026-06-28 · Claude Code (Opus 4.8) — DeviceCatalog + `geraetepreis` live (Schritt 4)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `feat/kalkulation-core-port`
**Build:** ✅ | **Tests:** 193 grün (174 swift-testing + 19 XCTest)

**Was gemacht wurde:**
- `DeviceCatalog.swift` + `CSVParser.swift` verbatim aus mykilO$$ `KalkulationsData` nach
  `MykilosServices/Kalkulation/` portiert (Import → `MykilosKalkulationsCore`). CSV-backed,
  tolerante Spaltenerkennung, Token-Score-Suche, Daten liegen in Application-Support (nie im Repo).
- **`geraetepreis(suchbegriff:)` scharf geschaltet:** `KalkulationsEngine` nimmt optional einen
  injizierten `DeviceCatalog`; `geraetepreis` → `search().first?.sellNet` (MYKILOS-VK vor Liste) →
  Double. Ohne Katalog weiterhin nil (optionaler Lookup, kein Crash).
- **Tests:** 3 synthetische DeviceCatalog-Port-Tests (parse/BOM/Suche, in-memory) + 1 Engine-Test
  (`geraetepreis` mit injiziertem Katalog → 2190; Fehlsuche → nil). Der mykilO$$-Import-Test
  (`importCatalog`→defaultURL) bewusst NICHT übernommen — würde an den echten App-Support-Pfad
  schreiben und reale Daten berühren.
- SwiftLint-Ausnahme um die 2 neuen vendored Dateien erweitert.

**Datensicherheit:** Das echte Preisbuch (PREISLISTEN-CSV, 13.419 Artikel mit EK-Preisen) bleibt
extern (`~/Library/Application Support/MYKILOS/Kalkulationslabor/Devices/catalog.csv`), nie im Repo.
Das tatsächliche Laden der echten CSV ist ein separater Daten-Schritt (Johannes' Freigabe).

**Adapter-Stand:** `schaetze` ✅ + `geraetepreis` ✅ | Stubs: `importPDF` (Drive-Download),
`recordAdjustment` (Persistenz/Bestätigungs-Flow). Kein Push ohne Freigabe.

---

### 2026-06-28 · Claude Code (Opus 4.8) — Contract + Engine-Adapter (Schritt 3)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `feat/kalkulation-core-port`
**Build:** ✅ | **Tests:** 189 grün (173 swift-testing + 16 XCTest)

**Team-Abstimmung (S10-Kanal):** niemand konsolidiert die Basis; ich cherry-picke nur was ich
brauche; kanonische Basis = `stabilize`/mein Branch; `recordAdjustment` = **String**; ich besitze
den Engine-Port allein.

**Was gemacht wurde:**
- **Contract übernommen:** `Sources/MykilosKit/Domain/KalkulationsEngineProviding.swift` aus PR #1
  (`claude/musing-sammet`) auf die kanonische Basis geholt. Einzige Änderung: `recordAdjustment(
  schaetzungsID:)` von `UUID` → **`String`** (stabiler Schlüssel = `EstimateSession.id`). Nur die
  Datei übernommen (nicht der ganze Commit — der AppState-Slot würde auf `stabilize` kollidieren).
- **Engine-Adapter:** `Sources/MykilosServices/Kalkulation/KalkulationsEngine.swift` (`actor`,
  conformt `KalkulationsEngineProviding`). `schaetze` voll implementiert: `parse → estimate →
  Mapping EstimateResult→KostenSchaetzung` (inkl. Kostenboden aus `bottomUpCost.total`,
  Div-by-Zero-Guard für `kostenbodenRatio`, EvidenceCase→PriceEvidence).
- **Bewusste Stubs (eigene Folgeschritte, werfen klar `KalkulationsEngineError.notYetImplemented`):**
  `geraetepreis` (DeviceCatalog fehlt), `importPDF` (Drive-Download fehlt), `recordAdjustment`
  (braucht persistierte Session + Reason/Target-Mapping + Bestätigungs-Flow).
- **Tests:** `KalkulationsEngineTests` (Stub-Anker, seed-frei): Mapping-Verdrahtung + Guard +
  dass die Stubs sauber werfen.
- SwiftLint: Lern-Schicht-Ausnahme auf die **3 vendored Dateien** verengt — eigener Adapter-Code
  in `Kalkulation/` ist voll gelintet.

**Nächste Schritte:** (5) Seed-Provider `BrainSeedRepository`/`DeviceCatalog` — braucht Seed-`sqlite`
+ CSVs nach Application-Support (externe Daten, Johannes' Freigabe). (4b) `recordAdjustment`
vervollständigen, wenn Persistenz-/Bestätigungs-Flow steht. Kein Push ohne Freigabe.

---

### 2026-06-28 · Claude Code (Opus 4.8) — Kalkulations-Lern-Schicht portiert (Schritt 2)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `feat/kalkulation-core-port`
**Build:** ✅ | **Tests:** 187 grün (171 swift-testing inkl. 2 Cold-Start + 16 XCTest)

**Was gemacht wurde — Port-Reihenfolge Schritt 2 (GRDB-Lern-Schicht):**
- `Sources/MykilosServices/Kalkulation/` mit 3 verbatim portierten Dateien aus mykilO$$
  `KalkulationsData`: `LearningDatabase.swift` (GRDB-Queue, WAL, additiver Migrator v1–v3,
  `inMemory()`), `LearningRecords.swift` (GRDB-Records + `LearningCodec` + DB-Extensions +
  JSONL-Import), `LearningStore.swift` (append-only High-Level-API, `CalibrationFactorProviding`).
- Einzige Änderungen am verbatim-Port: `import KalkulationsCore` → `import MykilosKalkulationsCore`;
  modul-internes `AuditRecord` → `LearningAuditRecord` umbenannt (Kollision mit bestehendem
  `AuditRecord` in MykilosServices).
- **Cold-Start-Test = Merge-Gate erfüllt:** neue `KalkulationsLearningStoreTests` —
  `lernDatenUeberlebenNeustart` (schreiben → zweite Store-Instanz öffnet dieselbe
  `learning.sqlite` von Platte → identisch) + `appendOnlyBleibtNachNeustartErhalten`.
  `MykilosKalkulationsCore` an die Test-Target-Deps gehängt.
- SwiftLint: `Sources/MykilosServices/Kalkulation` als vendored ausgenommen (3 Zeilen > 200);
  Rest von MykilosServices bleibt voll gelintet.

**Bewusst NICHT in diesem Schritt:** `BrainSeedRepository`/`DeviceCatalog`/CSV/`ImportService`
(brauchen externe Seed-Dateien) und `AirtableSyncService` (wird gelöscht, 3 Regelverstöße).
Engine-Adapter (`KalkulationsEngine: KalkulationsEngineProviding`, `parse → estimate`, id als
String), AppState-Verdrahtung, UI → Schritt 4+.

**Basis-Konflikt bleibt offen (siehe Schritt-1-Eintrag):** PR #1 (`claude/musing-sammet`,
~97-Test-Basis) hält das Contract/Protokoll, mein `stabilize`-Stand nicht. Schritt 2 brauchte
das Protokoll NICHT (reine Persistenz). Vor Schritt 4 (Engine-Adapter conformt das Protokoll)
muss EINE kanonische Basis hergestellt werden. Kein Push ohne Johannes' Freigabe.

---

### 2026-06-28 · Claude Code (Opus 4.8) — mykilO$$ Kalkulations-Core portiert (Schritt 1)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `feat/kalkulation-core-port` (aus `stabilize/from-0b7c366-2026-06-28`)
**Build:** ✅ | **Tests:** 185 grün (169 swift-testing + 16 portierte XCTest)

**Was gemacht wurde — Port-Reihenfolge Schritt 1 (HANDOFF_LIVE_WIRING_5.md Teil 3):**
- Neues Foundation-only-Target **`MykilosKalkulationsCore`** (Geschwister zu `MykilosKit`).
- **10 Dateien verbatim** aus mykilO$$ `KalkulationsCore` portiert: AirtableOffer,
  BottomUpCost, ComponentResolver, Estimation, LearningModels, MaterialLexicon,
  Models, Parsing, Review, Version. Foundation-only am Code verifiziert (nur `import Foundation`).
- `MykilosServices` hängt jetzt von `MykilosKalkulationsCore` ab (Zielzustand für die GRDB-Adapter).
- **16 reine Core-Tests portiert** (ParserTests 4 + MaterialLexiconTests 12) als neues
  Test-Target `MykilosKalkulationsCoreTests`. Einzige Änderung: Modulname im `@testable import`.
- SwiftLint: `Sources/MykilosKalkulationsCore` als vendored ausgenommen (verbatim-Tabellen
  sprengen `line_length` absichtlich; kein SwiftUI → Token-Custom-Rules n/a).

**Bewusst NICHT in diesem Schritt (= eigene PRs danach):**
- KalkulationsData/GRDB-Schicht: `LearningStore`/`LearningDatabase` (eigene `learning.sqlite`),
  `BrainSeedAnchorProvider`, `DeviceCatalog` → Schritt 2 + **Cold-Start-Test (Merge-Gate)**.
- 14 Integrations-Tests (Estimator/Calibration) — brauchen die Data-Schicht + Seed-Dateien.
- `KalkulationsEngine`-Adapter (`parse → estimate`, id als String), AppState-Verdrahtung, UI.
- Seed-`sqlite` (11 MB) + 4 CSVs aus dem mykilO$$-Tree nach Application-Support (externe Daten).

**Offen / Übergabe:** Reconciliation `recordAdjustment(schaetzungsID:)` UUID→String steht noch aus
(Teil 3); Destillation V2-Swift-Pipeline ist entschieden, aber noch nicht gebaut.
Kein Push ohne Johannes' Freigabe.

---

### 2026-06-28 · Claude Code Desktop — Verbindungscheck + Session-Abschluss

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `stabilize/from-0b7c366-2026-06-28`
**Build:** ✅ | **Tests:** 169 grün

**Verbindungscheck (alle Keychain-Einträge geprüft):**

| Service | Keychain | Live-API |
|---|---|---|
| Airtable | ✅ PAT + baseID = `appuVMh3KDfKw4OoQ` | ✅ Kunden, Projekte, Clockodo-Nutzer, Clockodo-Leistungen |
| Claude | ✅ API-Key + Modell `claude-sonnet-4-6` | ✅ |
| Google | ✅ OAuth-Token vorhanden | in App prüfen |
| Clockodo | ✅ `johannes@mykilos.com` | in App prüfen |
| ClickUp | ✅ API-Key vorhanden | in App prüfen |
| Sevdesk | ✅ (NO-GO — nicht live geprüft) | — |

**Airtable-Bug behoben:** `baseID` im Keychain enthält jetzt korrekt `appuVMh3KDfKw4OoQ`
(zuvor fälschlich zweiten PAT-Token — von Johannes manuell in App → Einstellungen korrigiert).

**Abgeschlossen diese Session:**
- Eiserne Regel in CLAUDE.md
- EREIGNISPROTOKOLL.md angelegt (dieses Dokument)
- Alle Memories aktualisiert (canonical-folder-rule, project-current-state, airtable-keychain-bug)
- Startprompt + Modell-Empfehlung für nächste Session geschrieben

**Finaler Handoff:** `docs/handoffs/HANDOFF_SESSION_ABSCHLUSS_2026-06-28.md`

---

### 2026-06-28 · Claude Code Desktop — Eiserne Regel + Ereignisprotokoll

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `stabilize/from-0b7c366-2026-06-28`
**Build:** ✅ (Build complete)
**Tests:** 169 grün

**Was passiert ist:**
- Neue EISERNE REGEL in `CLAUDE.md` eingetragen: kanonischer Pfad, Branch-Pflichtcheck,
  Handoff-Header-Pflicht. Verhindert künftig die Ordner-/Branch-Konfusion.
- Dieses `EREIGNISPROTOKOLL.md` angelegt als dauerhaftes Nachverfolgungsdokument.

**Offene Punkte aus dieser Session:**
- `sprint/shared-drive-widget-oauth` hat Session-Docs-Commits (4b3df08, 8c28443) die noch
  nicht auf `stabilize/` sind. Inhalt: Codex-Handoffs, Drive-Tab-Docs, Orientierungs-Docs.
  → Codex oder Johannes: prüfen ob diese Docs nach `stabilize/` oder `main` gemergt werden.
- `ProjectFilesTabView.swift` aus Worktree wurde in `sprint/shared-drive-widget-oauth` committed.
  Aber der Hauptordner hat bereits `FilesTabView.swift` (fortgeschrittener). Duplikat aufräumen.

---

### 2026-06-28 · Codex — Forensic Recovery Point

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `stabilize/from-0b7c366-2026-06-28` (neu erstellt von Codex)
**Build:** ✅
**Tests:** 169 grün
**Commit:** `130e6c0 docs: mark forensic recovery point from 0b7c366`

**Was passiert ist:**
- Codex hat den Branch `stabilize/from-0b7c366-2026-06-28` von `0b7c366` aus erstellt.
- Keine Code-Änderungen. Nur forensische Dokumentation des letzten bekannten guten Stands.
- Ergebnis: 169 Tests grün, Build grün, stabiler Ausgangspunkt gesichert.

---

### 2026-06-27/28 · Claude Code Desktop (Session musing-sammet-3abd94) — Worktree-Ordner-Konfusion

**Pfad (Worktree):** `~/Desktop/CLAUDE/_mykilOS/mykilOS6/musing-sammet-3abd94/`
**Pfad (Ziel):** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch Worktree:** `claude/musing-sammet-3abd94`
**Branch Hauptordner:** `sprint/shared-drive-widget-oauth`

**Was passiert ist (Problem):**
- Claude Code Desktop-Session arbeitete im temporären Worktree unter Desktop/CLAUDE/.
- Der Worktree war auf einem ÄLTEREN Commit-Stand basierend auf `main` (~97 Tests, Version 6.0.x).
- Der Hauptordner (gelber MYKILOS-6-Ordner) war bereits auf `sprint/shared-drive-widget-oauth`
  mit Version 6.3.0 und 169 Tests.
- Dateien wurden vom Worktree in den Hauptordner kopiert (`feat: sync all session work`).
- Dabei wurden ÄLTERE Dateien auf neuere Versionen kopiert — potenzielle Regression.

**Betroffene Dateien (kopiert von alt → neu, Risiko):**
- `AppState.swift` — Worktree-Version OHNE `chat`, `conversation`, `profile`, `pendingProjectSelection`
  wurde auf die Hauptordner-Version MIT diesen Feldern kopiert. Hätte Build brechen können.
  **Stand nach Analyse:** Build war zu diesem Zeitpunkt auf `stabilize/` bereits 169-Test-grün.
  Die Kopier-Commits landeten nur auf `sprint/shared-drive-widget-oauth`, nicht auf `stabilize/`.
- `DriveWidget.swift` — Ältere Worktree-Version, fehlte Signal-Emission. Neu hinzugefügt.
- `ProjectDetailView.swift` — Ältere Version. Überschrieben.

**Ergebnis:**
- Auf `sprint/shared-drive-widget-oauth`: mögliche Regression durch ältere Datei-Kopien.
- Auf `stabilize/from-0b7c366-2026-06-28`: UNBESCHÄDIGT, weil Kopier-Commits nur auf `sprint/` gingen.
- **Empfehlung:** `sprint/shared-drive-widget-oauth` vor weiterem Merge gründlich `swift build + swift test` prüfen.

**Neu erstellt in dieser Session (im Worktree, danach auf sprint/ committet):**
- `Sources/MykilosApp/Detail/ProjectFilesTabView.swift` — Drive-Browser (ABER: Hauptordner hat bereits `FilesTabView.swift` mit gleicher Funktion + mehr Features)
- `script/airtable_verify.sh` — Prüfskript für alle Airtable-Tabellen
- `docs/handoffs/MASTER_HANDOFF_CODEX.md` — Codex-Gesamtbauplan
- `docs/handoffs/CODEX_ORIENTATION.md` — Wer ist Johannes, Tools, Konnektoren
- `docs/handoffs/CODEX_START_PROMPT.md` — Copy-paste Startprompt
- `docs/handoffs/CODEX_SESSIONS.md` — Session-Übersicht A–F
- `docs/handoffs/CODEX_HANDOFF_KALKULATION.md` — Kalkulations-Port-Anleitung

**Bekanntes Problem identifiziert:**
- Keychain-Feld `baseID` enthält fälschlich einen zweiten PAT-Token statt der echten Base-ID.
- Fix: App öffnen → Einstellungen → Airtable → Base-ID = `appuVMh3KDfKw4OoQ` eintragen.
- **Johannes muss das manuell korrigieren.**

---

### 2026-06-27 · Claude Code Desktop — Live-Wiring Session 3 (BrandsView-Fix)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `sprint/shared-drive-widget-oauth`
**Build:** ✅ | **Tests:** 169 grün
**Handoff:** [HANDOFF_LIVE_WIRING_3.md](handoffs/HANDOFF_LIVE_WIRING_3.md)

**Was passiert ist:**
- `BrandsView`-Navigationsbug behoben: `@FocusedBinding` war `nil` bei inaktivem Fenster →
  Klick auf "Einstellungen" in BrandsView tat nichts. Fix: `onNavigateToSettings`-Callback.
- Version `6.3.0` · 169 Tests grün.
- Live-App-Tour: OAuth-Handshake dokumentiert, erster echter Google-Login-Flow beobachtet.

**Offene Punkte:**
- Google OAuth live noch nicht mit echtem Account vollständig durchlaufen (nur Token-Exchange beobachtet)
- Streaming bei toolsEnabled=true: nicht-streaming wenn Claude keine Tools aufruft (V1 ok)
- CalendarActionCard-Persistenz: korrekt und gewollt, aber noch nicht live-getestet

---

### 2026-06-27 · Claude Code Desktop — Post-Akt-5 Aufgaben 15–21 (Release 6.3.0)

**Pfad:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/`
**Branch:** `sprint/shared-drive-widget-oauth` (und Vorgänger-Branches)
**Build:** ✅ | **Tests:** 169 grün
**Handoff:** [HANDOFF_POST_AKT5_15_SURFACE_COMPLETION.md](handoffs/HANDOFF_POST_AKT5_15_SURFACE_COMPLETION.md)

**Was diese Aufgaben gebracht haben:**
- **Aufg. 15** — Projekt-Assistent-Tab: `AssistantChatView` scoped auf `project.projectNumber`
- **Aufg. 16** — Profil-Sektion in Settings: Name + Rolle direkt editierbar
- **Aufg. 17** — `GlobalOffersView`: Angebote als globales Sidebar-Modul
- **Aufg. 18** — `FilesTabView` (Drive-Dateien-Browser) + `BrandsView` (Integrations-Dashboard)
- **Aufg. 19** — UX-Polishing: Begrüßung, Cmd+1..6, Signal-Strip, Sidebar-Profil
- **Aufg. 20** — Phase 3: `SuggestCalendarEventTool` + `CalendarActionCard` (URL → Browser)
- **Aufg. 21** — Signal-Badges in Galerie, projektspezifische Beispielfragen

---

### 2026-06-27 · Claude Code Desktop — Post-Akt-5 Aufgaben 12–14 (Release 6.1–6.2)

**Handoff:** [HANDOFF_POST_AKT5_12_ASSISTANT_PLAN.md](handoffs/HANDOFF_POST_AKT5_12_ASSISTANT_PLAN.md) /
[HANDOFF_POST_AKT5_13_ASSISTANT_RELEASE.md](handoffs/HANDOFF_POST_AKT5_13_ASSISTANT_RELEASE.md) /
[HANDOFF_POST_AKT5_14_BUGFIXES.md](handoffs/HANDOFF_POST_AKT5_14_BUGFIXES.md)

- **Aufg. 12** — Konversationeller Assistent: `ChatStore`, `ConversationEngine`, Multi-Turn-Chat,
  Tool-Use mit Gmail-Labels und Kalender (read-only, Opt-in). 155 Tests, Version 6.1.0.
- **Aufg. 13** — First-Run-Onboarding-Wizard + `UserProfile`/`ProfileStore`. 158 Tests.
- **Aufg. 14** — SSE-Streaming live-tippend, UserProfile im System-Prompt, 2 Bugfixes:
  Integer-Decode-Bug in Tool-Inputs, Wizard ohne Schließen-Button. 163 Tests, Version 6.2.0.

---

### 2026-06-26/27 · Codex — Post-Akt-5 Aufgaben 9–11 (Stabilisierung)

**Handoff:** [HANDOFF_POST_AKT5_11.md](handoffs/HANDOFF_POST_AKT5_11.md)

- **Aufg. 9** — `DriveOfferWatcher`: Polling auf Drive → `offerDetected`-Signal, Baseline-Semantik
- **Aufg. 10** — Angebote-Tab live: Belege aus Drive via `DriveOfferWatcher.detectOffers`
- **Aufg. 11** — Kritische Crash-Fixes:
  - Projektdetail-Crash (100% reproduzierbar auf macOS 26): content-dimensioniertes Fenster +
    `.move`-Transition → `Update-Constraints`-Endlosschleife. Fix: `.opacity`-Transition +
    `WindowGuard` + feste Mindestrahmen an ContentView.
  - Galerie-Hang ("Lade Projekte…"): `RegistryStore` lief nicht auf `@MainActor`. Fix: `@MainActor`.
  - Multi-Agent-Bug-Audit: Notiz-Datenverlust, Signal-Leck, Loader-Races u.a. behoben.
  - 118 Tests, live verifiziert.

---

### 2026-06-26 · Codex — Live-Wiring Sessions 1–2

**Handoffs:** [HANDOFF_LIVE_WIRING_1.md](handoffs/HANDOFF_LIVE_WIRING_1.md) /
[HANDOFF_LIVE_WIRING_2.md](handoffs/HANDOFF_LIVE_WIRING_2.md)

- **Wiring 1**: Airtable "mykilOS Mastermind" (Schema + 69 Records live), 31 echte Projekte
  statt DemoSeed, Force-Poll-Buttons, Angebote-Tab-Bugfix.
- **Wiring 2**: Google-Login client_secret-Fix, Fenster-Drift-Guard (WindowGuard.swift),
  Projekt-Favoriten klickbar (heute → projektdetail), Drive-Routing über alle 31 Projekte.
  **Status: Alle code-fertig, Live-Verifikation mit echtem Account ausstehend.**

---

## Bekannte offene Punkte (Stand 2026-06-28)

### Sofort — erfordert Johannes' Aktion

| # | Was | Warum dringend |
|---|---|---|
| 1 | Airtable-Keychain-Bug: App → Einstellungen → Airtable → Base-ID = `appuVMh3KDfKw4OoQ` | Alle Airtable-Checks scheitern (404). `baseID` im Keychain enthält fälschlich PAT. |
| 2 | Google OAuth vollständig live testen (Drive, Kalender, Mail) | Noch nicht mit echtem Account end-to-end durchlaufen |
| 3 | Branch-Merge: `sprint/shared-drive-widget-oauth` → `main` beschließen | Drei Feature-Branches divergieren |

### Technisch offen (kein Blocker für Beta)

| # | Was | Details |
|---|---|---|
| 4 | `ProjectFilesTabView.swift` auf `sprint/` ist Duplikat von `FilesTabView.swift` | Aufräumen nach Merge |
| 5 | Clockodo-Widget zeigt Demo-Daten, keine echten Zeiten | `ClockodoClient` implementiert, aber nicht mit echtem User-Token live |
| 6 | `ProjectFilesTabView.swift` nutzt älteres Render-Pattern | `FilesTabView.swift` hat Generation-Token für Race-Freiheit — Pattern angleichen |
| 7 | `airtable_verify.sh` warnt bei falscher Base-ID, gibt aber nur Fallback-ID | Muss nach Keychain-Fix (Punkt 1) erneut getestet werden |
| 8 | Streaming bei toolsEnabled=true ist non-streaming wenn Claude keine Tools nutzt | V1 akzeptabel, aber sichtbar für den Nutzer |
| 9 | mykilO$$ Kalkulations-Core-Target (MykilosKalkulationsCore) noch nicht portiert | `KalkulationsEngineProviding`-Protokoll + nil-Slot existieren, aber 10 Dateien fehlen noch |
| 10 | Clockodo Zuhörer (Chat → Zeitbuchung → Draft → Wochenabschluss → POST) | Live-Wiring Session 4, noch nicht begonnen |

### Architektur-Hinweise für nächste Session

- `MykilosKit` darf NIE SwiftUI oder GRDB importieren
- `MykilosWidgets` darf NIE GRDB importieren
- Sevdesk: vollständiger NO-GO (nicht in Tool-Whitelist, nicht lesen, nicht schreiben)
- Signale sind VORSCHLÄGE — Schreiben immer nur über ActionCard → Bestätigung → AuditEntry
- Jede neue Persistenz: Cold-Start-Test ist Merge-Gate

---

## Airtable-Mastermind-Base (appuVMh3KDfKw4OoQ) — Live-Tabellen

| Tabelle | ID | Status |
|---|---|---|
| Kunden | `tblXXX` (→ per Verify ermitteln) | Live, 69 Records |
| Projekte | `tblYYY` | Live, 31 Projekte |
| Clockodo-Nutzer | `tblPbly2br8mR2kaU` | Live, 4 Team-Mitglieder |
| Clockodo-Buchungen | `tblYQxlauwej7FD1w` | Live |
| Clockodo-Leistungen | `tblRtsegocdpM8CJd` | Live, 8 Services |
| Kalkulationen | `tblO3y2jdmxDnuiZj` | Live |
| Kalkulations-Positionen | `tblNamx3cHTus6gtk` | Live |
| Eingehende-Angebote | `tbliKfs5FnufjdB36` | Live |
| Preis-Beobachtungen | (noch nicht angelegt) | Geplant für mykilO$$-Destillation |

**PAT im Keychain:** `security find-generic-password -s "com.mykilos6.airtable" -a "pat" -w`

---

## Keychain-Service-Namen (vollständig)

| Service | Account | Inhalt |
|---|---|---|
| `com.mykilos6.airtable` | `pat` | Airtable PAT |
| `com.mykilos6.airtable` | `baseID` | ⚠️ enthält fälschlich zweiten PAT — muss `appuVMh3KDfKw4OoQ` sein |
| `com.mykilos6.google` | — | Google OAuth Tokens |
| `com.mykilos6.clockodo` | — | Clockodo API-Key |
| `com.mykilos6.claude` | `apiKey` | Anthropic API-Key |
| `com.mykilos6.claude` | `model` | Default: `claude-sonnet-4-6` |
| `com.mykilos6.clickup` | — | ClickUp API-Key |

---

_Letzter Eintrag: 2026-06-28 · Claude Code Desktop_
_Nächster Eintrag bitte am Anfang der Einträge-Liste hinzufügen (neueste zuerst)._
