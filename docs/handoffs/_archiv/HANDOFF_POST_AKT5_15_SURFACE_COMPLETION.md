# Handoff: App-Vollständigkeit + Phase 3 CalendarActionCard
## Post-Akt 5, Aufgaben 15–21 · Release 6.3.0

---

## Was diese Session gebracht hat

Die App ist jetzt **vollständig**: alle Sidebar-Module und alle Projekt-Tabs die vorher „in Vorbereitung" zeigten sind live. Zusätzlich ist **Phase 3 des Assistenten** (Kalender-Aktionskarte) implementiert und mehrere UX-Polituren wurden durchgeführt.

---

## Aufgaben im Detail

### Aufgabe 15 — Projekt-Assistent-Tab
- `ProjectDetailView` hat jetzt `case .chat = "Assistent"` als Tab
- `AssistantChatView` wird mit `scope: .project(project.projectNumber)` eingebettet — vollständig scoped, eigener Verlauf je Projekt
- `ProjectTab.isFullHeight: Bool` — Chat-Tab bekommt die volle Fensterhöhe (kein äußerer ScrollView), alle anderen Tabs bleiben gescrollt
- Header (Hero + Tabs + Divider) ist fixed; `SaveStateBar` nur für nicht-Chat-Tabs

### Aufgabe 16 — Profil-Sektion in Einstellungen
- `SettingsView` hat jetzt eine erste Sektion mit Name + Rolle direkt editierbar (TextField, Speichern-Button)
- Kein Wizard-Umweg mehr für Profil-Änderungen

### Aufgabe 17 — Globales Angebote-Modul
- `GlobalOffersView.swift` — 2-Spalten: linke Projektliste (220 px, nur Projekte mit Drive-Ordner), rechts `OffersTabView` für das gewählte Projekt
- Sidebar-Modul `.offers` fällt nicht mehr auf `ComingSoonView` zurück

### Aufgabe 18 — Dateien-Tab + Marken & Daten
- `FilesTabView.swift` — alle Dateien im verlinkten Drive-Ordner, nach Änderungszeit sortiert; Refresh-Button im Content-State, Retry bei Fehler; Generationstoken-Pattern für Race-Freiheit
- `BrandsView.swift` — Integrations-Dashboard: 6 `IntegrationCard`s in LazyVGrid-3-Spalten; Status-Mapping aller 6 Quellen → `ConnectionDisplayState`
- Beide Sidebar-Module jetzt live

### Aufgabe 19 — UX-Politur
- **TodayView**: personalisierte Begrüßung (Name aus `UserProfile`), Signal-Strip (letzte 5 Sitzungs-Signale als `SignalPill`)
- **Navigation**: `Cmd+1..6` Keyboard-Shortcuts über `FocusedValues`/`@FocusedBinding`-Pattern
- **Chat**: projekt-spezifische Beispielfragen im Empty-State (Projekt-Titel interpoliert)
- **Sidebar-Profil-Button**: navigiert zu Settings wenn Profil vollständig, sonst Wizard
- **Files-Tab**: Refresh-Button (arrow.clockwise) im Content-State

### Aufgabe 20 — Phase 3: CalendarActionCard
Wenn Claude einen Termin empfiehlt, erscheint eine klickbare Aktionskarte mit Google-Kalender-Link. Kein API-Write — nur URL-Generierung → Browser.

**Neue Typen:**
- `ChatContentBlock.calendarAction(url: String, label: String)` — Codable, nie an die Anthropic-API gesendet
- `ToolRunResult.actionURL: String?` — optionaler URL aus einem Tool-Ergebnis

**Neue Klasse:**
- `SuggestCalendarEventTool` in `AssistantTool.swift` — output-only, baut Google Calendar `eventedit`-URL aus `title`/`date`/`notes`; kein Netzwerk-Call, kein Google-API-Zugriff

