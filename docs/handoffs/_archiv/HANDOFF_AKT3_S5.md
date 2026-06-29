# Handoff — Akt 3, Schritt 5: Clockodo-Widget live

**Status:** abgeschlossen
**Commit:** (noch nicht committed)

---

## Was passiert ist

Clockodo-Zeiterfassung als voll integriertes Widget in mykilOS:

### Neue Dateien

| Datei | Zweck |
|---|---|
| `Sources/MykilosKit/Domain/ClockodoConnectionStatus.swift` | Enum `.disconnected / .connected / .error(String)` |
| `Sources/MykilosServices/Clockodo/ClockodoClient.swift` | API-Client: liest heutige Zeiteinträge (v2 REST), gruppiert nach Projekt/Kunde. `ClockodoFetching`-Protokoll für Testbarkeit. |
| `Sources/MykilosServices/Clockodo/ClockodoAuthService.swift` | `@Observable` Auth-Service: speichert E-Mail + API-Key ins Keychain, verwaltet `ClockodoConnectionStatus`. |
| `Sources/MykilosServices/Clockodo/KeychainClockodoCredentialsStore.swift` | Keychain-Adapter über den bestehenden `KeychainStore`. `ClockodoCredentialsStoring`-Protokoll für Fakes. |
| `Tests/MykilosServicesTests/ClockodoClientTests.swift` | URL-Bau, JSON-Parsing, Fallback-Label, Fehlerfall — kein Netzwerk. |
| `Tests/MykilosServicesTests/ClockodoAuthServiceTests.swift` | Connect/Disconnect/Whitespace-Trim/Leere-Felder — In-Memory-Store. |

### Geänderte Dateien

| Datei | Was |
|---|---|
| `Sources/MykilosApp/Today/ClockodoWidget.swift` | Vollständiges Widget mit Loader, TimeBar, allen Renderstates (loading/content/empty/permissionRequired/error). |
| `Sources/MykilosApp/Data/AppState.swift` | `clockodoAuth: ClockodoAuthService` hinzugefügt. |
| `Sources/MykilosApp/Settings/SettingsView.swift` | Clockodo-Sektion: E-Mail + API-Key Felder, Verbinden/Trennen, Status-Badge. |

### Bereits vorhanden (vor diesem Schritt)

- `WidgetKind.clockodo` in `WidgetFoundation.swift`
- `SourceChip`-Mapping (`.clock` Icon)
- `WidgetContainer`-Farbzuordnung (`.tasks` / Ocker)
- `HomeBoardView`-Dispatch (`case "clockodo"`)

---

## Architektur-Entscheidungen

1. **Kein OAuth** — Clockodo nutzt API-Key + E-Mail als Header-Auth, kein Redirect-Flow nötig. Deshalb eigener `ClockodoAuthService` statt Erweiterung des Google-OAuth-Flusses.

2. **ZEITEN-Regel eingehalten** — mykilOS ist reiner Mapping-/Status-Layer, niemals zweite Zeit-Wahrheit. Widget zeigt heutige Einträge gruppiert nach Clockodo-Projektnamen, keine eigene Buchung.

3. **Keine Verknüpfung zu mykilOS-Projekten in V1** — Das Widget aggregiert projektübergreifend auf dem Home-Board. Mapping Clockodo-Projekt → mykilOS-Projekt ist für einen späteren Schritt vorgesehen.

4. **`SecureField` für API-Key** — Im Gegensatz zur Google Client-ID wird der API-Key als Passwort-Feld dargestellt.

---

## Tests

48 Tests grün, davon 11 neue:

- `ClockodoClientTests`: URL-Bau, JSON-Parsing (Projekt, Kunde, Fallback), Fehlerfälle
- `ClockodoAuthServiceTests`: Init-Status, Connect, Disconnect, Whitespace-Trim, leere Felder

Kein echtes Netzwerk, kein echtes Keychain im Testlauf — alles über In-Memory-Fakes.

---

## Offene Punkte

- **Erster Live-Test steht aus** — API-Key-Auth ist nicht live getestet. Falls Clockodo weitere Header oder andere Antwortformate liefert als dokumentiert, im Parsing nachbessern.
- **Laufende Buchung** — `duration` ist `null` bei laufenden Einträgen (noch nicht gestoppt). Aktuell werden diese mit `0` Sekunden dargestellt. Ein späterer Schritt könnte hier einen Live-Timer einbauen.
- **Widget-Refresh** — Aktuell lädt das Widget einmal bei `.task`. Kein Polling/Timer für automatisches Aktualisieren.
