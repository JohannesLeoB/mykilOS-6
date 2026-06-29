# Handoff — Akt 3, Schritt 2: Drive-Widget live

**Datum:** 2026-06-25 · **Basis:** Akt 3, Schritt 1 (Commits `a14ac6b`, `76add48`) · **Status:** Build + Tests grün, echter Drive-Fetch manuell zu bestätigen.

## Was in diesem Commit liegt

### `Sources/MykilosServices/Google/GoogleDriveClient.swift` (neu)
- `GoogleDriveFile` (Identifiable, Equatable, Sendable): `id, name, mimeType,
  modifiedAt: Date?, webViewLink: String?`, plus `iconName` (SF-Symbol nach
  MIME-Type: Ordner/PDF/Tabelle/Dokument/Bild/Sonstiges).
- `GoogleDriveFetching`-Protokoll für Testbarkeit (gleiches Muster wie
  `GoogleTokenStoring` aus Schritt 1).
- `GoogleDriveClient` — liest das Access-Token aus `GoogleTokenStoring`
  (Default: `KeychainGoogleTokenStore()`), ruft `GET .../drive/v3/files` mit
  `q='<folderID>' in parents and trashed=false`. Kein Token →
  `GoogleDriveError.notConnected`, kein Crash, kein stiller Fallback.
- URL-Aufbau (`buildListFolderURL`) und JSON-Decoding (`parseFiles`) sind als
  reine, statische Funktionen ausgelagert — testbar ohne Netzwerk/Keychain,
  genau wie `GoogleOAuthPKCEService.buildAuthorizationRequest` in Schritt 1.

### `Sources/MykilosWidgets/Kinds/DriveWidget.swift` (überarbeitet)
- `init(projectID:driveFolderID: String?)` statt nur `projectID`.
- `DriveFolderLoader` (privat, `@MainActor @Observable`) lädt pro Widget-
  Instanz — kein geteilter Store nötig, da Drive-Daten reine Lesefetches sind,
  kein Speichern-Vertrag wie bei `NoteStore`/`WidgetBoardStore`.
- Demo-Mosaik (Farbkacheln) ersetzt durch eine echte Dateiliste: Icon, Name,
  relative Änderungszeit; Tap öffnet `webViewLink` im Browser.
- Renderstate-Mapping: kein `driveFolderID` ODER leerer Ordner → `.empty`,
  `GoogleDriveError.notConnected` → `.permissionRequired` (mit "Erneut
  versuchen"-Button), sonstiger Fehler → `.error(String)`, sonst `.content`
  mit echter Anzahl in der Quellenzeile (`"DRIVE · {n} DATEIEN"`).

### Verdrahtung
- `ProjectDetailView.swift`: `ProjectWidgetBoardView` bekommt
  `driveFolderID: project.links.driveFolderID`, reicht es an `DriveWidget` weiter.
- `WidgetBoardView.swift` (öffentlich, seit Akt 2 unbenutzt) bekommt
  `driveFolderID: nil` zur Kompilierbarkeit — die Tatsache, dass diese Datei
  toter Code ist, ist als eigener Cleanup-Task geflaggt (nicht Teil dieser PR).

## Tests (`Tests/MykilosServicesTests/GoogleDriveClientTests.swift`, 5 neue)
1. URL-Aufbau enthält korrekten `q`- und `fields`-Parameter.
2. JSON → `[GoogleDriveFile]`-Decoding, inkl. fehlendem `webViewLink`/`modifiedTime`.
3. Kaputtes JSON → `GoogleDriveError.decodingFailed`.
4. Kein Token im Store → `GoogleDriveError.notConnected` (wiederverwendet
   `InMemoryGoogleTokenStore` aus `GoogleOAuthTests.swift`).
5. `iconName`-Mapping für alle gängigen MIME-Types.

**Bewusste Lücke** (wie in Schritt 1): kein echter Netzwerk-Fetch im
automatisierten Test. `DriveFolderLoader`s Renderstate-Logik (SwiftUI-Glue)
ist nicht unit-getestet, sondern manuell über `./script/build_and_run.sh`
zu verifizieren — gleiche Grenze wie der Rest der Widget-Schicht in diesem
Projekt.

## Build & Tests
- `swift build` — clean (nur die bekannte Pre-Akt-3-Warnung in `NotesWidget`).
- `swift test` — 24/24 grün (19 aus Akt 3 S1 + 5 neu).
- `./script/build_and_run.sh` — App startet ohne Crash.

## Manuell zu verifizieren (nicht automatisierbar)
1. In den Einstellungen verbinden (Akt 3, Schritt 1).
2. Ein Projekt mit echtem `driveFolderID` (Airtable-Link) öffnen → Drive-
   Widget sollte echte Dateien zeigen.
3. Projekt ohne `driveFolderID` (z. B. `DemoSeed`-Projekte haben aktuell nur
   Mock-IDs) → Widget zeigt `.empty` ("Noch leer"), nicht `.error` — bestätigt,
   dass eine ungültige/nicht existierende Ordner-ID von Google mit einer
   leeren Dateiliste beantwortet wird, nicht mit einem Fehler. Falls Google
   stattdessen 404 zurückgibt: dann zeigt das Widget `.error("httpError(404)")` —
   in diesem Fall müsste `DemoSeed` echte Test-Ordner-IDs bekommen, um den
   Pfad sauber zu zeigen (siehe "Bekannte offene Punkte" unten).

## Bekannte offene Punkte
- `DemoSeed.swift` verlinkt aktuell vermutlich Mock-`driveFolderID`-Werte
  (nicht-existierende IDs) — das Drive-Widget zeigt dafür entweder `.empty`
  oder `.error`, je nachdem wie Google auf eine fremde/falsche Ordner-ID
  antwortet. Für eine überzeugende Demo bräuchte es echte, für den
  verbundenen Account zugängliche Test-Ordner-IDs.
- Kein Token-Refresh (siehe Schritt 1) — wird jetzt mit echten Live-Calls
  relevant, nicht mehr nur theoretisch.
- `Sources/MykilosWidgets/WidgetBoardView.swift` ist toter Code (siehe oben) —
  als Task geflaggt, nicht in dieser PR entfernt.

## Nächster Schritt — Akt 3, Schritt 3
Kalender + Mail read-only, gleiches Muster wie `GoogleDriveClient`
(`GoogleCalendarClient`/`GmailClient`, jeweils mit `buildXURL`/`parseX` als
testbaren reinen Bausteinen). Vor dem Start: Token-Refresh-Lücke aus Schritt 1
einplanen, da jetzt zwei weitere Live-API-Aufrufer betroffen wären.
