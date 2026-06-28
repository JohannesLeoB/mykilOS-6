# Codex Start-Prompt

Kopiere diesen Text als erste Nachricht in eine neue Codex-Session:

---

Du übernimmst die Weiterentwicklung von **mykilOS 6** — einem macOS-Studio-Cockpit für ein Architektur-/Designbüro. Swift Package, SwiftUI, local-first, GRDB.

**Repo:** https://github.com/JohannesLeoB/mykilOS-6 (privat)
**Branch:** `claude/musing-sammet-3abd94`
**Letzter Stand:** Build grün, 97 Tests grün, Drive-Widget + Files-Tab live.

**Dein erster Schritt — immer:**
```bash
swift build && swift test          # muss grün sein
git log --oneline -5               # letzten Stand lesen
./script/build_and_run.sh          # App starten, kein Crash
./script/airtable_verify.sh        # Konnektoren prüfen
```

**Bekanntes Problem Airtable:** Das Keychain-Feld `baseID` enthält fälschlich ein PAT-Token. Wenn `airtable_verify.sh` alles als 404 meldet: App öffnen → Einstellungen → Airtable → Base-ID = `appuVMh3KDfKw4OoQ` eintragen.

**Dein vollständiger Bauplan:**
`docs/handoffs/MASTER_HANDOFF_CODEX.md` — lies das vollständig durch bevor du eine Zeile Code anfasst. Es enthält:
- Architektur und Schichtgrenzen
- Alle Airtable-Tabellen mit IDs
- Was heute wirklich funktioniert (ehrlich)
- Was noch fehlt und warum
- Session-Plan A bis I mit konkreten Anweisungen
- Alle absoluten Verbote

**Nächste offene Session:** Beginne mit **Session A** (User-Identität nach Login) oder **Session C** (Heute → Projektdetail Navigation) — beide sind unabhängig startbar. Für die Kalkulations-Engine beginne mit **Session F** (`docs/handoffs/CODEX_HANDOFF_KALKULATION.md`).

**Jede Session endet mit:**
1. `swift build` + `swift test` grün
2. `./script/build_and_run.sh` → Feature manuell prüfen
3. `docs/handoffs/HANDOFF_SESSION_{X}.md` schreiben
4. `CLAUDE.md` Status-Tabelle aktualisieren
5. Commit + Push auf `claude/musing-sammet-3abd94`

Eine Session = ein Ziel. Nie zwei Themen bündeln.
