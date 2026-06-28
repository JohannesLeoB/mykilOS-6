# Handoff: Live-Wiring-Session 3

Direkte Fortsetzung von [HANDOFF_LIVE_WIRING_2.md](HANDOFF_LIVE_WIRING_2.md).
Diese Session: Live-App-Tour, ein echter Bugfix, Architektur-Handshake für
den nächsten OAuth-Live-Test, und ein Umbenenungs-Wunsch für später.

---

## 1. BrandsView-Navigationsbug behoben

**Entdeckt während Live-Tour:** Klick auf eine `IntegrationCard` in
„Marken & Daten" zeigte den Hover-Effekt, navigierte aber nicht zu
Einstellungen.

**Root Cause:** `@FocusedBinding(\.activeModule)` liefert aus `BrandsView`
immer `nil` — kein fokussiertes View im Hierarchy-Pfad provisioniert das
Binding. Das ist ein bekanntes SwiftUI-Verhalten: `FocusedValues` propagieren
nur vom fokussierten View aufwärts, nicht seitwärts in Geschwister-Views.

**Fix:**
- `BrandsView.swift`: `@FocusedBinding` entfernt, stattdessen
  `onNavigateToSettings: () -> Void = {}` als Parameter.
- `MykilOS6App.swift`: `BrandsView(onNavigateToSettings: { module = .settings })`
  — direkte Closure aus dem Switch, der `module` ohnehin besitzt.
- Alle 7 `{ activeModule = .settings }`-Aufrufe im File → `{ onNavigateToSettings() }`.

**Ergebnis:** `IntegrationCard`-Klick und „Verbindungen in Einstellungen
verwalten"-Button navigieren zuverlässig zu Einstellungen.

---

## 2. Was aus der Live-Tour sonst gelernt wurde

| Bereich | Befund |
|---|---|
| Heute-Board / SignalStrip | ✅ Funktioniert — Greeting, Signale, Demo-Button |
| Projekte-Galerie | ✅ Signal-Badges korrekt (Ocker/Rot je nach Typ) |
| Projekt-Detail CalendarActionCard | ✅ Live bestätigt — Claude rief `suggest_calendar_event` auf, Karte erschien, Browser öffnete Google Calendar |
| Dateien-Tab | ✅ Zeigt `permissionRequired` (kein Google-Account verbunden — korrekt) |
| Marken & Daten | 🐛 Navigation-Bug entdeckt + behoben (siehe oben) |
| Einstellungen | ⬜ Teilweise gezeigt — Profil, Google, Clockodo, ClickUp, Sevdesk sichtbar; Sevdesk-Abschnitt live gesehen |
| Angebote (Sidebar) | ⬜ Nicht mehr gezeigt (Session unterbrochen) |
| Globaler Assistent | ⬜ Nicht mehr gezeigt |

---

## 3. Architektur-Handshake für den nächsten OAuth-Test

Vollständige Beschreibung des Google-OAuth-Flows, Token-Refresh, Widget-Handles
und des offenen `client_secret`-Risikopunkts — als Briefing für den nächsten
Live-Wiring-Sprint gesammelt (im Kontext dieser Session, nicht in einer Datei).

Kurzform für die nächste Session:
- OAuth-Einstieg: `SettingsView.googleSection` → TextField `clientID` → Button „Verbinden"
- Service: `GoogleAuthService.startAuthorization(clientID:)` in `GoogleAuthService.swift:34`
- Loopback auf random Port (RFC 8252), kein `client_secret` gesendet
- Tokens: Keychain `com.mykilos6.google` — `tokens` + `clientID`
- Widget-Handles kommen aus Airtable-Sync via `ProjectLinks` (Felder `driveFolderID`, `calendarQuery`, `mailQuery`, `contactsQuery`)
- ⚠️ Wenn Google `invalid_client` → `client_secret` in `buildTokenExchangeRequest` ergänzen

---

## 4. Vorgemerkter Umbenenungs-Wunsch (nicht umgesetzt)

„Marken & Daten" → **„Integrationen"** — auch die Rolle des Moduls soll
erweitert werden von Status-Dashboard zu aktivem Datenstrom-Hub.

Betroffene Stellen wenn umgesetzt:
- `AppModule.brands` → `.integrations`, Label `"Integrationen"`
- `BrandsView.swift` → `IntegrationsView.swift`
- Cmd+4-Shortcut-Label in `AppCommands`
- `CLAUDE.md` Statuszeile

In Memory gespeichert. Wird angepackt wenn das Modul sowieso angefasst wird.

---

## Build/Test-Status

**169 Tests grün.** `swift build` clean. Keine neuen Tests nötig — BrandsView
ist reine View-Logik ohne eigene Business-Regeln.

---

## Offene Punkte für die nächste Session

1. **Google OAuth live verifizieren** — erster echter Connect mit einem
   Google-Account (benötigt OAuth-Client-ID aus Google Cloud Console).
2. **Airtable-Sync testen** — `mykilOS Mastermind`-Base (`appuVMh3KDfKw4OoQ`,
   69 Records) in Settings eintragen und `syncFromAirtable` live laufen lassen,
   damit `ProjectLinks` (driveFolderID, calendarQuery etc.) aus echten Daten
   befüllt werden.
3. **Live-Tour fortführen** — Angebote-Sidebar, globaler Assistent noch nicht
   gezeigt.
4. Live-Verifikation der Session-2-Fixes (Fenster-Drift, Favoriten, Drive-Routing).

---

## Empfohlener Startprompt für die nächste Session

> „Live-Wiring-Session 4: Lies HANDOFF_LIVE_WIRING_3.md. Zuerst swift test
> verifizieren (169 Tests soll grün sein). Dann OAuth-Live-Test: Google
> Cloud Console Client-ID eingeben, 'Verbinden' klicken, prüfen ob der
> Browser öffnet und der Login-Flow durchläuft. Falls invalid_client → Skill
> mykilos-live-wiring Phase 1 (client_secret-Fallback). Nach erfolgreichem
> Login: Airtable-Mastermind-Sync (Base appuVMh3KDfKw4OoQ), dann Drive-Widget
> + Dateien-Tab mit echten Ordner-Daten verifizieren."
