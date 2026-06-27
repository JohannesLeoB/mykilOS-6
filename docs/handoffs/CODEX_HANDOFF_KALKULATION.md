# Codex-Arbeitsanweisung: mykilO$$ Integration — Post-Akt-5, Aufgabe 7

**Datum:** 2026-06-28  
**Repo:** https://github.com/JohannesLeoB/mykilOS-6 (privat)  
**Arbeitsverzeichnis:** Wurzel des Repos (`/`), Branch `claude/musing-sammet-3abd94`  
**Run-Action:** `./script/build_and_run.sh` → baut `.app`-Bundle in `dist/`, startet App  
**Tests:** `swift test` (muss vor jeder Änderung und nach Abschluss grün sein)

---

## Ausgangslage (was bereits erledigt ist)

| Was | Wo | Status |
|---|---|---|
| `KalkulationsEngineProviding`-Protokoll | `Sources/MykilosKit/Domain/KalkulationsEngineProviding.swift` | ✅ |
| `AppState.kalkulationsEngine` nil-Slot | `Sources/MykilosApp/Data/AppState.swift` | ✅ |
| `AirtableClient.createRecord()` + `AirtableCreating` | `Sources/MykilosServices/Airtable/AirtableClient.swift` | ✅ |
| 3 Kalkulations-Tabellen in Airtable live | `Kalkulationen`, `Kalkulations-Positionen`, `Eingehende-Angebote` | ✅ |
| 97 Tests grün, Build sauber | — | ✅ |

**Quell-Codebase mykilO$$** (read-only, nicht verändern):
```
/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilO$$$/ClaudeCode_Final_Handoff_2026-06-26/04_PROJECT/MYKILOSKalkulationslabor/Sources/MYKILOSKalkulationslabor/
```
Die 10 Dateien dort importieren NUR Foundation — sie sind verbatim portierbar.

---

## Aufgabe 1 — UUID → String reconciliation in KalkulationsEngineProviding.swift

**Datei:** `Sources/MykilosKit/Domain/KalkulationsEngineProviding.swift`

**Problem:** `EstimateSession.id` in der mykilO$$-Quelle ist `String` (= `UUID().uuidString`), nicht `UUID`.  
Unser Protokoll hat noch `recordAdjustment(schaetzungsID: UUID, ...)` und `KostenSchaetzung` fehlt `id` und `erstelltAm`.

**Änderungen:**

1. `KostenSchaetzung` um zwei Felder ergänzen:
   ```swift
   public let id: String          // = EstimateSession.id aus mykilO$$
   public let erstelltAm: Date
   ```
   Und im `init(...)` entsprechend aufnehmen.

2. `recordAdjustment` Signatur ändern:
   ```swift
   // vorher:
   func recordAdjustment(schaetzungsID: UUID, faktor: Double, grund: String) async throws
   // nachher:
   func recordAdjustment(schaetzungsID: String, faktor: Double, grund: String) async throws
   ```

`swift build` muss danach grün bleiben (noch keine Konformität, der Slot ist nil).

---

## Aufgabe 2 — `MykilosKalkulationsCore` Target anlegen

### 2a. Package.swift

In `Package.swift` neues Target einfügen (nach `MykilosKit`, vor `MykilosServices`):

```swift
.target(
    name: "MykilosKalkulationsCore",
    dependencies: [],
    path: "Sources/MykilosKalkulationsCore"
),
```

`MykilosServices` bekommt die neue Abhängigkeit:
```swift
.target(
    name: "MykilosServices",
    dependencies: [
        "MykilosKit",
        "MykilosKalkulationsCore",   // ← neu
        .product(name: "GRDB", package: "GRDB.swift"),
    ],
    ...
),
```

### 2b. Verzeichnis anlegen und 10 Dateien verbatim kopieren

```bash
mkdir -p Sources/MykilosKalkulationsCore
```

