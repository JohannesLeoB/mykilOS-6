# Handoff — Akt 3: Die Fenster sind offen

**Status:** abgeschlossen (8 Schritte, 8 Commits)

## Was in diesem Akt passiert ist

mykilOS 6 ist vom lokalen Cockpit zur vernetzten Plattform geworden. Alle Integrationen sind read-only live, die Projektdaten kommen aus Airtable, und die Widget-Boards sind frei umsortierbar.

### Google Workspace (S1–S4, S6)
- **OAuth/PKCE-Fundament** (S1): Loopback-Redirect, Keychain-Token-Store, Settings-Tab mit Verbinden/Trennen. Kein `client_secret` nötig (Desktop-App-Flow).
- **Drive-Widget** (S2): read-only Metadaten via `GoogleDriveClient`, Klick öffnet im Browser.
- **Token-Refresh** (S3): `GoogleAccessTokenProvider` als zentrale Stelle, die alle Clients nutzen. Automatische Erneuerung, Unit-Tests mit Fake-Refresher.
- **Kalender-Widget** (S3): `GoogleCalendarClient`, `calendarQuery` als Freitext-Projektfilter.
- **Kontakte-Widget** (S4): `GoogleContactsClient`, People API `searchContacts`, `contactsQuery`.
- **Mail-Widget** (S6): `GoogleGmailClient` (gmail.readonly), `messages.list` + individuelle `messages.get`, `mailQuery` als Projektfilter.

### Clockodo (S5)
- API-Key + E-Mail Auth (kein OAuth), heutige Zeiteinträge gruppiert nach Projekt/Kunde.
- ZEITEN-Regel eingehalten: nur Anzeige, keine Buchung.
- Settings-Sektion mit SecureField für API-Key.

### Drag & Drop (S7)
- Home- und Projekt-Boards frei umsortierbar per Drag & Drop.
- SwiftUI `.draggable` + `.dropDestination`, persistiert via `WidgetBoardStore.move()`.
- Visueller Drop-Highlight (Ocker-Rahmen).

### Airtable-Sync (S8)
- `AirtableClient`: REST API v0, automatische Paginierung (100er Seiten + offset).
- `AirtableRegistry.sync()`: echte Implementierung, ersetzt den Akt-0-Stub.
- PAT im Keychain, Settings-Sektion mit Base-ID + PAT + "Jetzt synchronisieren"-Button.
- Deutsches Feld-Mapping: `Kundennummer`, `Projektnummer`, `Titel`, `Art`, etc.

## Architektur-Muster (durchgängig)

| Muster | Wo |
|---|---|
| Protocol + Fake für Testbarkeit | `GoogleDriveFetching`, `ClockodoFetching`, `AirtableFetching`, etc. |
| Statische Parse-Methoden | `Client.parseX(from:)` — kein Netzwerk/Keychain nötig im Test |
| `@Observable` Auth-Service | `GoogleAuthService`, `ClockodoAuthService`, `AirtableAuthService` |
| Keychain via `KeychainStore` | Google-Tokens, Clockodo-Keys, Airtable-PAT — alles über denselben generischen Wrapper |
| `ProjectLinks.xxxQuery` | Freitext-Suche je Projekt: `calendarQuery`, `contactsQuery`, `mailQuery` |
| Alle Renderstates | loading / content / empty / permissionRequired / offline / error — in jedem Widget |

## Zahlen

- **8 Commits** (S1–S8)
- **73 Tests grün** (37 neue in Akt 3)
- **8 Widget-Arten** im Projekt-Board: drive, tasks, contacts, cash, calendar, notes, mail, assistant
- **5 Home-Widgets**: focus, projectFaves, clockodo, recentActivity, notes
- **3 externe Integrationen**: Google Workspace, Clockodo, Airtable
- **3 Settings-Sektionen**: Google, Clockodo, Airtable

## Detail-Handoffs

Jeder Schritt hat sein eigenes Handoff mit Architektur-Entscheidungen und offenen Punkten:
- [S1](HANDOFF_AKT3_S1.md) — Google-OAuth-Fundament
- [S2](HANDOFF_AKT3_S2.md) — Drive-Widget
- [S3](HANDOFF_AKT3_S3.md) — Token-Refresh + Kalender-Widget
- [S4](HANDOFF_AKT3_S4.md) — Kontakte-Widget
- [S5](HANDOFF_AKT3_S5.md) — Clockodo-Widget
- [S6](HANDOFF_AKT3_S6.md) — Mail-Widget
- [S7](HANDOFF_AKT3_S7.md) — Drag & Drop
- [S8](HANDOFF_AKT3_S8.md) — Airtable-Sync

## Offene Punkte (für Akt 4+)

1. **Erster Live-Test aller Integrationen** — Kein Client wurde bisher gegen die echte API getestet. Feldnamen, Auth-Flows und Antwortformate könnten im Live-Betrieb Überraschungen bringen.
2. **Token-Refresh unter echtem Ablauf** — Nur per Unit-Test mit Fake abgedeckt. Erster echter Ablauf nach ~1h noch unbeobachtet.
3. **Gmail N+1 Requests** — 11 HTTP-Calls für 10 Mails. Batch API evaluieren falls spürbar langsam.
4. **Laufende Clockodo-Buchungen** — `duration: null` wird als 0h dargestellt. Live-Timer möglich.
5. **Kein Auto-Sync** — Airtable-Sync nur manuell. Periodisch oder bei App-Start wäre sinnvoll.
6. **`WidgetBoardView` Cleanup** — Die alte stateless View in MykilosWidgets pflegt einen redundanten Widget-Dispatch.

## Nächster Schritt — Akt 4: Der Assistent erwacht
- Assistent-Widget live: Tool-Use, proaktiver ein-Satz-Dolmetscher.
- Das Widget, das aus allen Quellen synthesiert und dem Nutzer sagt, was jetzt wichtig ist.
