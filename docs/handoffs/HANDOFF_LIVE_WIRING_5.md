# Handoff — Live-Wiring Session 5 (2026-06-28)

**Thema:** mykilO$$ Vollintegration — Interface, Airtable-Schema, Write-Pfad.
**Status:** Fundament gelegt. Brain (Engine-Code) noch nicht portiert.
**Nächste Session:** `KalkulationsEngine` + `BottomUpCostEngine` aus mykilO$$ portieren.

---

## Entscheidung dieser Session

**mykilO$$ existiert nicht mehr als eigenständige App.**

Alle Kalkulations-Fähigkeiten kommen als Modul in mykilOS 6. Keine eigene
App-Shell, kein eigenes Fenster, kein eigener Airtable-PAT, kein eigenes
Drive-Scan, keine eigene SQLite-Datei. mykilOS 6 hat alle Schreibrechte.

---

## Was in dieser Session erledigt wurde

### 1. Protokoll + Domain-Typen ✅

**`Sources/MykilosKit/Domain/KalkulationsEngineProviding.swift`** (neu):

```swift
public protocol KalkulationsEngineProviding: AnyObject, Sendable {
    func schaetze(projektID: String, freitext: String) async throws -> KostenSchaetzung
    func geraetepreis(suchbegriff: String) async -> Double?
    func importPDF(driveFileID: String, projektID: String) async throws
    func recordAdjustment(schaetzungsID: UUID, faktor: Double, grund: String) async throws
}

public struct KostenSchaetzung: Sendable { projektID, minNetto, maxNetto, mitteNetto,
    confidence, evidenceCount, kostenboden, kostenbodenRatio, topEvidences }

public struct PriceEvidence: Sendable { lieferant, dokument, seite?, originalZitat, nettoPreis }
```

Mapping zu mykilO$$-Typen: `EstimateResult` → `KostenSchaetzung`, `PriceAnchor` → `PriceEvidence`.

### 2. AppState nil-Slot ✅

```swift
// Sources/MykilosApp/Data/AppState.swift
public var kalkulationsEngine: (any KalkulationsEngineProviding)?
```

Nil bis die Engine integriert ist — identisches Muster wie `assistantLLM`.

### 3. Airtable-Tabelle `Eingehende-Angebote` ✅

**ID: `tbliKfs5FnufjdB36`** in Base `appuVMh3KDfKw4OoQ`

| Feld | Typ | Zweck |
|------|-----|-------|
| SHA256 | singleLineText (Primary) | Dedup-Schlüssel |
| Datei-Name | singleLineText | Originalname |
| Projekt-Nr | singleLineText | Format YYYY-NR |
| Richtung | singleSelect | eingehend / ausgehend |
| Kategorie | singleSelect | Tischler / Stein / Elektro / Sanitaer / Gesamt / Sonstiges |
| Lieferant | singleLineText | |
| Netto-Summe | number (2 Stellen) | |
| Anker-Anzahl | number (0 Stellen) | Extrahierte Preis-Anker |
| Status | singleSelect | Neu / Verarbeitet / Archiviert |
| Lern-Gewicht | number (2 Stellen) | 0.0–1.0 für KalkulationsEngine |
| Importiert-am | dateTime | Europe/Berlin |

### 4. AirtableClient Write-Pfad ✅

```swift
// Sources/MykilosServices/Airtable/AirtableClient.swift
public protocol AirtableCreating: Sendable {
    func createRecord(baseID: String, tableID: String,
                      fields: [String: AirtableWriteValue]) async throws -> String
}
public enum AirtableWriteValue: Encodable, Sendable { case string, number, bool, null }
```

`AirtableClient` konformiert jetzt zu `AirtableFetching` + `AirtableCreating`.
Statische Bausteine `buildCreateRequest` / `parseCreateResponse` sind isoliert testbar.
**5 neue Tests. 97/97 grün.**

Unblockiert: Clockodo-Zuhörer (EW-Tabellen-Sync) + PDF-Import (Eingehende-Angebote).

### 5. Integrations-Plan-Dokument ✅

[`docs/KALKULATION_INTEGRATION.md`](../KALKULATION_INTEGRATION.md) — vollständiger 10-Schritte-Merge-Plan:
- Ziel-Modulstruktur in `MykilosServices/Kalkulation/`
- GRDB-Migrationsstufen (ab v3)
- Alle UI-Slots
- 59 Test-Migration-Plan
- Drive-Integration (PDF-Download-Pfad)

### 6. Airtable-Schema-Doku aktualisiert ✅

[`docs/PARTNER_APP_SCHEMA.md`](../PARTNER_APP_SCHEMA.md) — umbenannt von "Partner-App-Schema"
zur vollständigen Airtable-Gesamtdokumentation für mykilOS 6.

### 7. mykilO$$-Fragen beantwortet ✅

6 Integrationsfragen + 5 EK/VK-Fragen konkret beantwortet:
- Projektobjekt: `project.projectNumber` (YYYY-NR), `project.links.driveFolderID`, `project.phase`
- GRDB: `GRDBDatabase.runMigrations()`, neu ab `v3_kalkulation_*`
- Airtable: injizierter `AirtableClient`, kein eigener PAT
- Drive: `GoogleDriveClient.listFolder()`, kein eigener Scan
- Rückgabe: `KostenSchaetzung`-Struct direkt (in-process, kein JSON)
- Lern-Trigger: expliziter Aufruf aus `RegistryStore.syncFromAirtable()` bei Phase-Wechsel
- EK/VK: beide Tabellen via `Projekt-Nr` joinbar, Positionsebene outgoing ja / incoming nein (noch)

