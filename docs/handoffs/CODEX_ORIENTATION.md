# Codex Orientierung — Wer bin ich, wo bin ich, was habe ich?

Lies das einmal vollständig durch bevor du irgendetwas tust.

---

## WER IST JOHANNES?

Johannes ist Inhaber eines kleinen Architektur-/Designbüros (MYKILOS). Er ist
kein Softwareentwickler von Beruf — er denkt produktgetrieben, hat klare
Vorstellungen vom Ergebnis, aber nicht immer vom Weg dorthin.

**Was das für dich bedeutet:**
- Terminal-Befehle immer vollständig hinschreiben. Nie "führe dann den üblichen
  Build-Befehl aus" — immer `./script/build_and_run.sh` ausschreiben.
- Erklärungen: kurz, auf Deutsch, ergebnisorientiert. Nicht "wir könnten
  erwägen..." — sondern "ich mache X, weil Y, Ergebnis ist Z".
- Wenn etwas schiefgeht: Fehlermeldung zeigen, dann direkt sagen was zu tun ist.
- Keine langen Theorie-Exkurse. Johannes will die App benutzen, nicht Swift lernen.
- Entscheidungen, die nur er treffen kann (Daten, Passwörter, OAuth-Freigaben),
  klar benennen und warten — nicht raten.
- Er arbeitet auf einem Mac. Alle Pfade sind macOS-Pfade.

---

## WO BIN ICH?

**Arbeitsverzeichnis — IMMER DIESER ORDNER (der gelbe MYKILOS-6-Ordner):**
```
/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
```

**GitHub Repo:** https://github.com/JohannesLeoB/mykilOS-6 (privat)
**Aktiver Branch:** `claude/musing-sammet-3abd94`
**Ziel-Branch für PR:** `main`

**Orientierung im Repo:**
```bash
git log --oneline -5        # Was wurde zuletzt gemacht?
git status                  # Gibt es offene Änderungen?
ls docs/handoffs/           # Welche Handoffs existieren?
```

Letzter dokumentierter Stand: Drive-Tab live, Drive→Assistent-Signal live, 97 Tests grün.

---

## WAS HABE ICH — TOOLS UND KONNEKTOREN

### Swift / Build
```bash
swift build                   # kompilieren
swift test                    # alle Tests (soll 97+ grün sein)
./script/build_and_run.sh     # echtes .app-Bundle bauen + starten (dist/)
swiftlint --strict            # Token-Disziplin prüfen
```

### Git / GitHub
```bash
git status
git log --oneline -5
git add <datei> && git commit -m "feat: ..."
git push
gh pr view                    # offener PR anschauen
```
Offener PR: https://github.com/JohannesLeoB/mykilOS-6/pull/1

### Airtable (System of Record)
**Base:** `appuVMh3KDfKw4OoQ` — das ist DIE Mastermind-Base. Nur diese.
**PAT im Keychain lesen:**
```bash
security find-generic-password -s "com.mykilos6.airtable" -a "pat" -w
```
**Alle Tabellen prüfen:**
```bash
./script/airtable_verify.sh
```
⚠️ Bekanntes Problem: Keychain-Feld `baseID` enthält fälschlich ein zweites PAT.
Fix: App öffnen → Einstellungen → Airtable → Base-ID = `appuVMh3KDfKw4OoQ` eintragen.

### Google (Drive, Kalender, Kontakte, Gmail)
Token liegt im Keychain via `GoogleAuthService` (Service: `com.mykilos6.google`).
OAuth-Flow läuft im Browser. Nach Verbinden sind Drive/Kalender/Kontakte/Mail live.
Drive ist **read-only** — nie schreiben, nie verschieben.

### Clockodo (Zeiterfassung)
API-Key im Keychain via `ClockodoAuthService` (Service: `com.mykilos6.clockodo`).
Jeder User bucht/sieht nur seine eigenen Einträge — nie cross-user.

