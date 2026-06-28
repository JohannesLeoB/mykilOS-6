# Handoff — Post-Akt 5, Aufgabe 1: Auto-Sync bei App-Start

**Status:** abgeschlossen

---

## Was gebaut wurde

`AppState.bootstrap()` startet nach dem lokalen Laden von Home-Board, Notizen,
Demo-Seed und Registry-Cache automatisch den bestehenden Airtable-Sync, wenn
`AirtableAuthService` bereits verbunden ist.

Die Reihenfolge bleibt bewusst:

1. lokale DB-Stores laden
2. Demo-Seed bei leerer Registry
3. lokalen Registry-Cache laden
4. gespeicherte Airtable-Credentials aus der Keychain lesen
5. `RegistryStore.syncFromAirtable(baseID:auth:)` ausführen

Damit ist beim App-Start sofort ein lokaler Zustand sichtbar; Airtable aktualisiert
anschließend den Cache.

## Geänderte Dateien

| Datei | Was |
|---|---|
| `Sources/MykilosApp/Data/AppState.swift` | Auto-Sync nach lokalem Bootstrap verdrahtet |
| `CLAUDE.md` | Status und offene Punkte aktualisiert |

## Tests

Keine neuen Tests. Die Sync-Logik selbst ist bereits über
`RegistryTests.airtableSyncSchreibtInCache()` abgedeckt; diese Session verdrahtet
nur den App-Start-Hook.

Verifiziert:

- `swift test` — 80 Tests grün
- `swift build` — erfolgreich

## Bewusst offen

- Der echte Startup-Sync mit realen Airtable-Credentials muss in der Beta-App
  manuell geprüft werden, weil automatisierte Tests kein echtes Keychain/Netzwerk
  verwenden.
- Bestehende Compiler-Warnungen aus vorherigen Sessions wurden nicht angefasst.

## Nächster Schritt

Post-Akt 5, Aufgabe 2: Audit-Store verdrahten und bestätigte Assistant-Aktionen
persistieren.