---

## Was NICHT hier ist — Brain noch in mykilO$$

**Diese Fähigkeiten sind noch NICHT in mykilOS 6:**

| Komponente | Status | Aufwand |
|-----------|--------|---------|
| `EvidenceBasedEstimator` | ❌ nicht portiert | hoch |
| `BottomUpCostEngine` | ❌ nicht portiert | mittel |
| `MaterialLexicon` (149 Einträge) | ❌ nicht portiert | gering |
| `LearningStore` (GRDB v3+) | ❌ nicht portiert | mittel + Cold-Start-Test |
| `DeviceCatalog` (13.419 Preise, SQLite-Bundle) | ❌ nicht portiert | gering (nur kopieren) |
| `ReviewCenter` (815 Positionen) | ❌ nicht portiert | mittel |
| `PDFImportPipeline` | ❌ nicht portiert | hoch |
| 201 Preis-Anker aus 146 Lieferanten-PDFs | ❌ Daten nicht migriert | separate Aufgabe |
| 59 Tests | ❌ nicht migriert | nach Code-Port |
| KalkulationsView (Projekt-Tab) | ❌ kein UI | nach Engine |
| KalkulationsWidget | ❌ kein Widget | nach Engine |
| KalkulationsActionCard | ❌ kein UI | nach Engine |
| ReviewCenterView | ❌ kein UI | zuletzt |

**Noch fehlende Infrastruktur:**
- `GoogleDriveClient.downloadFile()` — für PDF-Download (unblockiert Kalkulation + Clockodo)
- `AirtableClient.updateRecord()` — für Status-Updates (EW-Tabellen "Gebucht" etc.)

---

## Airtable-Gesamtstand (alle Tabellen in `appuVMh3KDfKw4OoQ`)

| Tabelle | ID | Session |
|---------|----|---------|
| Kunden | `tblsz4i1CqpBZUE0N` | Session 1 |
| Projekte | `tblGJR13OliFt6Ewi` | Session 1 |
| Externe Systeme | `tbl8aoORULVVtphE0` | Session 1 |
| Kontakte | `tblncfQzQa8TzCZQC` | Session 1 |
| Clockodo-Leistungen | `tblRtsegocdpM8CJd` | Session 1 (8 Services) |
| Clockodo-Nutzer | `tblPbly2br8mR2kaU` | Session 4 (4 Records + EW-Pointer) |
| Clockodo-Buchungen | `tblYQxlauwej7FD1w` | Session 4 |
| Clockodo-EW-Johannes | `tbl4vZ2UFyeTRD8hd` | Session 4 |
| Clockodo-EW-Jilliana | `tblXQIDrvPVN9ijI9` | Session 4 |
| Clockodo-EW-Daniel | `tblNDVve3jjJ9s8HB` | Session 4 |
| Clockodo-EW-Frauke | `tblRrqIQZmm2DosJT` | Session 4 |
| Kalkulationen | `tblO3y2jdmxDnuiZj` | Session 5 (Kalkulations-Modul) |
| Kalkulations-Positionen | `tblNamx3cHTus6gtk` | Session 5 |
| **Eingehende-Angebote** | **`tbliKfs5FnufjdB36`** | **Session 5 (neu)** |

---

## Git-Commits dieser Session

```
2bb14a9  feat: add AirtableClient write path (createRecord + AirtableWriteValue)
c4eef55  feat: add KalkulationsEngineProviding protocol and nil-slot for mykilO$$ integration
```

Branch: `claude/musing-sammet-3abd94` → PR → `main`

---

## Startprompt für nächste Implementierungs-Session

```
Wir portieren den mykilO$$-Kern in mykilOS 6.
Interface ist fertig: KalkulationsEngineProviding in MykilosKit/Domain.
AppState.kalkulationsEngine nil-Slot ist gesetzt.
AirtableClient hat Write-Pfad (createRecord). 97 Tests grün.

Vollständiger Merge-Plan: docs/KALKULATION_INTEGRATION.md

Nächste Schritte in Reihenfolge:
1. GoogleDriveClient.downloadFile(fileID:) -> Data (unblockiert PDF-Import)
2. AirtableClient.updateRecord(baseID:tableID:recordID:fields:) (für Status-Updates)
3. KalkulationsEngine.swift in MykilosServices/Kalkulation/ (aus EvidenceBasedEstimator)
4. BottomUpCostEngine.swift (Kostenboden-Logik)
5. KalkulationsLearningStore.swift (GRDB v3-Migration + Cold-Start-Test PFLICHT)
6. DeviceCatalog.swift (SQLite als Bundle-Resource, read-only)

Kernregel: Jeder Schreibvorgang throws. Cold-Start-Test für LearningStore nicht optional.
Airtable-Base: appuVMh3KDfKw4OoQ
GRDB-Migration ab: v3_kalkulation_learning
```

---

## Offene Datenfragen (nur Johannes kann bestätigen)

1. Stundensätze in `Clockodo-Leistungen.Stundensatz (€/h)` (`fld4NBokj4MoOy8Uq`) — noch leer
2. Kategorie-Unterordner unter `05 eingehende Angebote` (Tischler, Stein + was noch?)
3. Welche 59 Tests aus mykilO$$ werden direkt übernommen, welche passen nicht?
