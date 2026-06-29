# Handoff — Akt 3, Schritt 1: Google-OAuth-Fundament

**Datum:** 2026-06-25 · **Basis:** Akt 2 (Commit `553414b`) · **Status:** Build + Tests grün, OAuth manuell zu bestätigen.

## Was in diesem Commit liegt

### `Sources/MykilosServices/Google/` — neues Modul
Portiert aus `mykilOS 5.5/Sources/Integrations/Google/Auth/`, auf reine
Readonly-Scopes verschlankt (V6 plant keine Schreibzugriffe) und an die
strengere V6-Schichtgrenze angepasst (kein globaler Service-Locator-Aufruf
aus dem Netzwerk-Code, siehe unten).

- **`GoogleOAuthModels.swift`** — `GoogleOAuthScope` (4 Readonly-Scopes:
  Drive-Metadata, Calendar-Events, Gmail, Contacts), `GoogleTokens`
  (accessToken/refreshToken?/expiresAt), `GoogleOAuthError`.
- **`GoogleOAuthPKCEService.swift`** — PKCE-Challenge (SecRandomCopyBytes +
  CryptoKit SHA256, base64url), Authorization-URL-Builder, Code-Exchange
  (POST `oauth2.googleapis.com/token`), Redirect-Parser mit State-Validierung.
- **`GoogleOAuthLoopbackRedirectServer.swift`** — NWListener auf
  `127.0.0.1:0`. **Unterschied zu V5:** ruft keinen globalen Singleton-Service
  auf, sondern löst eine `awaitRedirect() async throws -> URL`-Continuation
  auf, die der Aufrufer (`GoogleAuthService`) besitzt. Kein URL-Scheme/
  Info.plist nötig — der Browser macht einen normalen HTTP-GET an localhost,
  den der im Prozess laufende Listener direkt empfängt.
- **`KeychainStore.swift`** — generischer Keychain-Wrapper mit dem
  Ad-hoc-Signing-Workaround aus V5 (`SecAccessCreate` mit leerer
  Application-Liste = "allow all", verhindert den wiederholten Keychain-Prompt
  bei jedem Rebuild). Generalisiert auf `(service, account) → String`, damit
  ein künftiger Airtable-PAT (Akt 3, Schritt 5) denselben Code nutzen kann.
- **`KeychainGoogleTokenStore.swift`** — `GoogleTokenStoring`-Protokoll +
  Keychain-Implementierung. Tokens werden als JSON serialisiert; Datum über
  `timeIntervalSinceReferenceDate` (siehe Akt-2-Lektion: `.iso8601` und
  `.secondsSince1970` verlieren beide Präzision über die Epoch-Konvertierung).
- **`GoogleAuthService.swift`** — `@MainActor @Observable` Orchestrator.
  `status: GoogleConnectionStatus`. `startAuthorization(clientID:)` baut PKCE,
  startet den Loopback-Server, öffnet die Konsens-URL im System-Browser
  (`NSWorkspace.shared.open`), wartet auf den Redirect, tauscht den Code gegen
  Tokens, speichert sie im Keychain. `disconnect()` leert den Keychain-Eintrag.

### `Sources/MykilosKit/Domain/GoogleConnectionStatus.swift`
`disconnected/connecting/connected/error(String)` — reiner Status, analog zu
`SaveState`, damit die UI-Schicht ihn rendern kann ohne `MykilosServices` zu
kennen.

### `Sources/MykilosApp/Settings/SettingsView.swift`
Ersetzt `ComingSoonView` für den `.settings`-Tab. Textfeld für die
OAuth-Client-ID (wird in Keychain gespeichert, nie im Code/Repo),
Status-Badge, "Verbinden"/"Trennen"-Button, Hinweistext "nur Lesezugriff".

### `AppState`
Neues `public let googleAuth: GoogleAuthService`, instanziiert im Init
(Standard-Konstruktor nutzt `KeychainGoogleTokenStore()` + den
Loopback-Singleton `.shared`).

## Tests (`Tests/MykilosServicesTests/GoogleOAuthTests.swift`, 7 neue)

Kein echtes Keychain/Netzwerk im automatisierten Lauf (Sandbox würde an
OS-Prompts scheitern) — Muster wie `GRDBDatabase.inMemory()`:
- PKCE-Format (Base64url, Länge, Challenge = SHA256(Verifier)), zwei
  Challenges sind nie gleich.
- Authorization-URL: alle Pflicht-Query-Parameter korrekt
  (`code_challenge_method=S256`, `access_type=offline`, `prompt=consent`, `state`).
- Redirect-Parser: korrekter Code bei passendem State, `nil` bei Mismatch
  oder fehlendem Code.
- `GoogleAuthService`-Statusübergänge mit `InMemoryGoogleTokenStore`
  (Test-Double): Status `.connected` wenn beim Start schon Tokens vorliegen,
  `disconnect()` leert Status + Store, leere Client-ID wirft
  `.missingClientID` und setzt `.error`.

**Bewusste Lücke:** Die echte `KeychainGoogleTokenStore`-Implementierung (echtes
Keychain) und der komplette Browser-Redirect-Roundtrip sind nicht automatisiert
getestet — beides braucht einen registrierten Google-Cloud-OAuth-Client und
einen interaktiven Login, den kein Sandbox-Testlauf abbilden kann. Wird manuell
verifiziert (siehe unten), dokumentiert als akzeptierte Lücke — gleiches Muster
wie der bestehende Kommentar zu `GRDBDatabase.inMemory()` aus Akt 2.

## Build & Tests
- `swift build` — clean, nur die bekannte Pre-Akt-3-Warnung (NotesWidget
  Actor-Isolation) plus erwartete Deprecation-Warnungen für die Legacy-
  `SecAccess`-API (kein nicht-deprecated Ersatz für "allow all applications"
  auf macOS Keychain-Items vorhanden — identisch zu V5s eigenem Workaround).
- `swift test` — 19/19 grün (12 aus Akt 2 + 7 neu).
- `swift run` — startet ohne Crash.

## Manuell zu verifizieren (nicht automatisierbar)
1. In Google Cloud Console ein OAuth-Client vom Typ **"Desktop App"** anlegen.
2. `swift run` → Einstellungen → Client-ID eintragen → "Verbinden".
3. Browser öffnet sich mit der Google-Consent-Seite → nach Login Redirect auf
   `127.0.0.1:<port>` → App zeigt "VERBUNDEN".
4. Falls Google `invalid_client` meldet: ggf. braucht der Desktop-App-Client
   doch ein `client_secret` im Token-Exchange (siehe "Bekannte offene Punkte"
   in `CLAUDE.md`) — dann `clientSecret`-Parameter in
   `GoogleOAuthPKCEService` nachziehen (war in V5 bereits optional vorgesehen).

## Nächster Schritt — Akt 3, Schritt 2
Drive-Ordner-Widget auf echte Drive-API umstellen (read-only), aufbauend auf
`GoogleAuthService`/`KeychainGoogleTokenStore`. Pattern aus V5
(`GoogleDriveHTTPReadOnlyClient`) lässt sich analog portieren — Token kommt
dann aus `KeychainGoogleTokenStore().load()?.accessToken` statt aus einem
eigenen Provider-Protokoll, da V6 (noch) keinen automatischen Refresh-on-401
braucht, bis ein echtes Token abläuft (siehe "Bekannte offene Punkte").