### Claude API (Anthropic)
Key im Keychain via `ClaudeAuthService` (Service: `com.mykilos6.claude`).
Default-Modell: `claude-sonnet-4-6`. Wird vom AssistantWidget genutzt.

### mykilO$$$ Quell-Code (read-only, nie verändern)
```
/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilO$$$/
  ClaudeCode_Final_Handoff_2026-06-26/04_PROJECT/MYKILOSKalkulationslabor/
    Sources/MYKILOSKalkulationslabor/
```
Daraus werden 10 Swift-Dateien verbatim nach `Sources/MykilosKalkulationsCore/` portiert.

---

## WAS DARF ICH NICHT — ABSOLUTE VERBOTE

| Verbot | Warum |
|---|---|
| Sevdesk berühren | NO-GO, externe Buchhaltung, nicht unser System |
| Fremde Airtable-Base `appkPzoEiI5eSMkNK` | Alte mykilO$$$-Base, stillgelegt |
| Google Drive schreiben/verschieben | Read-only, Originaldateien sind heilig |
| Secrets in Code / Commits / Logs | Nur Keychain |
| `try?` ohne Kommentar bei Schreibvorgängen | Persistenzregel, SwiftLint |
| `import GRDB` in MykilosKit oder MykilosWidgets | Architekturgrenze |
| Schreiben aus Views (nicht aus Stores) | Architekturgrenze |
| Neues persistentes Feature ohne Cold-Start-Test | Merge-Gate, Projektgesetz |
| Automatisch buchen/senden ohne Nutzerbestätigung | Nie — immer ActionCard → Confirm |

---

## WIE ICH ARBEITE

**Eine Session = ein Ziel.** Nie zwei Themen in einem Commit bündeln.

**Jede Session endet mit:**
1. `swift build` grün
2. `swift test` grün (Zahl der Tests steigt oder bleibt gleich)
3. `./script/build_and_run.sh` — App startet, Feature manuell geprüft
4. `docs/handoffs/HANDOFF_SESSION_{X}.md` geschrieben
5. `CLAUDE.md` Status-Tabelle aktualisiert
6. Commit mit sprechendem Message, Push

**Commit-Format:**
```
feat: kurze Beschreibung (Session X)
fix: was und warum
docs: was dokumentiert wurde
```
Immer auf Englisch. Nie "WIP" oder "misc".

---

## WO FINDE ICH DEN BAUPLAN?

```
docs/handoffs/MASTER_HANDOFF_CODEX.md    ← vollständiger Bauplan, Sessions A–I
docs/handoffs/CODEX_START_PROMPT.md      ← kurzer Einstieg
docs/handoffs/CODEX_HANDOFF_KALKULATION.md ← Kalkulations-Port im Detail
CLAUDE.md                                ← Projekt-Gedächtnis, immer aktuell
```

**Wenn du nicht weiterweißt:** Lies zuerst `MASTER_HANDOFF_CODEX.md` Abschnitt
"Was heute wirklich funktioniert" — der zeigt dir den ehrlichen Ist-Stand.
Dann lies den Handoff der letzten abgeschlossenen Session.

---

## WAS ALS NÄCHSTES KOMMT

Starte mit dem Pre-Flight:
```bash
swift build && swift test
git log --oneline -5
./script/build_and_run.sh
./script/airtable_verify.sh
```

Dann wähle eine Session aus `MASTER_HANDOFF_CODEX.md` — empfohlene Startreihenfolge:
- **Session A** — User-Identität nach Login (Google-Email in der Sidebar)
- **Session B** — Clockodo-Widget live (echte Zeiten statt Demo)
- **Session C** — Heute-Board → Projektdetail Navigation (MiniProjectCard klickbar)
- **Session D** — Drive-Ordner-Links überall (Klick öffnet Ordner in Browser)
- **Session F** — Kalkulations-Core-Target portieren (unabhängig von A–D)

Fang mit der an, die dir am klarsten ist. Alle sind unabhängig voneinander startbar.
