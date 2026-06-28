# Startprompt S17 — Security-Härtung + technische Schulden

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: feat/kalkulation-calibration-loop (oder main nach Merge von S16)
Build:  ✅ 198 Tests grün (179 swift-testing + 19 XCTest)
Datum:  2026-06-28
```

---

## Du bist Teil des mykilOS Dev Collective

**Lese zuerst:** `docs/TEAM_CHARTER.md`

Die wichtigsten Regeln für dich als aktive Build-Session:

1. **Du bist der aktive Chef** — S10 Learning (keen-williamson-ddb354) ist der Tisch. Alle anderen Sessions beobachten still.
2. **Kein Push ohne explizite Freigabe von Johannes** — auch wenn alles grün ist.
3. **`git add` immer mit expliziten Pfaden — nie `git add -A`** — Johannes hat uncommittete eigene Änderungen (z.B. `docs/IDEEN_UND_BACKLOG.md`). NIE anfassen.
4. **Handoff-Dreifach-Pflicht am Ende:** EREIGNISPROTOKOLL-Eintrag + CLAUDE.md aktualisiert + STARTPROMPT_S18.md geschrieben — alle drei, kein STOP ohne sie.
5. **Kanonischer Ordner:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/` — der einzige echte Arbeitsort. Desktop-Worktrees sind Wegwerfkopien.
6. **Wenn du merkst die Richtung ist grundsätzlich falsch** — stopp und melde es an Johannes/Tisch. Nicht weiterbauen auf falschen Fundamenten (Statut 14).
7. **Fehler werden berichtet, nicht verschwiegen** (Kulturregel des Collectives).

---

## Session-Schematik

S12 → S14 → S15 → S16 → **S17** → S18 → S19 → S20

Jede Session = ein abgeschlossener Schritt, sauberer Handoff, kein Bug offen,
Tests grün, Commit, Dokumentation aktuell. STOP wenn der Schritt fertig ist.

**Roadmap der nächsten Sessions:** `docs/handoffs/ROADMAP_S16_S20.md`

---

## Was S16 hinterlassen hat (Lern-Loop, Kalkulation Schritt 8)

| Schritt | Was | Status |
|---|---|---|
| 1–7 | Kalkulations-Port: Core, Lernschicht, Engine, geraetepreis, Widget, recordAdjustment | ✅ |
| 8 | Lern-Loop sichtbar: `lernen`-Toggle, `lernUebersicht`, `promote`, Widget-Sektion, `.calibrationPromoted` | ✅ |

**Offener Engine-Stub:** nur noch `importPDF` (braucht Drive-Download + PDF-Pipeline —
eigene Spur, NICHT S17).

Details: `docs/handoffs/HANDOFF_KALKULATION_CORE_PORT.md` (Schritt 8).

---

## Pflicht-Checks ZUERST

```bash
cd "/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6"
pwd
git status
git log --oneline -3
swift build && swift test 2>&1 | tail -5
```

Falls S16 gemergt: `git checkout main && git pull`. Sonst auf
`feat/kalkulation-calibration-loop` bleiben und neuen Branch abzweigen:
```bash
git checkout -b feat/security-haertung
```

---

## ⚠️ Wichtiger Vorab-Check (S16-Finding, ehrlich gemeldet)

Die Roadmap nennt als S17-Aufgabe 1 das **Löschen von `AirtableSyncService.swift`**
(3 Regelverstöße: ENV-Secrets, fremde Base `appkPzoEiI5eSMkNK`, `DispatchSemaphore`).

**Befund aus S16:** Diese Datei existiert auf dem aktuellen Branch
(`feat/kalkulation-calibration-loop` ← `…-record-adjustment` ← `…-core-port`) **NICHT**:
```bash
find Sources -name "AirtableSyncService.swift"      # → leer
grep -rln "AirtableSyncService\|appkPzoEiI5eSMkNK\|DispatchSemaphore" Sources Tests
                                                     # → nur Doku-Treffer, kein Code
```
Sie liegt vermutlich auf einer anderen Branch-Linie (z. B. `main`/`stabilize` oder
einem Live-Wiring-Branch). **Bevor du Aufgabe 1 angehst:** kläre mit dem Tisch/Johannes,
auf welchem Branch der echte Integrationsstand liegt und ob die Kalkulations-Branches
zuerst nach `main` gemergt werden. Sonst löschst du etwas, das hier gar nicht liegt,
oder die Härtung landet auf dem falschen Fundament (Statut 14).

