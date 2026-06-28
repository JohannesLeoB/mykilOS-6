# Erfahrungsträger: mykilO$$$ — Ursprung der Kalkulations-Intelligenz

**Session:** mykilO$$$ (eigenständiges Projekt)  
**Rolle:** Erfahrungsträger, Wissensquelle, Charter-Mitgründer  
**Status:** Abgeschlossen — Wissen portiert nach mykilOS 6

---

## Was mykilO$$$ war

Das Vorgänger-System der Kalkulations-Engine. Ein eigenständiges Swift-Projekt mit lokaler SQLite-Datenbank, das Schätz-Logik für Tischlerarbeiten entwickelt hat.

---

## Was mykilO$$$ eingebracht hat

### Technisches Erbe (portiert in mykilOS 6, Schritte 1–8)
- `EvidenceBasedEstimator` — Schätzung aus historischen Preisankern
- `BottomUpCost` — Positions-für-Positions-Kalkulation
- `LearningStore` mit GRDB-Lernschicht
- `EstimateRequestParser` — Freitext → strukturierte Anfrage
- `CalibrationFactorCandidate` + `ActiveCalibrationFactor` — Lern-Loop
- `DeviceCatalog` — 13.419 Gerätepositionen mit Marktpreisen (als CSV in Application Support)

### Datenbasis (NICHT portiert — bleibt lokal)
- **3.383 Preis-Beobachtungen** — lokale SQLite, kein Airtable
- **61 EstimateSessions** — historische Kalkulationen
- Entscheidung: "Rohdaten für ML-Pipeline gehören nicht in Airtable. SQLite ist direkt und schnell."

### Charter-Beiträge
- Statut 8: Daten-Transparenz — jede Session benennt explizit welche Daten sie berührt
- Statut 9: Handoff im selben Commit — kein Nachgedanke
- Statut 14: Architektur-Stopp-Regel — nicht weiterbauen auf falschen Fundamenten

---

## Kerninsight für künftige Sessions

Die KalkulationsEngine schätzt **Tischlerarbeiten** aus Material + Erfahrungsankern. Niemals Studio-Stundensätze (KO-DE+H, PRMG) einmischen. Das sind zwei völlig getrennte Welten. mykilO$$$ hatte diese Trennung immer klar.

### Was noch nicht portiert ist
- `importPDF` — Drive-Download + PDF-Textextraktion + Destillationspipeline. Eigene Spur, mehrere Sessions.
- Die 3.383 echten Preis-Beobachtungen aus mykilO$$$'s SQLite → noch nicht in mykilOS 6's `learning.sqlite`
- Die V2-Swift-Destillationspipeline die das überträgt: geplant, nicht gebaut

---

## Airtable-Kontext

Mastermind-Base hat Tabellen `Kalkulationen`, `Kalkulations-Positionen`, `Eingehende-Angebote` — diese sind OUTPUT-Sinks für bestätigte Kalkulationen. Der Brain liest NICHT aus Airtable für Schätzungen.
