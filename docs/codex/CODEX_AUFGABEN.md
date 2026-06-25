# Codex-Aufgaben — nach Akt 5

Stand: `f222b56` · 80 Tests grün · Akte 0–5 abgeschlossen

---

## Aufgabe 1: Auto-Sync bei App-Start (Airtable)

**Prompt für Codex:**

```
Lies CLAUDE.md und docs/codex/WORKFLOW.md.

Aufgabe: Implementiere Auto-Sync bei App-Start für Airtable.

Kontext:
- AirtableAuthService liegt in Sources/MykilosServices/Airtable/AirtableAuthService.swift
- RegistryStore.syncFromAirtable(baseID:auth:) existiert bereits in Sources/MykilosApp/Data/RegistryStore.swift
- AppState.bootstrap() in Sources/MykilosApp/Data/AppState.swift ist der App-Start-Hook

Was zu tun ist:
1. In AppState.bootstrap(): wenn airtableAuth.status == .connected, die gespeicherten Credentials laden und syncFromAirtable aufrufen
2. Sync soll NACH dem lokalen Load laufen (Demo-Seed + lokaler Cache zuerst, dann Airtable-Update)
3. Kein neuer Test nötig (Sync-Logik ist schon getestet), aber swift test muss grün bleiben
4. Handoff: docs/handoffs/HANDOFF_POST_AKT5_1.md
5. CLAUDE.md aktualisieren (offene Punkte)

Regeln: CLAUDE.md "Absolute Regeln" gelten. Secrets nur Keychain.
```

---

## Aufgabe 2: Audit-Store verdrahten

**Prompt für Codex:**

```
Lies CLAUDE.md und docs/codex/WORKFLOW.md.

Aufgabe: Implementiere einen persistenten AuditStore und verdrahte ihn mit dem AssistantWidget.

Kontext:
- AuditEntry existiert bereits in Sources/MykilosKit/Domain/AuditEntry.swift
- AuditRecord existiert in Sources/MykilosServices/Database/WidgetBoardRecord.swift (Tabelle auditEntries ist in der GRDB-Migration)
- Das AssistantWidget hat Action-Cards mit Bestätigungs-Buttons (Sources/MykilosWidgets/Kinds/AssistantWidget.swift) — aktuell nur visuelles Feedback, kein Schreiben
- Folge dem NoteStore-Muster: @MainActor @Observable, throws, SaveState

Was zu tun ist:
1. AuditStore in MykilosServices erstellen (GRDB-backed, analog NoteStore)
2. In AppState als Property hinzufügen
3. AssistantWidget: bei Bestätigung einer SuggestedAction über den AuditStore einen AuditEntry schreiben
4. Cold-Start-Test: AuditEntry schreiben → neue AuditStore-Instanz → lesen → identisch
5. Handoff: docs/handoffs/HANDOFF_POST_AKT5_2.md
6. CLAUDE.md aktualisieren

Regeln: Jeder Schreibvorgang throws. SaveState sichtbar. CLAUDE.md "Absolute Regeln" gelten.
```

---

## Aufgabe 3: About-Fenster

**Prompt für Codex:**

```
Lies CLAUDE.md und docs/codex/WORKFLOW.md.

Aufgabe: Erstelle ein About-Fenster für mykilOS 6.

Was zu tun ist:
1. In MykilOS6App.swift: eine neue WindowGroup oder Settings-Scene für "Über mykilOS"
2. Zeigt: App-Name "mykilOS 6", Version "6.0.0", Copyright "MYKILOS", kurzer Einzeiler
3. Erreichbar über das macOS-Menü (Cmd+, oder mykilOS 6 → Über mykilOS 6)
4. Design: MykColor.paper Hintergrund, MykColor.ink Text, Font.mykDisplay für den Namen
5. Kein Test nötig (reine UI), aber swift build + swift test müssen grün bleiben
6. Handoff: docs/handoffs/HANDOFF_POST_AKT5_3.md

Regeln: Nur Design-Tokens aus MykilosDesign verwenden. Keine .font(.system(...)).
```

---

## Reihenfolge

1 → 2 → 3 (jede Aufgabe ist eine eigene Codex-Session)
