# 🜂 mykilOS 6+ Hyperbuild — Der Brühwürfel

> **Die ganze App auf einer Seite. Bei Session-Start ZUERST lesen — danach erst Code.**
> Wenn alles andere verloren ginge, ließe sich aus dieser Seite das Verständnis
> rekonstruieren. Jede Zeile trägt. Kein Ballast.

```
Pfad:    /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch:  polish/dampflok   ·   HEAD a461fee   ·   GitHub JohannesLeoB/mykilOS-6 (privat)
Build:   ✅ swift build grün        Tests: ✅ 270 grün (43 Suites)
Modell:  claude-sonnet-4-6 (App)    Stand: 2026-06-28
Fallback: git checkout ui/sidebar-ci-stable
```

---

## 1 · Was es ist

Ein persönliches macOS-Cockpit (SwiftUI, local-first) für Studio-Projektarbeit.
Jeder Nutzer sieht durch **seine** Identität auf **geteilte** Instrumente (Drive,
Kalender, ClickUp, Airtable) und **private** Daten (Clockodo). Farbe ist Sprache:
man erkennt die Quelle, bevor man liest. Airtable ist System-of-Record, kein
Sync-Backend. Signale sind Vorschläge — geschrieben wird nie ohne Bestätigung.

**Hyperbuild = mykilOS 6, das endlich *tut* was es behauptet.** Der Sprung ist
nicht „neue Features", sondern *Proof-of-Existence → Proof-of-Function* (siehe §3+4).

---

## 2 · Architektur in sieben Zeilen (das zeitlose Skelett)

```
App → Widgets → Design        |  Services → Kit        |  Integrations → Kit
MykilosKit       importiert NIE SwiftUI/GRDB (reine Domain + Persistence + Signals)
MykilosWidgets   importiert NIE GRDB; Widgets reden NIE direkt → nur StudioContext.emit()
Schreibvorgänge  kommen NIE aus Views — nur über Stores; jeder Write throws; SaveState sichtbar
Persistenz       GRDB; Cold-Start-Test Pflicht (schreiben→neue Instanz→lesen→identisch)
Tokens           SwiftLint erzwingt: Font.myk… / MykColor.… — keine .system()/Color(red:)
Secrets          nur Keychain, pro Nutzer isoliert; Clockodo nur Private Area
```

---

## 3 · Die eine Lektion (Wurzel aller 13 Forensik-Befunde)

> **Proxy-Optimierung statt Ziel-Optimierung.**

Frühere Sessions optimierten messbare Stellvertreter — Tests grün ✅, Ledger-Haken ✅,
Commit ✅, Handoff ✅ — und verwechselten sie mit dem Ziel: *läuft live, mit echten
Daten, am echten Gerät.* „Drive live" hieß „API antwortet", nicht „Nutzer öffnet Datei".
Ein Fehler, aufgeteilt in 13 Befunde (Forensik: 60 Agenten).
Vollständig: [docs/handoffs/HANDOFF_POLISH_DAMPFLOK.md](docs/handoffs/HANDOFF_POLISH_DAMPFLOK.md).

---

## 4 · „Fertig" = das Hustadt-Live-Gate (nicht grüne Tests)

```
Projekt Hustadt · driveFolderID 13ITPqAMdz6JrS13u8y7JvkTVXAWznA_S
✅ Dateien-Tab zeigt Dateien aus lokalem Finder-Pfad
✅ PDF-Klick öffnet Vorschau — NICHT Safari
✅ Angebote-Tab findet PDF in „05 eingehende Angebote/Vorplanung…"
✅ Schaltzentrum: GMAIL_SEARCH > 0 Handshakes nach erstem Chat
✅ Settings → Diagnose: Version + Commit sichtbar
```
Drive/Offers/Assistent-Commits brauchen einen Hustadt-Haken im Handoff vor dem Merge.

---

## 5 · Wo wir stehen (die Wahrheit)