**Engine:**
- `ConversationEngine.runLoop` — injiziert `.calendarAction`-Block wenn `result.actionURL != nil`
- `activityLabel` für `suggest_calendar_event`: `"Kalender-Link generiert"`
- `ClaudeChatClient.wire(from:)` — `.calendarAction` in der Wire-Switch als `break` (wie `toolActivity`)

**UI:**
- `CalendarActionCard` in `AssistantChatView.swift` — Sage-Button-Style, people-Farbe, maxWidth 360, öffnet URL via `NSWorkspace.shared.open(_:)`
- `ChatMessageBubble` rendert alle `calendarActions` nach der Antwort-Bubble

**Grounding:**
- `AssistantGrounding.systemPrompt()` nennt `suggest_calendar_event` explizit wenn `toolsEnabled: true`, damit Claude das Tool aktiv nutzt

**Registry:**
- `AssistantToolRegistry.standard()` enthält jetzt 3 Tools: `search_gmail`, `list_calendar_events`, `suggest_calendar_event`

### Aufgabe 21 — Signal-Badges in Galerie + Beispielfragen
- `ProjectCard` liest `@Environment(StudioContext.self)` — zeigt Signal-Count-Badge oben links wenn `> 0`; Ocker für normale Signale, Rot für kritische (Deadline, Budget ≥90%)
- Beispielfragen mit `toolsEnabled: true` zeigen jetzt Kalender-Termin-Beispiele als erste Frage → Discoverability für `suggest_calendar_event`

---

## Teststand

**169 Tests grün** (`swift test`):
- `calendarSuggestionMitTitelUndDatum` — URL enthält korrekten Titel + normalisierten Datums-String
- `calendarSuggestionOhneDatum` — URL ohne `dates=`-Parameter
- `calendarSuggestionMitNotizen` — URL mit `details=`-Parameter
- `calendarSuggestionOhneTitelIstFehler` — `isError: true`, kein `actionURL`
- `calendarSuggestionInRegistry` — Standard-Registry kann Tool aufrufen
- `calendarToolInjiziertAktionsBlock` — Engine speichert `.calendarAction`-Block wenn Tool `actionURL` zurückgibt
- `standardRegistryHatErwarteteTools` — Whitelist jetzt `["list_calendar_events", "search_gmail", "suggest_calendar_event"]`
- `promptMitToolsEnabledNenntErlaubteTools` — Grounding erwähnt `suggest_calendar_event`

---

## Architektur-Invarianten

- `.calendarAction`-Block wird **NIE** an die Anthropic-API gesendet (`ClaudeChatClient.wire(from:)` überspringt ihn wie `toolActivity`)
- `SuggestCalendarEventTool` macht **keinen** Google-API-Call — vollständig offline lauffähig
- `CalendarActionCard` öffnet URL via `NSWorkspace.shared.open(_:)` — kein In-App-WebView, kein Schreiben in Google Calendar
- Sevdesk bleibt vollständig aus der Tool-Whitelist ausgeschlossen (NO-GO)

---

## Offene Punkte

1. **Google OAuth live verifizieren** — Die Google-Integration ist vollständig implementiert, aber der erste echte OAuth-Connect-Flow (PKCE + Code-Exchange) ist noch nicht mit einem echten Account live getestet. Manueller Beta-Check.
2. **Streaming bei toolsEnabled=true** — Wenn Tools aktiviert sind, nutzt die Engine `respond()` statt `streamText()` für den Tool-Loop. Wenn Claude keine Tools aufruft, kommt die Antwort trotzdem non-streaming. Für V1 akzeptabel.
3. **CalendarActionCard-Persistenz** — `.calendarAction`-Blocks sind Codable und überleben Neustarts — beim App-Neustart erscheinen die Karten noch. Korrekt und gewollt (Link ist permanent gültig).

---

## Version

`6.3.0` · Commits in `sprint/shared-drive-widget-oauth`
