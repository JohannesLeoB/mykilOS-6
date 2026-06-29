# mykilOS 6 — Polish-Loop Ledger

Branch: `polish/dampflok` · Erstellt: 2026-06-28

Reihenfolge = Priorität. Status: `pending` | `done` | `blocked`.

---

## Block 1 — Zahlen-Hirn

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L1 | Kalkulation echt — BrainSeedProvider verdrahten | done | 51b8ed0 | 207 | Parsing.swift küche-Pattern + 6 neue Tests |
| L2 | Kalkulator im Assistenten + Schätzchat-Toggle | done | d5b1c1a | 209 | schaetzDefinitions, ConversationEngine schaetzModusEnabled, AssistantChatView Toggle, 2 GATE-Tests |
| L3 | Geräte & Stundensätze (DeviceCatalog CSV + Airtable-Fallback) | done | 573c16e | 215 | StundensatzLoader + 6 Tests; DeviceCatalog.loadDefault() bereits live; Weiche DEVICE_CATALOG_LOAD in Handbuch |
| L4 | Lern-Loop-Politur (Promote-Flow + Audit) | done | 60c9abd | 216 | anpassen Auto-Reset 2,5s; promoteBestaetigung Auto-Clear 3s; promoteSchreibtAuditEntry GATE-Test |

