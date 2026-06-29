# Handoff: Hustadt-Live-Abnahme — der letzte Schritt zu mykilOS 7

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: polish/dampflok · HEAD b5d062a · Version 6.5.0
Build:  ✅ grün   Tests: ✅ 386 grün (62 Suites)
Datum:  2026-06-29
```

**Stand:** Die Roadmap ist code-komplett (Polish L1–L30, Core Repair A–G, Assistenten-
Schreibtools S1–S17). S17 = 16-Agenten-Audit, 0 Defekte. Es fehlt **kein Code** mehr —
nur die Bestätigung am echten Gerät. Diese Abnahme ist die Definition von „fertig"
(nicht grüne Tests). Wenn alle 5 Häkchen sitzen, ist **mykilOS 7** erreicht.

> Dieser Handoff ist für **Johannes** — die Schritte brauchen ein echtes Google-Konto
> und das echte Gerät. Claude kann sie nicht ausführen (kein Live-Login, kein OAuth-Consent).

---

## Schritt 1 — App frisch bauen & starten

```bash
cd "/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6"
./script/build_and_run.sh    # baut echtes .app-Bundle (Commit wird in Info.plist injiziert)
```

## Schritt 2 — M2: Google Re-Consent (entriegelt 3 Features)

Settings → Google → **Trennen**, dann **Verbinden**. Im Google-Dialog **alle** neuen
Berechtigungen zustimmen. Echtes Trennen→Verbinden ist Pflicht — ein bloßer
Token-Refresh holt die neuen Scopes evtl. nicht.

Neue Scopes und was sie scharfschalten:
- `drive.readonly` → Datei-Inhalt lesen (S5) + volle Dokumentenvorschau (S3)
- `contacts` → `create_contact` (S9)
- `gmail.compose` → `create_draft` (S14, **Versenden bleibt NO-GO**)

## Schritt 3 — M1: Airtable Base-ID korrigieren (Sync-Blocker)

Settings → Airtable → Base-ID muss exakt `appuVMh3KDfKw4OoQ` sein (nicht der PAT).
Speichern → Sync → 31 Projekte erscheinen in der Galerie.

---

## Das Hustadt-Gate — die 5 Häkchen

Projekt **Hustadt** öffnen · `driveFolderID 13ITPqAMdz6JrS13u8y7JvkTVXAWznA_S`

| # | Tun | Erwartet | Beweist |
|---|-----|----------|---------|
| 1 | Dateien-Tab öffnen | Dateien erscheinen aus dem **lokalen** Finder-Pfad (CloudStorage), nicht nur API | B: `LocalDriveRootResolver` löst xattr → lokal |
| 2 | PDF anklicken → „Vollvorschau" | Öffnet **Vorschau/QuickLook**, NICHT Safari | D: `DocumentViewerView` |
| 3 | Angebote-Tab | Findet PDF in `05 eingehende Angebote/Vorplanung…` (Unterordner!) | C: rekursiver `OffersCollector` |
| 4 | Assistent: eine Mail-Frage stellen, dann Schaltzentrum öffnen | `GMAIL_SEARCH` zeigt **> 0** Handshakes | E: `manifestID(forTool:)`-Logging |
| 5 | Settings → Diagnose | **Version + Commit** sichtbar (Commit ≠ „unknown") | A: `DiagnosticsReport` |

**Wenn ein Häkchen fehlt:** nicht „fast fertig" — das ist ein echter Befund. Genau hier
hat die Forensik früher Proxy mit Funktion verwechselt. Befund notieren → zurück an Claude.

**Wenn alle 5 sitzen:** mykilOS 7 ist live. Dann (und nur dann) ist `polish/dampflok` →
`main` merge-/push-reif — auf deine ausdrückliche Freigabe.

---

## Danach — Features scharfschalten (optional, eigene Daten)

- **M3** ClickUp-Listen-IDs in Airtable `Projekte` → `list_all_clickup_tasks` liefert Daten
- **M4** sevdeskRef + Budget in Airtable → Cash-Widget
- **M5** Clockodo-Stundensätze (8 Leistungen) in Airtable
- **M6** alten Airtable-PAT revoken (Security)
- **M7** Drive-Ordner `2026_20_Liebig_Quooker` → `2026_020` umbenennen

## Offener Code-Schritt (auf Ansage)

Voller Postfach-Sync `GmailSyncService` über den TTL-Cache hinaus — einziger größerer
Folgeschritt (Ledger S12). Nicht M2-blockiert; erst auf ausdrückliche Freigabe bauen.

_Übergabe: 2026-06-29 · Claude Code · GOMODE-Verifikation: Mandate A/B/E gegen echten Code bestätigt._
</content>