| | live & verifiziert | behauptet, aber nicht funktional → Core Repair fixt |
|---|---|---|
| **Daten** | Airtable-Sync (31 Projekte), Drive-API, Kalender, Mail, Claude-Assistent, Kalkulation-Widget | lokales Drive-Öffnen · rekursive Angebote · Schaltzentrum-Handshakes · App-Diagnose · GmailCache (L23 committed, unverdrahtet) |

Polish-Loop L1–L23 ✅ committed · L24–L30 ⏳ ([Ledger](docs/POLISH_LOOP_LEDGER.md)). Core Repair = PR #3 OPEN.

---

## 6 · Die einzige To-do-Liste

**🔴 Core Repair (PR #3 · Mandate A–G) — kritischer Pfad:**
A App-Diagnose · B Lokales Drive-Routing (`LocalDriveRootResolver`, xattr) · C Angebote rekursiv + Pagination ·
D Document-Workspace (PDFKit/QuickLook/OCR) · E Typed I/O (`toolName→manifestID`, eine Manifest-Datei) ·
F Crash-Diagnostics (`try!` raus, recoverable DB) · G Backup/Restore (WAL-Checkpoint + SHA-256)

**🟡 Polish L24–L30:** Kontakt-Kontext · Favoriten (GRDB) · Dunkelmodus-Kontrast · Timeline-Tab · Leerzustände · Test-Decke · Abschluss+DMG

**🟢 Nur Johannes (kein Code):**
M1 Airtable Base-ID fixen (PAT statt `appuVMh3KDfKw4OoQ`) 🔴 Sync-Blocker · M2 Google Re-Consent (userinfo-Scopes) ·
M3 ClickUp-Listen-IDs · M4 sevdeskRef+Budget · M5 Clockodo-Stundensätze · M6 Alt-PAT revoken · M7 `2026_20`→`2026_020`

---

## 7 · Eiserne Regeln

1. **Kanonischer Ordner** `…/MYKILOS 6/mykilOS6/`. `~/Desktop/CLAUDE/` = Wegwerf-Worktrees.
2. **Vor jedem Handoff:** `swift build && swift test` grün · `git status` clean.
3. **Externe Daten heilig:** Sevdesk nie · geteilte Airtable-Base & Drive-Root read-only · **nie löschen/überschreiben** (Inaktivierung nur per Status-Feld).
4. **„Fertig" = Hustadt-Gate.** **Push/PR nur auf ausdrückliche Freigabe.**
5. **Jede neue Daten-Weiche sofort** ins Datenstrom-Handbuch (Airtable `tblaUVftka0GvXzeU`) + `docs/BENUTZERHANDBUCH.md`.

---

## 8 · Karte (wo der Rest liegt)

- **Vollständiges Gedächtnis** → [CLAUDE.md](CLAUDE.md) · **Backlog/Ideen** → [docs/IDEEN_UND_BACKLOG.md](docs/IDEEN_UND_BACKLOG.md)
- **Verlauf (Pflicht-Mitschrift)** → [docs/EREIGNISPROTOKOLL.md](docs/EREIGNISPROTOKOLL.md) · **Nutzerfunktionen** → [docs/BENUTZERHANDBUCH.md](docs/BENUTZERHANDBUCH.md)
- **Daten-Schemata** → [docs/PARTNER_APP_SCHEMA.md](docs/PARTNER_APP_SCHEMA.md) · [docs/SCHALTZENTRUM_DATENSTROM.md](docs/SCHALTZENTRUM_DATENSTROM.md)
- **Team/Collective** → [docs/MYKILOS_6_TEAM_MODELL.md](docs/MYKILOS_6_TEAM_MODELL.md) · [docs/TEAM_CHARTER.md](docs/TEAM_CHARTER.md) · [docs/COLLECTIVE_REGELWERK.md](docs/COLLECTIVE_REGELWERK.md)
- **Historie komprimiert** → [docs/handoffs/_archiv/INDEX.md](docs/handoffs/_archiv/INDEX.md) · [docs/_archiv/](docs/_archiv/)

_Destilliert 2026-06-28 — der Brühwürfel. Wird mit jedem Meilenstein nachgeschärft, nie aufgebläht._
</content>