Dann diese 10 Dateien **exakt** aus der mykilO$$-Quelle kopieren (KEIN Umbenennen, KEIN Ändern):

```
AirtableOffer.swift
BottomUpCost.swift
ComponentResolver.swift
Estimation.swift
LearningModels.swift
MaterialLexicon.swift
Models.swift
Parsing.swift
Review.swift
Version.swift
```

Quelle:
```
/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilO$$$/ClaudeCode_Final_Handoff_2026-06-26/04_PROJECT/MYKILOSKalkulationslabor/Sources/MYKILOSKalkulationslabor/
```

**Wichtig:** Alle 10 Dateien importieren ausschließlich `Foundation`. Kein `import SwiftUI`, kein `import GRDB`. Falls beim Kopieren doch ein anderer Import auftaucht → stopp, melden.

### 2c. Verifizieren

```bash
swift build
```

Muss grün sein. Keine neuen Warnings ignorieren.

---

## Aufgabe 3 — `AirtableSyncService.swift` löschen

**Datei:** `Sources/MykilosServices/Airtable/AirtableSyncService.swift`

Diese Datei hat 3 Regelverstöße:
1. Liest Secrets aus ENV (`AIRTABLE_TOKEN` / `AIRTABLE_API_KEY`) — verboten laut CLAUDE.md
2. Nutzt fremde Airtable-Base `appkPzoEiI5eSMkNK` — nur `appuVMh3KDfKw4OoQ` ist erlaubt
3. Nutzt `DispatchSemaphore` — blockierendes Muster, verboten

```bash
rm Sources/MykilosServices/Airtable/AirtableSyncService.swift
```

Falls irgendetwas diese Datei importiert oder referenziert → auflösen, nicht umgehen.  
`swift build` + `swift test` müssen danach grün bleiben.

---

## Aufgabe 4 — `KalkulationsEngine` Adapter schreiben

**Neue Datei:** `Sources/MykilosServices/Kalkulation/KalkulationsEngine.swift`

Dieses Modul verbindet das reine `MykilosKalkulationsCore`-Brain mit dem `KalkulationsEngineProviding`-Protokoll aus `MykilosKit`. Es darf `MykilosKalkulationsCore` und GRDB importieren.

```swift
import Foundation
import MykilosKit
import MykilosKalkulationsCore

public final class KalkulationsEngine: KalkulationsEngineProviding, @unchecked Sendable {

    private let estimator: EvidenceBasedEstimator   // aus MykilosKalkulationsCore
    private let costEngine: BottomUpCostEngine       // aus MykilosKalkulationsCore

    public init(seedDirectory: URL) {
        // seedDirectory = Application Support / mykilOS / kalkulation /
        // Dort liegen: active_price_anchors.csv, component_price_atoms.csv
        self.estimator = EvidenceBasedEstimator(seedDirectory: seedDirectory)
        self.costEngine = BottomUpCostEngine()
    }

    public func schaetze(projektID: String, freitext: String) async throws -> KostenSchaetzung {
        let request = estimator.parse(freitext)          // Schritt 1: Semantik
        let result  = estimator.estimate(request)         // Schritt 2: Preislogik
        return KostenSchaetzung(
            id: UUID().uuidString,
            projektID: projektID,
            minNetto: result.minNetto,
            maxNetto: result.maxNetto,
            mitteNetto: result.mitteNetto,
            confidence: result.confidence,
            evidenceCount: result.evidences.count,
            kostenboden: costEngine.kostenboden(for: request),
            kostenbodenRatio: result.mitteNetto / max(1, costEngine.kostenboden(for: request)),
            topEvidences: result.evidences.prefix(5).map { ev in
                PriceEvidence(
                    lieferant: ev.lieferant,
                    dokument: ev.sourceFile,
                    seite: ev.page,
                    originalZitat: ev.quote,
                    nettoPreis: ev.netPrice
                )
            },
            erstelltAm: Date()
        )
    }

    public func geraetepreis(suchbegriff: String) async -> Double? {
        // V1: noch nicht implementiert, gibt nil zurück
        return nil
    }

    public func importPDF(driveFileID: String, projektID: String) async throws {
        // V1: noch nicht implementiert
        throw KalkulationsEngineError.notImplemented("PDF Import V1 pending")
    }

    public func recordAdjustment(schaetzungsID: String, faktor: Double, grund: String) async throws {
        // V1: noch nicht implementiert (LearningStore kommt in Aufgabe 5)
        throw KalkulationsEngineError.notImplemented("LearningStore V1 pending")
    }
}

public enum KalkulationsEngineError: Error {
    case notImplemented(String)
}
```