## Block 2 — Daten-Hirn (Schaltzentrale)

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L5 | Alle Ströme instrumentieren (DataFlowLogger) | done | 5d50c26 | 217 | ConversationEngine.runLoop loggt jeden Tool-Call (success/error); AppState injiziert dataFlow; GATE-Test dataFlowLoggerLogtJedesToolRun |
| L6 | Knoten-Link (mykilos://datastream/<ID>) im Handbuch | done | e17d07e | 223 | DatastromManifest.json (22 Weichen) + 6 GATE-Tests (Existenz/JSON/Count/IDs/Felder/Link-Format) |
| L7 | SchaltzentrumView — Live-Anzeige Weichen + letzter Handshake | done | 1af4888 | 225 | SettingsView verdrahtet + KatalogeView-Quote-Fix |
| L8 | Vollständigkeits-Audit (SCHALTZENTRUM_DATENSTROM.md) | done | 40da1bf | 225 | Kein Gap — 3 statische IDs + 5 Tool-Namen abgedeckt; ausstehende Weichen korrekt |

## Block 3 — Artikel-Hirn (Kataloge)

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L9 | Sidebar-Umbau: brands → kataloge; Dashboard → Settings | done | 40da1bf | 225 | AppModule.kataloge + KatalogeView bereits verdrahtet (vorab committed) |
| L10 | KatalogeView: Artikel-Airtable read-only + Suche/Filter | done | 1af4888 | 225 | KatalogeView vollständig (CSV, Search, Table, emptyState, Hover) — vorab committed |
| L11 | search_katalog-Tool im Assistenten | done | 1af4888 | 225 | SearchKatalogTool + Registry.standard — vorab committed |

## Block 4 — Assistent-Vollendung

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L12 | Tool-Transparenz: Quellzeile je Tool-Lauf im Chat | done | 1af4888 | 225 | ToolCallRow + activityLabel(name:inputJSON:) — vorab committed |
| L13 | Gmail-Labels (Ablageort) im Detail-Fetch | done | 1af4888 | 225 | placement(from:) + humanLabel(_:) in SearchGmailTool — vorab committed |
| L14 | Streaming/Activity-Politur | done | d5c1509 | 230 | Cursor ▌ am tippenden Text (isStreaming + displayText) |
| L15 | Capability-Ehrlichkeit + Connect-Check | done | ccc925f | 230 | AssistantCapability + AssistantCapabilityChip — 7 Chips, farbig wenn aktiv |

## Block 5 — Datei-Vorschau

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L16 | Drive-Scope + downloadFileContent | done | e0f0df3 | 233 | thumbnailLink + downloadContent + driveReadonly (inaktiv) + 3 Tests |
| L17 | Preview-Bausteine (FilePreviewView / Renderer) | done | 049f696 | 233 | AsyncImage(thumbnailLink) + SF-Fallback + Browser-Open-Button |
| L18 | Preview verdrahten in Files/Angebote/Material | done | be138dc | 233 | DriveTreeRow Popover → FilePreviewView mit Browser-Open-Button |
| L19 | Mail-Anhänge (format=full + downloadAttachment) | done | 98b956d | 237 | GmailAttachment + format=full + extractAttachments rekursiv + 4 Tests |

## Block 6 — Angebote

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L20 | Angebote-Tab 04/05 getrennt + Suche/Sortierung + Preview | done | 11b2326 | 237 | Suchfeld + Datum/Name-Toggle + Preview-Popover (Icon-Klick → FilePreviewView) |
| L21 | Angebote-Sammler GlobalOffersView über alle Projekte | done | (bereits implementiert) | 237 | Projektliste links + OffersTabView rechts, bereits live |

## Block 7 — Menschen/Projekt-Hirn (Signal-Nervensystem)

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L22 | Signal-Monitore: Budget/Deadline/DriveFile echte Emitter | done | f8f27e3 | 238 | CashWidget budgetThresholdCrossed ≥0.9; TasksWidget deadlineNear ≤7 Tage; DriveOfferWatcher driveFileAdded für Nicht-Angebote; +1 GATE-Test |
| L23 | Mail-Vollcache (GmailCacheStore + GmailSyncService) | done | ef09d76 | 243 | GmailCacheStore actor + TTL; SearchGmailTool Cache-Hit vor API; 5 GATE-Tests |
| L24 | Kontakt-Kontext im Assistenten (Airtable Kontakte) | done | b1bed54 | 304 | KundenBrain (Foundation-only Snapshot) + `lookup_kunde`-Tool (read-only Sync-Cache, KEINE Kontaktdetails); Weiche AIRTABLE_KUNDEN_LOOKUP; ConversationEngine.updateRegistry-Seam |

## Block 8 — UI-Politur

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L25 | Favoriten: GRDB projectFavorites + Stern-Button | done | b1bed54 | 309 | FavoritesStore (GRDB v7, SaveState, throws) + Stern-Toggle Galerie/Detail; Widget zeigt echte Favoriten; Cold-Start-Test |
| L26 | Dunkelmodus-Kontrast + Token-Disziplin | done | b17ac81 | 309 | NotesWidget/folderIcon/Hero-Verläufe adaptiv (neue MykColor-Tokens); 11× .system + 24× Color(hex/red) raus; SwiftLint-Token-Regeln scharfgestellt (lokal 0 Verstöße) |
| L27 | Timeline-Tab (Drive/Angebote/Kalender/Audit) | done | 2646769 | 314 | TimelineMerger (rein/testbar) + TimelineTabView + dünner Loader; De-Dup Drive↔Angebot; in ProjectDetailView verdrahtet |
| L28 | Leerzustände & Konsistenz (RecentActivityWidget) | done | 6b1b77e | 319 | RecentActivityWidget echt (DataFlow+Audit, neueste-zuerst) via RecentActivityFeed; Leerzustand über kanonischen WidgetContainer |

## Block 9 — Härtung & Abschluss

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L29 | Test-Decke (Cold-Start + Unit für alle neuen Stores/Tools) | done | 6b1b77e | 320 | KundenBrain/LookupKunde/FavoritesStore(Cold-Start)/TimelineMerger/RecentActivityFeed + RecentActivity-Cold-Start-Integration |
| L30 | Abschluss: EREIGNISPROTOKOLL + Handoff + DMG | done | — | 320 | Ledger/Protokoll/Benutzerhandbuch final; DMG-Pipeline verifiziert (dist/mykilOS-6.dmg, Commit 6b1b77e in Info.plist injiziert) |

## Block 10 — Proof-of-Function-Sprint (Live-Tour-Befunde)

Befunde aus der Live-Durchführung: grüne Tests hatten echte Lücken übersehen
(04/05-Verschachtelung, Schaltzentrale „0 Weichen", Kalender -50, kein Datei-Inhalt-Lesen).
Jeder Schritt schließt eine real beobachtete Funktionslücke.

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| S1 | Schaltzentrale lädt 0 Weichen → Manifest aus Bundle | done | f7048ee | 320 | `loadManifest` Bundle.module zuerst (+ korrigierter #filePath-Fallback); Build-Skript kopiert SPM-Resource-Bundles ins .app (sonst Schaltzentrum/StudioBrain leer im DMG) |
| S2 | `find_offers`-Tool + globaler Projekt-Resolver | done | a1f9f61 | 331 | FindOffersTool (wraps OffersCollector, rekursiv 04/05); ProjectDirectory.resolve (Projektnummer/Substring→driveFolderID); Weiche DRIVE_OFFERS_FIND |
| S3 | Volle Dokumentenvorschau (QuickLook/Voll-PDF) | open | — | — | Braucht M2 (Google Re-Consent, drive.readonly). Noch offen. |
| S4 | Notiz-Funktion im Assistenten | done | 288554a | 328 | AssistantNotesStore (actor, GRDB v8) + create/list/update/delete_note (einzige Schreib-Tools, lokal); Weiche ASSISTANT_NOTES; Kalender-Link-Fix (-50: kein fabrizierter Inline-Link) |
| S5 | Drive-Dateiinhalt lesen (`read_drive_file`) | done | bf101e0 | 334 | DriveFileReader (PDFKit für PDF, Export für Google Docs/Sheets/Slides, utf8 für Text, 6000-Zeichen-Cap) + GoogleDriveClient.exportFile; ReadDriveFileTool; Weiche DRIVE_FILE_READ; +3 Tests |
| S6 | Aufgaben-Store + Assistent-Tools (Memos/Erinnerungen) | done | f2da028 | 342 | AssistantTask (Kit) + AssistantTasksStore (actor, GRDB v9) + create/list/complete/delete_task; optionales Fälligkeitsdatum; Weiche ASSISTANT_TASKS; AppState-Wiring; +8 Tests (inkl. Cold-Start) |
| S7 | Kataloge: umsortierbare Unter-Tabs | done | dcec0ad | 342 | KatalogeView mit 4 Drag-umsortierbaren Tabs (Geräte/Kontakte/Notizen/Aufgaben), Reihenfolge in @AppStorage; Kontakte=People-Suche, Notizen/Aufgaben=lokale Stores mit Inline-Add/Toggle/Delete + sichtbarer Fehlerzeile; in KatalogeContentTabs.swift ausgelagert |
| S8 | Kontakte-Widget im Projektdetail reparieren | done | 2472bd1 | 344 | Ursache: People-API `searchContacts` liefert beim kalten Index **deterministisch leer** (Warmup-Pflicht). Fix: stiller Warmup (leere Query) + Retry-once; Query-Normalisierung (Unterstrich→Space, „Fuckner_Huetter"). +2 Tests (buildWarmupURL, normalizedQuery) |
| S9 | Google Contacts Schreibzugriff (`create_contact`) | done | 4c1b816 | 348 | `GoogleContactsWriting` + `createContact` (People API), `ContactDraft`/`ContactCreateOutcome` (Kit), `create_contact`-Tool (nur Entwurf, kein Auto-Write), `.contactAction`-Block + `ContactActionCard` (Bestätigung→AppState.createContact→Audit `.contactCreated`), Weiche CONTACTS_CREATE. **Live-Test braucht M2 (Google Re-Consent, contacts-Scope).** +4 Tests |

## Block 11 — Memo-Reconciliation (In-App-Assistent, 2026-06-29)

Memo des In-App-Assistenten gegen den echten Code auditiert (Multi-Agent-Workflow, 37 Agenten).
Befund: P1 (Drive/Kontakte) ist code-fertig, nur **M2-blockiert** (Google Re-Consent). Die echten,
ohne M2 baubaren Lücken werden hier geschlossen.

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| S10 | Notizen & Aufgaben pro Projekt | done | 7738bcd | 351 | `projectID` an AssistantNote/AssistantTask + Stores (`scoped(to:)`) + GRDB v10 (additiv, NULL=global); Tools taggen via `_projektID` (AssistantScope), `list_*` scoped aufs Fokus-Projekt + global (`alle=true` = alle); Kataloge zeigt Projekt-Badge. +3 Tests (Scope-Filter, Cold-Start, Projekt-Chat-Tagging) |
| S13 | Airtable-Kontaktverzeichnis (`lookup_kontakt`) | done | 47156e5 | 357 | **Befund: Kunden-Tabelle hat keine Adresse — die Tabelle `Kontakte` (914 Records) schon.** `StudioContact` (Kit), `AirtableClient.mapContacts`, `ContactDirectory` (Snapshot, rang-sortierte Suche), `LookupKontaktTool` (Name/Org/Tel/E-Mail/Adresse/Projekt). AppState synct `Kontakte` einmalig bei Start → Snapshot → Registry. Weiche AIRTABLE_KONTAKTE_LOOKUP. Beantwortet „Adresse Cirnavuk?" **ohne M2/Google**. +6 Tests |
| S12 | Gmail-Suche: Limit erhöhen/parametrisieren | done | 1407e59 | 358 | `SearchGmailTool` `anzahl`-Parameter (Default **25** statt hart 10, Cap 100); Cache-Hit nur genutzt wenn groß genug; Beschreibung nennt Datums-Operatoren (`after:`) für Rückblicke. +1 Test (resultLimit Default/Cap/Floor/Fallback). Hinweis: voller Mailbox-Sync (GmailSyncService) bleibt größerer Folgeschritt |
| S11 | ClickUp projektübergreifend (`list_all_clickup_tasks`) | done | f7d6f1b | 361 | `AllClickUpTasksTool` aggregiert offene Tasks über alle Projekte mit `clickUpListID` (gruppiert, Projekt-Filter, Cap 20 Listen, pro-Liste-Fehler übersprungen); `ProjectClickUpRef` (Kit); AppState baut Listings aus `registry.projects`; mappt auf CLICKUP_TASKS. +3 Tests. **Daten erst voll bei M3 (Listen-IDs in Airtable).** |
| S14 | Gmail-Entwurf anlegen (`create_draft`) | done | (dieser Commit) | 371 | `GoogleGmailWriting.createDraft` (drafts.create, RFC822-MIME + RFC2047-Subject + base64url), `EmailDraft`/`DraftCreateOutcome` (Kit), `create_draft`-Tool (nur Entwurf), `.draftAction`-Block + `DraftActionCard` (Bestätigung→AppState.createDraft→Audit `.draftCreated`), Weiche GMAIL_DRAFT_CREATE, `gmail.compose`-Scope. **VERSENDEN NIE.** Live braucht M2. +5 Tests |
| S15 | Gmail vollständig lesbar (`read_email`) | done | (dieser Commit) | 371 | `GoogleGmailFetching.fetchBody` (Default-Extension wirft, Client implementiert: text/plain bevorzugt, sonst text/html-strip, base64url-decode), `read_email`-Tool (Volltext per Suche+Index), Suche-Hinweis „ganzes Postfach". +5 Tests (buildMIME/encodeHeader/parseBody/stripHTML/Tool) |
