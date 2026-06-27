# Airtable-Schema — mykilOS 6 (Kalkulation vollständig integriert)

**Stand:** 2026-06-28 — AKTUALISIERT nach Vollintegrations-Entscheidung
**Base:** `appuVMh3KDfKw4OoQ` (mykilOS Mastermind)

> **Wichtig:** mykilO$$ existiert nicht mehr als eigenständige App.
> Alle Kalkulationsfähigkeiten sind in mykilOS 6 integriert.
> mykilOS 6 hat alle Schreibrechte über alle Tabellen.
> Dieses Dokument war vormals das "Partner-App-Schema" — es ist jetzt
> die Airtable-Gesamtdokumentation für mykilOS 6.

Vollständiger Integrationsplan: [KALKULATION_INTEGRATION.md](KALKULATION_INTEGRATION.md)

---

## Ownership-Modell (alle Tabellen: mykilOS 6)

| Tabelle | Schreibt | Liest | Bemerkung |
|---------|----------|-------|-----------|
| `Kunden` | mykilOS 6 | mykilOS 6 | Stammdaten |
| `Projekte` | mykilOS 6 | mykilOS 6 | inkl. Drive-Ordner-ID |
| `Kontakte` | mykilOS 6 | mykilOS 6 | 914 Records |
| `Externe Systeme` | mykilOS 6 | mykilOS 6 | |
| `Clockodo-Leistungen` | mykilOS 6 | mykilOS 6 | Stundensätze, 8 Services |
| `Clockodo-Nutzer` | mykilOS 6 | mykilOS 6 | User-Scoping, EW-Table-IDs |
| `Clockodo-Buchungen` | mykilOS 6 | mykilOS 6 | Master-Audit-Log |
| `Clockodo-EW-*` | mykilOS 6 (je User) | — | Private Draft-Tabellen, user-scoped |
| `Kalkulationen` | mykilOS 6 | mykilOS 6 | integriertes Kalk.-Modul schreibt |
| `Kalkulations-Positionen` | mykilOS 6 | mykilOS 6 | linked zu Kalkulationen |
| `Eingehende-Angebote` | mykilOS 6 | mykilOS 6 | PDF-Corpus, SHA256-dedup |

---

## Tabellen-IDs (alle in Base `appuVMh3KDfKw4OoQ`)

### Kern-Tabellen

| Tabelle | ID | Primärfeld |
|---------|----|-----------|
| Kunden | `tblsz4i1CqpBZUE0N` | Name |
| Projekte | `tblGJR13OliFt6Ewi` | Projektnummer |
| Externe Systeme | `tbl8aoORULVVtphE0` | System |
| Kontakte | `tblncfQzQa8TzCZQC` | Name |

### Clockodo-Tabellen

| Tabelle | ID | Primärfeld |
|---------|----|-----------|
| Clockodo-Leistungen | `tblRtsegocdpM8CJd` | Name |
| Clockodo-Nutzer | `tblPbly2br8mR2kaU` | Name |
| Clockodo-Buchungen | `tblYQxlauwej7FD1w` | Clockodo-Entry-ID |

### Clockodo EW-Tabellen (private Draft-Stores, user-scoped)

| Tabelle | ID | User | Clockodo-User-ID |
|---------|-----|------|-----------------|
| Clockodo-EW-Johannes | `tbl4vZ2UFyeTRD8hd` | Johannes Berger | 421694 |
| Clockodo-EW-Jilliana | `tblXQIDrvPVN9ijI9` | Jilliana | 391140 |
| Clockodo-EW-Daniel | `tblNDVve3jjJ9s8HB` | Daniel | 391057 |
| Clockodo-EW-Frauke | `tblRrqIQZmm2DosJT` | Frauke | 391141 |

### Kalkulations-Tabellen (integriertes mykilO$$-Modul)

| Tabelle | ID | Primärfeld |
|---------|----|-----------|
| Kalkulationen | `tblO3y2jdmxDnuiZj` | Bezeichnung |
| Kalkulations-Positionen | `tblNamx3cHTus6gtk` | Bezeichnung |
| Eingehende-Angebote | `tbliKfs5FnufjdB36` | SHA256 |

---

## Clockodo-Nutzer Records

| Record-ID | Name | Clockodo-User-ID | EW-Tabelle |
|-----------|------|-----------------|------------|
| recrHGv8SFviFPrvp | Johannes Berger | 421694 | tbl4vZ2UFyeTRD8hd |
| rec3i3LJLtrFwOJBN | Jilliana | 391140 | tblXQIDrvPVN9ijI9 |
| recmbKjrO9emL6yqt | Daniel | 391057 | tblNDVve3jjJ9s8HB |
| recZ7rauB3erxG8Vb | Frauke | 391141 | tblRrqIQZmm2DosJT |

---

## Schlüssel-Felder

### `Clockodo-Nutzer`

| Feld | ID | Typ | Bedeutung |
|------|----|-----|-----------|
| Stundensatz-Override (€/h) | `fld9Ljvdo20qCwKIe` | number | Abweichender Satz für diesen Nutzer |
| Airtable-Entwurf-Tabelle | `fldsoeQHWDmbBt7FM` | text | EW-Tabellen-ID (für Clockodo-Zuhörer) |

### `Clockodo-Leistungen`

| Feld | ID | Typ | Bedeutung |
|------|----|-----|-----------|
| Stundensatz (€/h) | `fld4NBokj4MoOy8Uq` | number | Standard-Stundensatz — noch leer! |

Stundensatz-Priorität: `Nutzer.Stundensatz-Override` > `Leistung.Stundensatz`

**Offener Punkt:** Stundensätze in `Clockodo-Leistungen` noch manuell einzutragen.

---

## Konventionen

- **Projekt-Referenz:** immer `YYYY-NR` (z. B. `2026-015`)
- **Währung:** EUR, Punkt als Dezimaltrennzeichen in der API
- **Datum:** ISO 8601 in der API, europäisch in der UI
- **Leer lassen statt 0:** leer = unbekannt; `0` = explizit Null
- **Nie löschen, nur archivieren:** Status auf "Archiviert" statt Record-Löschung