**Achtung:** Die exakten Methoden-/Property-Namen von `EvidenceBasedEstimator` und `EstimateResult` aus dem mykilO$$-Quellcode ablesen. Oben sind die *wahrscheinlichen* Namen — falls sie abweichen, die richtigen aus den kopierten Dateien nehmen.

`swift build` muss danach grün sein.

---

## Aufgabe 5 — LearningStore (eigene `learning.sqlite`)

**Neue Datei:** `Sources/MykilosServices/Kalkulation/KalkulationsLearningStore.swift`

**Zwingend:** Eigene `learning.sqlite` in Application Support, NICHT in die Haupt-GRDB-Migration einhängen.

```swift
import Foundation
import GRDB
import MykilosKit

public struct KalkulationsAdjustment: Codable, FetchableRecord, PersistableRecord {
    public var id: String
    public var schaetzungsID: String
    public var faktor: Double
    public var grund: String
    public var erstelltAm: Date

    public static var databaseTableName: String { "kalkulations_adjustments" }
}

@MainActor
@Observable
public final class KalkulationsLearningStore {

    public private(set) var saveState: SaveState = .idle
    private var db: DatabaseQueue

    public init(appSupportURL: URL) throws {
        let dbURL = appSupportURL
            .appendingPathComponent("mykilOS", isDirectory: true)
            .appendingPathComponent("learning.sqlite")
        try FileManager.default.createDirectory(
            at: dbURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        db = try DatabaseQueue(path: dbURL.path)
        try db.write { db in
            try db.create(table: "kalkulations_adjustments", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("schaetzungsID", .text).notNull()
                t.column("faktor", .double).notNull()
                t.column("grund", .text).notNull()
                t.column("erstelltAm", .datetime).notNull()
            }
        }
    }

    public func append(_ adjustment: KalkulationsAdjustment) throws {
        saveState = .saving
        do {
            try db.write { db in try adjustment.insert(db) }
            saveState = .saved(Date())
        } catch {
            saveState = .failed(error.localizedDescription)
            throw error
        }
    }

    public func all() throws -> [KalkulationsAdjustment] {
        try db.read { db in try KalkulationsAdjustment.fetchAll(db) }
    }
}
```

**Cold-Start-Test ist Pflicht (Merge-Gate):**

**Neue Datei:** `Tests/MykilosServicesTests/Kalkulation/KalkulationsLearningStoreTests.swift`

```swift
import XCTest
@testable import MykilosServices

final class KalkulationsLearningStoreTests: XCTestCase {

    func testAdjustmentUeberlebtNeustart() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let adjustment = KalkulationsAdjustment(
            id: UUID().uuidString,
            schaetzungsID: UUID().uuidString,
            faktor: 1.15,
            grund: "Marktpreiskorrektur Holz 2026",
            erstelltAm: Date()
        )

        // Schreiben
        let store1 = try KalkulationsLearningStore(appSupportURL: tmp)
        try store1.append(adjustment)

        // Neue Instanz → lesen
        let store2 = try KalkulationsLearningStore(appSupportURL: tmp)
        let loaded = try store2.all()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].id, adjustment.id)
        XCTAssertEqual(loaded[0].faktor, adjustment.faktor)
        XCTAssertEqual(loaded[0].grund, adjustment.grund)
    }
}
```

