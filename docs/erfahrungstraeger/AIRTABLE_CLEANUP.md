# Erfahrungsträger: Airtable Cleanup — Datenstruktur-Ordnung

**Session:** mykilOS 6 Airtable structure cleanup (trusting-jemison-f105ae)  
**Rolle:** Erfahrungsträger, stiller Zeuge  
**Status:** Abgeschlossen

---

## Was Airtable Cleanup geleistet hat

Diese Session hat die Airtable-Struktur für mykilOS 6 geordnet und klärende Entscheidungen getroffen.

### Entscheidungen
- **1 Base bleibt operativ:** Mastermind `appuVMh3KDfKw4OoQ` — einzige aktive Base
- **Stillgelegt:** `appkPzoEiI5eSMkNK` — kein Lesen, kein Schreiben, nie
- **Zulieferpreise Schätzung** (MYKILOS SCHATZ Workspace): alter mykilO$$$-Tryout, für mykilOS 6 irrelevant

### Airtable-Struktur in Mastermind (bekannt)
- `Kalkulationen` — OUTPUT für bestätigte Schätzungen
- `Kalkulations-Positionen` — Positionen zu Kalkulationen
- `Eingehende-Angebote` — eingehende Angebote
- `Clockodo-Leistungen` (`tblRtsegocdpM8CJd`) — Leistungsarten mit Stundensatz
- `Kontakte` — 914 Einträge (891 CSV + 23 Gmail)
- Clockodo EW-Tabellen (4 persönliche Tabellen)

---

## Wichtigstes Wissen

### Was Airtable IST und was NICHT
- Airtable Mastermind = System of Record für Projektstruktur, Kundendaten, Kalkulationen (Output)
- Airtable = KEIN Source für KalkulationsEngine-Input (das ist local GRDB + CSV)
- Airtable `Preis-Beobachtungen` = Archiv, kein operativer Datenpfad

### Neu entdeckt (2026-06-28, nach Airtable Cleanup)
- `appdxTeT6bhSBmwx5` — Artikel- & Einkaufsdatenbank (13.419 Studio-Produkte) — READ ONLY Tabu
