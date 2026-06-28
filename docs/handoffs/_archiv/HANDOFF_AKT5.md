# Handoff — Akt 5: Politur, Dark Mode, DMG

**Status:** abgeschlossen

---

## Was passiert ist

mykilOS 6 ist beta-ready: Dark Mode funktioniert, Placeholder sind ersetzt, und die App lässt sich als DMG verpacken.

### Dark Mode

`MykColor` nutzt jetzt `NSColor(name:dynamicProvider:)` — jede Farbe hat einen Light- und Dark-Hex-Wert. Die Palette invertiert sich sauber:

| Token | Light | Dark | Logik |
|---|---|---|---|
| paper | `#FAF8F3` warm-weiß | `#1A1814` tiefes Dunkel | Hintergrund ↔ Tinte tauschen |
| ink | `#1A1814` | `#F0EDE6` | |
| card | `#FFFFFF` | `#2A2721` | Karten leicht heller als paper |
| Akzente | Original-Werte | Leicht aufgehellt | Lesbarkeit auf dunklem Grund |

Kein Asset-Katalog nötig — alles in `Tokens.swift`. Die gesamte App adaptiert automatisch über das System-Erscheinungsbild.

### Politur

- **AssistantPlaceholderView → AssistantPageView** — Der Sidebar-Tab "Assistent" zeigt jetzt das echte AssistantWidget (projektübergreifend, `projectID: "home"`).
- **AssistantWidget** — Alle hardcoded `.white`-Referenzen durch `MykColor.paper.color` ersetzt. Gradient nutzt `MykColor.ink`/`.inkSoft` statt fester Hex-Werte.

### DMG-Script

`script/create_dmg.sh` — Baut das App-Bundle (falls nötig) und verpackt es als komprimierte DMG (`UDZO`-Format). Output: `dist/mykilOS-6.dmg`.

### Geänderte Dateien

| Datei | Was |
|---|---|
| `Sources/MykilosDesign/Tokens.swift` | Adaptive Light/Dark Farben via `NSColor(name:dynamicProvider:)` |
| `Sources/MykilosWidgets/Kinds/AssistantWidget.swift` | `.white` → `MykColor.paper.color`, Gradient adaptiv |
| `Sources/MykilosApp/MykilOS6App.swift` | Placeholder → echte `AssistantPageView` |
| `script/create_dmg.sh` | DMG-Build-Script (neu) |

---

## Tests

80 Tests grün. Keine neuen Tests — Dark Mode ist rein visuell, DMG-Script ist Build-Tooling.

---

## Offene Punkte für post-Beta

- **App-Icon** — Nutzt aktuell das macOS-Default-Icon. Ein eigenes Asset (`AppIcon.icns`) muss in den Resources-Ordner des Bundles.
- **About-Fenster** — Kein eigenes About-Fenster mit Versionsnummer.
- **Notarization** — Für Distribution außerhalb des App Stores müsste die App notarisiert werden (`xcrun notarytool`).
- **ProjectHeroView / ProjectCard** — Nutzen weiterhin hardcoded `.white` für Text auf dunklen Gradient-Bannern. Das ist korrekt (der Banner-Hintergrund ist immer dunkel), aber könnte bei extremen Dark-Mode-Kontrasten angepasst werden.