`swift test` muss grün sein.

---

## Aufgabe 6 — AppState.bootstrap() verdrahten

**Datei:** `Sources/MykilosApp/Data/AppState.swift`

Im `bootstrap()`-Aufruf (nach dem lokalen Cache-Load) die Engine instanziieren:

```swift
// Kalkulations-Engine starten (nur wenn Seed-Daten vorhanden)
let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
let seedDir = appSupport.appendingPathComponent("mykilOS/kalkulation", isDirectory: true)
if FileManager.default.fileExists(atPath: seedDir.path) {
    kalkulationsEngine = KalkulationsEngine(seedDirectory: seedDir)
}
```

Für V1 ist `kalkulationsEngine` nil wenn keine CSVs vorhanden — das ist korrekt, die UI-Slots prüfen `!= nil`.

---

## Aufgabe 7 — Handoff + CLAUDE.md aktualisieren

1. Dieses Dokument als erledigt markieren in `CLAUDE.md`:
   ```
   | Post-Akt-5, Aufgabe 7 | 🚧 | mykilO$$ Vollintegration: Core-Target live, LearningStore, Engine-Adapter |
   ```
   (oder `✅` wenn alles erledigt)

2. Neuen Handoff schreiben: `docs/handoffs/HANDOFF_POST_AKT5_7.md`  
   — was entstanden ist, welche Tests neu sind, was V1 bewusst nicht macht (PDF-Import, LearningStore → Engine verdrahten), was der nächste Schritt ist.

3. Commit mit sprechendem Message:
   ```
   feat: add MykilosKalkulationsCore target + KalkulationsEngine adapter (Post-Akt-5, Aufgabe 7)
   ```

---

## Absolut verboten (nicht verhandelbar)

| Verbot | Grund |
|---|---|
| `try?` bei Schreibvorgängen ohne begründeten Kommentar | Persistenzregel |
| `import GRDB` in `MykilosKalkulationsCore` | Foundation-only Target |
| `import SwiftUI` in `MykilosServices` | Architekturgrenze |
| Secrets in Code / ENV / Logs | Keychain-Regel |
| Schreiben in die originale mykilO$$-Basis `appkPzoEiI5eSMkNK` | Fremde Base |
| Schreiben in Google Drive | Read-only |
| Sevdesk berühren | NO-GO absolut |
| `AirtableSyncService.swift` wiederherstellen | 3 Regelverstöße |
| Corpus-CSVs im Repo bundlen | Nur in Application Support |
| Cold-Start-Test für LearningStore weglassen | Merge-Gate |

---

## Architektur-Kurzreferenz

```
MykilosKit          → kein SwiftUI, kein GRDB, kein Netzwerk
MykilosKalkulationsCore → nur Foundation, kein GRDB, verbatim aus mykilO$$
MykilosDesign       → Tokens, Farben, Typografie
MykilosServices     → GRDB, Keychain, Netzwerk; kein SwiftUI
MykilosWidgets      → SwiftUI; kein GRDB direkt
MykilosApp          → SwiftUI-Shell, AppState, bootstrap
```

Signale = Vorschläge. Schreiben nur über Action-Card → Bestätigung → AuditEntry.  
Jedes neue persistierbare Feature braucht Cold-Start-Test.

---

## Falls etwas unklar ist

- `CLAUDE.md` im Repo-Root ist das vollständige Projektgedächtnis
- `docs/handoffs/HANDOFF_POST_AKT5_7_START.md` — Vorbereitungs-Handoff dieser Session
- `docs/KALKULATION_INTEGRATION.md` — Gesamtplan mit allen Tabellen-IDs
- `docs/PARTNER_APP_SCHEMA.md` — vollständiges Airtable-Schema
- mykilO$$-Quelldaten: `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilO$$$/ClaudeCode_Final_Handoff_2026-06-26/04_PROJECT/MYKILOSKalkulationslabor/`
