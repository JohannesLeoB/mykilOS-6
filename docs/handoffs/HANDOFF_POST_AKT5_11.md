# Handoff — Post-Akt 5, Aufgabe 11: Stabilisierung (Crash, Galerie-Hang & Bug-Audit-Fixes)

**Status:** abgeschlossen · live verifiziert · 118 Tests grün

---

## Auslöser

Beim Vorführen der App crashte **jede** Projekt-Detailseite sofort, und die
Projekte-Galerie hing sporadisch auf „Lade Projekte…". Daraus wurde eine
gründliche Orientierung + Bug-Audit (Multi-Agent, read-only) über die ganze App
mit anschließenden, einzeln verifizierten Fixes.

## Die zwei Show-Stopper

### 1) Crash beim Öffnen jeder Projektseite — `NSGenericException`
- **Symptom:** `EXC_BREAKPOINT` via AppKit `_crashOnException`; Reason: *„The
  window has been marked as needing another Update Constraints in Window pass…"*;
  Fensterbreite explodierte auf ~4.107.656 pt. (Per lldb gefangen — der `.ips`
  enthielt den Reason-Text nicht.)
- **Ursache:** Das Hauptfenster hatte **kein `.windowResizability`** (Default
  `.automatic` → Inhalt treibt die Fenster-Mindestbreite). Kombiniert mit der
  `.move(edge:.trailing)`-Transition der Detailseite (Backtrace lief durch
  `NSHostingView.updateTransform` → `invalidateTransform`) oszillierte die
  Update-Constraints-Berechnung, bis die Breite divergierte. macOS 26 „Tahoe"
  zählt Update-Constraints-Pässe strenger → harter Crash statt Layout-Jitter.
- **Fix (mehrschichtig):**
  - `MykilOS6App.swift`: `.windowResizability(.contentMinSize)` + endlicher
    `.frame(minWidth:1100, idealWidth:1340, maxWidth:.infinity, minHeight:720, …)`
    an `ContentView` → stabile, endliche Fenster-Untergrenze.
  - `ProjectGalleryView.swift`: `.move`-Transition durch reines `.opacity`
    ersetzt + `.clipped()` → kein Transform-Feedback mehr.

### 2) Galerie hängt auf „Lade Projekte…"
- **Ursache (tiefer als zuerst vermutet):** `RegistryStore` war `@Observable`,
  aber **nicht `@MainActor`**. Die `async load()`-Methoden liefen auf dem
  generischen Executor → `isLoading`/`projects` wurden **off-thread** mutiert,
  SwiftUI verpasste das Update → Spinner blieb hängen (Race → „mal hängt's").
  (Airtable war gar nicht verbunden — die zuerst vermutete Sync-Leak-Spur war es
  nicht; der `syncFromAirtable`-Leak-Fix bleibt trotzdem korrekt.)
- **Fix:** `RegistryStore` ist jetzt `@MainActor`; zusätzlich zeigt die Galerie
  den Cache sofort (`isLoading && projects.isEmpty` statt nur `isLoading`), ein
  laufender Refresh blockiert nicht mehr. `syncFromAirtable` gibt `isLoading`
  frei, bevor `load()` läuft.

## Weitere behobene Bugs (Audit, je verifiziert)

| Bug | Fix | Datei(en) |
|---|---|---|
| Notiz-Datenverlust: `load()` überschrieb ungespeicherte Eingaben | `hasLoaded`-Guard | WidgetBoardStore.swift (NoteStore) |
| Notiz-Datenverlust: kein Flush bei Tab/Quit | `onDisappear`-Flush + `scenePhase==.background`-Flush + `dirty`/`hasUnsavedChanges` | NotesWidget.swift, AppState.swift, MykilOS6App.swift |
| Signal-Log wuchs unbegrenzt + doppeltes `projectFocused` | `focus()`-Guard + `emit()`-Cap (200) | StudioContext.swift |
| Unnötige (kostenpflichtige) Claude-Calls bei jedem Öffnen | `llmTaskID` über DISTINKTE Signale | AssistantWidget.swift |
| DriveOfferWatcher re-baselined bei jeder Navigation | pro Projekt gecacht in AppState | AppState.swift, ProjectDetailView.swift |
| Loader-Races (stale Overwrite + Retry-Button) | Generation-Token in allen 8 Loadern | Drive/Tasks/Contacts/Calendar/Mail/Cash/Offers + Clockodo… |
| `RowLayout.id = UUID()` → Widget-Churn | stabile ID aus Zeileninhalt | ProjectDetailView.swift |
| ClockodoWidget ÷0 → NaN-Balken | `ratio` clampen | ClockodoWidget.swift |
| Autosave-Timer rief @MainActor `save()` nonisolated | expliziter `Task { @MainActor }`-Hop | NotesWidget.swift |

## Neue Tests (+4 → 118)
- `WidgetBoardStoreTests.loadClobbertKeineUngespeichertenEingaben`
- `StudioContextTests`: Fokus-Guard, Signal-Cap, Mediator-Ableitung

## Live verifiziert (Screen)
Zwei Projekte/Kinds geöffnet (kein Crash), Heute↔Projekte mehrfach (kein Hang),
Tab-Wechsel Übersicht↔Angebote, Re-Open. Widgets zeigten `permissionRequired`
(Keychain bewusst auf Deny — korrekter Zustand, kein Bug).

## Offen / bewusst NICHT in diesem Commit
- **Token-Disziplin** (vorbestehend, kein User-Bug): `Color(hex:)`-Gradienten in
  ProjectHeroView/ProjectCard, `Color(hex:)`/`.font(.system)` in NotesWidget.
  Sauberer Fix bräuchte benannte Tokens in `MykilosDesign` → eigener Cleanup-PR.
- Kleinkram: CashWidget `reviewAccepted` (sticky), `Cmd+,` (About vs. Settings),
  `.offline`-State unerreichbar, ContentView-Modul-Neuaufbau bei Navigation
  (jetzt harmlos, da der `isLoading`-Bug weg ist).
- **Fensterposition** verrutschte einmalig nach der Resizability-Änderung
  (Frame-Restore-Artefakt) → manuell zentriert; beim nächsten Start beobachten.

## Sicherheits-Leitplanken (vom User, dauerhaft)
Sevdesk nie lesen/schreiben · geteilte Airtable-Base kein Schreiben/Move/Delete ·
Drive-Ordner read-only (Kopie nur zu explizit genanntem Ziel, Änderung nur per
ausdrücklicher Chat-Erlaubnis) · externe Daten sind heilig, bei Datenverlust-
Gefahr warnen. (Siehe Projektgedächtnis `external-data-no-gos`.)