---

## Dein Auftrag: Security-Härtung + technische Schulden

Scope bewusst klein halten — kein Feature-Bloat.

### 1) `AirtableSyncService.swift` löschen (NUR falls vorhanden, siehe Vorab-Check)
- 3 Regelverstöße: ENV-Secrets statt Keychain, fremde Base `appkPzoEiI5eSMkNK`
  (stillgelegt, NIE anfassen), `DispatchSemaphore` (blockierend).
- Sicherstellen, dass nichts mehr darauf referenziert; `swift build` grün halten.

### 2) Google-Identität nach Login anzeigen
- Nach dem Token-Tausch `GET https://www.googleapis.com/oauth2/v2/userinfo`
  (mit Access-Token) → `GoogleUserInfo(email, displayName)`.
- Keychain-Cache (gleiches Muster wie `KeychainGoogleTokenStore`).
- `AppState.currentGoogleUser` → Anzeige in der Sidebar (`SidebarView`).
- **Test (Merge-Gate-tauglich):** JSON-Parsing des userinfo-Response OHNE Netzwerk
  (injizierbarer HTTP-Client, gleiches Muster wie `ClaudeMessagesClient`/`GoogleDriveClient`).
- Relevante Dateien: `Sources/MykilosServices/Google/` (neue `GoogleUserInfoClient`),
  `GoogleAuthService.swift`, `Sources/MykilosApp/Data/AppState.swift`,
  `Sources/MykilosApp/.../SidebarView.swift`.

### 3) Airtable baseID-Validierung in Settings
- `baseID` muss mit `app` beginnen (Airtable-Konvention) — klare Fehlermeldung
  statt stillem 404 beim Sync.
- Relevante Dateien: `Sources/MykilosApp/.../SettingsView.swift`,
  `Sources/MykilosServices/Airtable/AirtableAuthService.swift`.
- Hinweis: Es gibt einen bekannten Keychain-Bug, bei dem die gespeicherte `baseID`
  versehentlich den PAT enthielt statt `appuVMh3KDfKw4OoQ`. Die Validierung hilft,
  das künftig früh zu fangen.

---

## Absolute Regeln

- **Sevdesk: NIE lesen/schreiben**
- **Airtable-Base `appuVMh3KDfKw4OoQ`: nur lesen**
- **Airtable-Base `appkPzoEiI5eSMkNK`: NIE anfassen (stillgelegt)**
- **Drive: read-only — nie schreiben oder verschieben**
- Secrets nur Keychain, nie in Code/Commits/Logs
- `MykilosKit`: kein SwiftUI, kein GRDB
- `MykilosWidgets`: kein GRDB direkt, **kein `import MykilosKalkulationsCore`**
- Schreibvorgänge nie aus Views — nur über Stores/Engine
- **Neues persistierbares/parsbares Feature → Test ist Merge-Gate**
- `try?` nur mit erklärendem Kommentar
- **`git add` immer mit expliziten Pfaden — nie -A**
- **Kein Push ohne explizite Freigabe von Johannes**

---

## Handoff-Dreifach-Pflicht am Ende (Statut 13)

Kein STOP ohne alle drei:

1. `swift build && swift test` — grün, keine Regressions, mindestens 198 Tests
2. `git add <nur eigene Dateien>` — explizit, nie -A
3. `git commit -m "feat: security hardening + google identity + baseID validation (S17)"`
4. `docs/handoffs/HANDOFF_S17.md` (oder passendes Handoff-Doc) schreiben
5. **`docs/EREIGNISPROTOKOLL.md`** — neuen Eintrag oben einfügen
6. **`CLAUDE.md`** — Fortschrittstabelle aktualisieren
7. **`docs/handoffs/STARTPROMPT_S18.md`** — für nächste Session schreiben (S18 =
   Clockodo Zuhörer Phase 1, siehe Roadmap)
8. Erfahrungsbericht an S10 Learning senden (Tisch)
9. STOP — auf Johannes' Push-Freigabe warten

---

## Was S18 als nächstes macht

Clockodo Zuhörer Phase 1: Chat-Eingabe → Zeitbuchungs-Entwurf → persönliche
Airtable-EW-Tabelle. Große Session, 6-Schichten-Architektur.

Details: `docs/handoffs/ROADMAP_S16_S20.md`
