# Handoff: Post-Akt-5 Aufgabe 7 — Kalkulations-Integration Start

**Session:** musing-sammet-3abd94  
**Stand:** 2026-06-28  
**Status:** Vorbereitung abgeschlossen, Code-Port noch ausstehend

---

## Was diese Session abgeschlossen hat

- `KalkulationsEngineProviding`-Protokoll + Typen in `MykilosKit/Domain/KalkulationsEngineProviding.swift` ✅
- `AppState.kalkulationsEngine: (any KalkulationsEngineProviding)?` nil-Slot ✅
- `AirtableClient.createRecord()` + `AirtableCreating`-Protokoll + 5 Tests ✅
- `AirtableSyncService.swift` wurde als zu löschen identifiziert (ENV-Secrets, fremde Base, DispatchSemaphore)
- Airtable-Tabellen `Kalkulationen`, `Kalkulations-Positionen`, `Eingehende-Angebote` live ✅
- Destillation V2 als Swift-Pipeline entschieden ✅
- 97/97 Tests grün, Build sauber ✅

## Was die nächste Session tun muss (Port-Reihenfolge)

### Schritt 1 — SOFORT: UUID → String reconciliation
In `Sources/MykilosKit/Domain/KalkulationsEngineProviding.swift`:
- `KostenSchaetzung.id` fehlt noch (hinzufügen als `public let id: String`)
- `KostenSchaetzung.erstelltAm: Date` fehlt noch (hinzufügen)
- `recordAdjustment(schaetzungsID: UUID, ...)` → `schaetzungsID: String`

Grund: `EstimateSession.id` in mykilO$ ist `String` (= UUID().uuidString), nicht `UUID`.

### Schritt 2 — `MykilosKalkulationsCore` Target anlegen
In `Package.swift` neues Foundation-only Target:
```swift
.target(
    name: "MykilosKalkulationsCore",
    dependencies: [],
    path: "Sources/MykilosKalkulationsCore"
)
```
Dann `MykilosServices` darauf abhängig machen.

10 Quelldateien verbatim aus:
`/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilO$$$/ClaudeCode_Final_Handoff_2026-06-26/04_PROJECT/MYKILOSKalkulationslabor/Sources/MYKILOSKalkulationslabor/`

- AirtableOffer.swift
- BottomUpCost.swift
- ComponentResolver.swift
- Estimation.swift
- LearningModels.swift
- MaterialLexicon.swift
- Models.swift
- Parsing.swift
- Review.swift
- Version.swift

Alle importieren NUR Foundation. Verbatim kopieren, KEIN Umbenennen.

### Schritt 3 — AirtableSyncService löschen
`Sources/MykilosServices/Airtable/AirtableSyncService.swift` löschen.
3 Regelverstöße: ENV-Secrets, fremde Base `appkPzoEiI5eSMkNK`, DispatchSemaphore.

### Schritt 4 — `swift build` grün verifizieren

### Schritt 5 — `KalkulationsEngine: KalkulationsEngineProviding` Adapter
In `Sources/MykilosServices/Kalkulation/KalkulationsEngine.swift`:
- Importiert `MykilosKalkulationsCore` + GRDB
- `schaetze(projektID:freitext:)` → `parse(_:)` → `estimate(_:)` → `KostenSchaetzung`
- `id` = `UUID().uuidString` (String)

### Schritt 6 — LearningStore GRDB (eigene learning.sqlite)
`Sources/MykilosServices/Kalkulation/KalkulationsLearningStore.swift`
- Eigene `learning.sqlite` in `Application Support/mykilOS/learning.sqlite`
- NICHT in Haupt-GRDB-Migration einhängen
- Cold-Start-Test ist Merge-Gate (ABSOLUTES PROJEKTGESETZ)

### Schritt 7 — AppState.bootstrap() verdrahten
`AppState.kalkulationsEngine = KalkulationsEngine(...)` beim Start setzen.

---

## Kritische Architektur-Entscheidungen (nicht ändern)

| Entscheidung | Grund |
|---|---|
| `MykilosKalkulationsCore` ist eigenes Target | Importiert NUR Foundation; `MykilosServices` importiert GRDB → darf nicht gemischt werden |
| LearningStore = eigene `learning.sqlite` | Nicht in Haupt-GRDB-Migration einhängen → kein Overloading |
| `AirtableSyncService` löschen, nicht refactorn | 3 Regelverstöße, kein Rettungsweg |
| Einstieg zweistufig: `parse()` dann `estimate()` | `estimate()` nimmt KEINEN Freitext |
| `KostenSchaetzung.id: String` (nicht UUID) | `EstimateSession.id` in Quelle ist String |
| Corpus NICHT im Repo/Bundle | Nur in Application Support laden (3.383 Preis-Beobachtungen) |
| Sevdesk: NO-GO | Nie lesen oder schreiben |
| Originale Airtable-Base `appkPzoEiI5eSMkNK`: NO-GO | Nur Mastermind `appuVMh3KDfKw4OoQ` |
| Drive: read-only | Nur lesen, nie schreiben/verschieben |

---

## Quell-Codebase mykilO$
`/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilO$$$/ClaudeCode_Final_Handoff_2026-06-26/04_PROJECT/MYKILOSKalkulationslabor`

mykilO$-Session (für Rückfragen): `local_ea915727-6e38-408f-a528-b8a3ad2384f3`

---

## Aktueller Build-Stand

- Branch: `claude/musing-sammet-3abd94`
- Tests: 97/97 grün
- Build: sauber
- PR: https://github.com/JohannesLeoB/mykilOS-6/pull/1
