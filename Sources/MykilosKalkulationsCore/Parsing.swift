import Foundation

public enum GermanNumberParser {
    public static func decimal(_ input: String) -> Decimal? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let withoutCurrency = trimmed
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "EUR", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized: String
        if withoutCurrency.contains(",") {
            normalized = withoutCurrency
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: ".")
        } else {
            normalized = withoutCurrency
        }
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    public static func double(_ input: String) -> Double? {
        guard let decimal = decimal(input) else { return nil }
        return NSDecimalNumber(decimal: decimal).doubleValue
    }

    public static func integerWord(_ input: String) -> Int? {
        let lower = input.lowercased()
        let words: [String: Int] = [
            "ein": 1, "eine": 1, "einen": 1, "eins": 1, "zwei": 2, "drei": 3,
            "vier": 4, "fünf": 5, "fuenf": 5, "sechs": 6, "sieben": 7,
            "acht": 8, "neun": 9, "zehn": 10, "elf": 11, "zwölf": 12,
            "zwoelf": 12, "dreizehn": 13, "vierzehn": 14, "fünfzehn": 15,
            "fuenfzehn": 15
        ]
        return words[lower]
    }
}

public final class EstimateRequestParser {
    public init() {}

    public func parse(_ text: String) -> EstimateRequest {
        let lower = text.lowercased()
        let materials = parseMaterials(lower)
        var scope = parseScope(lower)
        var components: [EstimateComponent] = []
        let drawerCount = parseDrawerCount(lower)

        if let run = parseRun(lower) {
            components.append(EstimateComponent(type: .baseCabinetRun, quantity: run, unit: "lfm", drawerCount: drawerCount, materials: materials, componentClass: .kitchenRun))
        } else if let width = parseBaseUnitWidth(lower) {
            components.append(EstimateComponent(type: .baseCabinetRun, quantity: 1, unit: "piece", widthM: width, drawerCount: drawerCount, materials: materials, componentClass: .baseUnit))
        } else if lower.contains("zeile") || lower.contains("rückzeile") || lower.contains("rueckzeile") || lower.contains("unterschränke") || lower.contains("unterschraenke") {
            // Laufmeter fehlt: NICHT auf 1 lfm degradieren (das kollabierte die ganze Küche
            // zu einem ~820-€-Schrank). Stattdessen mit einem typischen Default ansetzen und
            // klar als geschätzt markieren, damit das Preisband entsprechend breit wird.
            components.append(EstimateComponent(type: .baseCabinetRun, quantity: 4.0, unit: "lfm", drawerCount: drawerCount, materials: materials, scopeNotes: ["size_estimated", "Laufmeter fehlt; als ~4 lfm geschätzt — bitte präzisieren."], componentClass: .kitchenRun))
        }

        if lower.contains("gesamtküche") || lower.contains("gesamtkuche") || lower.contains("gesamtkueche") || lower.contains("einbauküche") || lower.contains("einbaukueche") {
            components.append(EstimateComponent(type: .aggregateKitchen, quantity: 1, unit: "scope", materials: materials, componentClass: .aggregateKitchen))
        }

        if lower.contains("insel") || lower.contains("küchenblock") || lower.contains("kuechenblock") {
            let dimensions = parseDimension(after: "insel", in: lower) ?? parseAnyDimension(in: lower)
            let quantity = dimensions?.width ?? 1
            let footprint = (dimensions?.width ?? 0) * (dimensions?.height ?? 0)
            components.append(EstimateComponent(type: .island, quantity: footprint > 0 ? footprint : quantity, unit: footprint > 0 ? "m2" : "lfm", widthM: dimensions?.width, heightM: dimensions?.height, depthM: dimensions?.depth, materials: materials, componentClass: .island))
        }

        // Eigenständige Hochschrank-/Schrank-Einheiten (separat von der Zeile bepreisen).
        // Achtung: KEIN "hs " (kollidiert mit "sechs"). Eine generische "Hochschrankzeile"
        // ist Teil der Küchenzeile und erzeugt NUR dann einen eigenen Block, wenn keine
        // Zeile erkannt wurde — sonst wäre es eine Doppelzählung.
        let standaloneTall = lower.contains("treppenschrank")
            || lower.contains("geräteschrank") || lower.contains("geraeteschrank")
            || lower.contains("schrankblock") || lower.contains("schrank block")
            || lower.contains("einbauschrank")
            || lower.contains("nischen-hochschrank") || lower.contains("nischenhochschrank")
        let genericTall = lower.contains("hochschrank") || lower.contains("hochschr") || lower.contains("hochschränke")
        let hasRun = components.contains { $0.componentClass == .kitchenRun }
        let hasIsland = components.contains { $0.componentClass == .island }
        // Eigene Dimension NUR, wenn keine Insel bereits eine Dimension beansprucht — sonst
        // würde der Block die Inselmaße "klauen" (Number-Race). parseDimension(after:) wird
        // bewusst nicht genutzt: es greift Maße, die hinter dem Stichwort zur Insel gehören.
        let dimensions = hasIsland ? nil : parseAnyDimension(in: lower)
        let hasExplicitTallDim = dimensions != nil
        // Block, wenn eigenständige Einheit ODER generischer Hochschrank, der nicht schon
        // Teil der Zeile ist (= keine Zeile vorhanden ODER eigene Maßangabe genannt).
        // Niemals die Laufmeter der Zeile als Breite erben (das war der +30k-Doppelzähl-Bug).
        if standaloneTall || (genericTall && (!hasRun || hasExplicitTallDim)) {
            let width = dimensions?.width
            let estimated = width == nil
            components.append(EstimateComponent(
                type: .tallCabinetBlock,
                quantity: width ?? 1.0,
                unit: "lfm",
                widthM: width,
                heightM: dimensions?.height,
                depthM: dimensions?.depth,
                materials: materials,
                scopeNotes: estimated ? ["size_estimated", "Hochschrank-Breite unbekannt; konservativ als 1 lfm angesetzt."] : [],
                componentClass: .tallCabinetBlock))
        }

        if lower.contains("hängeschrank") || lower.contains("haengeschrank") {
            components.append(EstimateComponent(type: .wallCabinets, quantity: parseRun(lower) ?? 1, unit: "lfm", materials: materials))
        }

        // Arbeitsplatten-Trigger: zusätzlich zum Klartext erkennt das Lexikon APL/AP,
        // Abdeckplatte, Spülenplatte sowie Stein-/Mineral-Marken (Silestone, Dekton,
        // Hi-Macs, Corian, Quarzit …). Scope-Gate bleibt: "ohne AP/Stein" unterdrückt.
        if lower.contains("arbeitsplatte") || lower.contains("waschtischplatte") || lower.contains("fensterbank") || lower.contains("ap ") || lower.contains("stein") || lower.contains("marmor") || lower.contains("granit") || lower.contains("dekton") || MaterialLexicon.shared.mentionsWorktopSurface(in: lower) {
            if !scope.excludesWorktop && !scope.excludesStone {
                let area = parseArea(lower) ?? 1
                components.append(EstimateComponent(type: .stoneCountertop, quantity: area, unit: area == 1 ? "scope" : "m2", materials: materials, componentClass: .worktopSurface))
            }
        }

        if lower.contains("lieferung") && !components.contains(where: { $0.type == .delivery }) {
            components.append(EstimateComponent(type: .delivery, quantity: 1, unit: "scope", materials: []))
        }

        if lower.contains("montage") && !components.contains(where: { $0.type == .installation }) {
            components.append(EstimateComponent(type: .installation, quantity: 1, unit: "scope", materials: []))
        }

        if components.isEmpty {
            components.append(EstimateComponent(type: .other, quantity: 1, unit: "scope", materials: materials))
            scope.notes.append("Freitext konnte keinem Standardbauteil sicher zugeordnet werden.")
        }

        components = components.map(normalizeImplausibleSize)
        return EstimateRequest(rawText: text, components: components, materials: materials, scope: scope)
    }

    /// Kappt unrealistische Größen (z. B. Tippfehler „100 x 50 m", „999 laufmeter") auf eine
    /// plausible Domänengrenze und markiert sie als `size_implausible`. So entsteht statt eines
    /// selbstsicheren Millionenbetrags eine gekappte, breit-bandige, niedrig-konfidente Schätzung
    /// mit klarer Warnung. Allgemeine Grenzen — kein Fit auf einzelne Beispiele.
    private func normalizeImplausibleSize(_ component: EstimateComponent) -> EstimateComponent {
        let cap: Double
        switch component.componentClass {
        case .kitchenRun, .tallCabinetBlock: cap = 20          // lfm
        case .island: cap = component.unit == "m2" ? 12 : 8    // m² bzw. lfm
        case .worktopSurface: cap = 30                          // m²
        case .baseUnit where component.unit == "piece" && component.widthM != nil: cap = 1.5  // m Breite
        default: return component
        }
        let measured = (component.componentClass == .baseUnit ? (component.widthM ?? 0) : component.quantity)
        guard measured > cap, measured > 0 else { return component }
        var capped = component
        if component.componentClass == .baseUnit { capped.widthM = cap } else { capped.quantity = cap }
        capped.scopeNotes = component.scopeNotes + [
            "size_implausible",
            "Unrealistische Größe (\(formatMeasure(measured)) \(component.unit)); auf \(formatMeasure(cap)) gekappt — bitte prüfen."
        ]
        return capped
    }

    private func formatMeasure(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }

    private func parseScope(_ lower: String) -> ScopeFlags {
        var scope = ScopeFlags()
        scope.includesDelivery = lower.contains("lieferung") && !lower.contains("ohne lieferung")
        scope.includesInstallation = lower.contains("montage") && !lower.contains("ohne montage")
        scope.excludesAppliances = lower.contains("ohne geräte") || lower.contains("ohne geraete") || lower.contains("geräte bauseits") || lower.contains("geraete bauseits") || lower.contains("ohne elektro") || lower.contains("ohne anschlüsse") || lower.contains("ohne anschluesse") || lower.contains("/geräte") || lower.contains("/geraete")
        scope.excludesWorktop = lower.contains("ohne arbeitsplatte") || lower.contains("ohne ap") || lower.contains("ohne ap/")
        scope.excludesStone = lower.contains("ohne stein") || lower.contains("ohne dekton")
        if scope.excludesAppliances { scope.notes.append("Geräte ausgeschlossen.") }
        if scope.excludesWorktop { scope.notes.append("Arbeitsplatte ausgeschlossen.") }
        if scope.excludesStone { scope.notes.append("Stein/Dekton ausgeschlossen.") }
        if scope.includesDelivery { scope.notes.append("Lieferung enthalten oder angefragt.") }
        if scope.includesInstallation { scope.notes.append("Montage enthalten oder angefragt.") }
        return scope
    }

    private func parseMaterials(_ lower: String) -> Set<String> {
        // Materialwissen-Schicht: erkennt humane Eingabe (Synonyme, Marken, Tippfehler,
        // Plurale, Bindestrich-Komposita) und mappt sie auf die kanonischen Preis-Tokens.
        // Bestehende Kanons (linoleum, eiche, furnier, dekorspan, edelstahl, stein, dekton,
        // keramik, hi-macs, mdf, valchromat, fenix, legrabox) bleiben byte-genau erhalten;
        // Longest-Match verhindert, dass "stahl" in "edelstahl" oder "platte" in
        // "arbeitsplatte" fälschlich zündet. Siehe MaterialLexicon.swift.
        MaterialLexicon.shared.materialCanonicals(in: lower)
    }

    private func parseRun(_ lower: String) -> Double? {
        // "4m zeile" / "6 m küchenzeile" sind reale Laufmeter-Angaben — auch die bloße
        // "zeile" (und ihre Varianten) zählt als Zeilenstichwort, nicht nur "küchenzeile".
        let patterns = [
            #"([0-9]+(?:[,.][0-9]+)?)\s*(?:laufmeter|lfm)\b"#,
            #"([0-9]+(?:[,.][0-9]+)?)\s*(?:laufende\s+meter|m)\s+(?:küchenzeile|kuechenzeile|unterschränke|unterschraenke|us|unterbau|zeile|rückzeile|rueckzeile|wandzeile|spülenzeile|spuelenzeile|us-zeile)"#
        ]
        return firstDouble(patterns: patterns, in: lower)
    }

    private func parseBaseUnitWidth(_ lower: String) -> Double? {
        // "us" als Abkürzung für Unterschrank NUR an Wortgrenzen — sonst kollabiert
        // "korp\u{00AD}us melamin" (enthält "us ") fälschlich die ganze Zeile zu einem Einzelschrank.
        // Achtung: "us-zeile" ist eine Küchenzeile (Unterschrank-Zeile), KEIN Einzelschrank —
        // deshalb hier nicht auf "us-" matchen, das fängt der Zeilen-Fallback unten.
        let mentionsUS = lower.hasPrefix("us ") || lower.contains(" us ")
        guard lower.contains("unterschrank") || lower.contains("unterschränk") || lower.contains("unterschraenk") || mentionsUS || lower.contains("unterbau") || lower.contains("korpus unten") else { return nil }
        let patterns = [
            #"([0-9]+(?:[,.][0-9]+)?)\s*cm\s+(?:[a-zäöüß-]+\s+){0,2}unterschrank"#,
            #"([0-9]+(?:[,.][0-9]+)?)\s*cm"#
        ]
        guard let centimeters = firstDouble(patterns: patterns, in: lower) else { return 0.6 }
        return centimeters / 100
    }

    private func parseArea(_ lower: String) -> Double? {
        let patterns = [
            #"([0-9]+(?:[,.][0-9]+)?)\s*(?:m2|m²|qm)\b"#
        ]
        return firstDouble(patterns: patterns, in: lower)
    }

    private func parseSingleMeterLength(_ lower: String) -> Double? {
        let patterns = [
            #"([0-9]+(?:[,.][0-9]+)?)\s*(?:m|meter)\b"#
        ]
        return firstDouble(patterns: patterns, in: lower)
    }

    private func parseDrawerCount(_ lower: String) -> Int {
        let drawerWords = ["schubkästen", "schubkaesten", "schubladen", "legraboxen", "legrabox"]
        var total = 0
        for word in drawerWords {
            let pattern = #"([0-9]+|ein|eine|einen|zwei|drei|vier|fünf|fuenf|sechs|sieben|acht|neun|zehn|elf|zwölf|zwoelf|dreizehn|vierzehn|fünfzehn|fuenfzehn)\s+(?:[a-zäöüß-]+\s+){0,2}[a-zäöüß-]*\#(word)\b"#
            for match in matches(pattern: pattern, in: lower) {
                let token = String(match.1)
                total += Int(token) ?? GermanNumberParser.integerWord(token) ?? 0
            }
        }
        return total
    }

    private func parseAnyDimension(in lower: String) -> (width: Double, height: Double?, depth: Double?)? {
        parseDimension(after: "", in: lower)
    }

    private func parseDimension(after marker: String, in lower: String) -> (width: Double, height: Double?, depth: Double?)? {
        let searchArea: String
        if marker.isEmpty {
            searchArea = lower
        } else if let range = lower.range(of: marker) {
            searchArea = String(lower[range.lowerBound...])
        } else {
            searchArea = lower
        }
        let pattern = #"([0-9]+(?:[,.][0-9]+)?)\s*x\s*([0-9]+(?:[,.][0-9]+)?)(?:\s*x\s*([0-9]+(?:[,.][0-9]+)?))?\s*m?"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let nsRange = NSRange(searchArea.startIndex..<searchArea.endIndex, in: searchArea)
        guard let result = regex.firstMatch(in: searchArea, range: nsRange),
              let firstRange = Range(result.range(at: 1), in: searchArea),
              let secondRange = Range(result.range(at: 2), in: searchArea) else { return nil }
        let width = GermanNumberParser.double(String(searchArea[firstRange])) ?? 0
        let second = GermanNumberParser.double(String(searchArea[secondRange]))
        let third: Double?
        if result.numberOfRanges > 3,
           result.range(at: 3).location != NSNotFound,
           let thirdRange = Range(result.range(at: 3), in: searchArea) {
            third = GermanNumberParser.double(String(searchArea[thirdRange]))
        } else {
            third = nil
        }
        return (width, second, third)
    }

    private func firstDouble(patterns: [String], in text: String) -> Double? {
        for pattern in patterns {
            if let match = matches(pattern: pattern, in: text).first,
               let value = GermanNumberParser.double(String(match.1)) {
                return value
            }
        }
        return nil
    }

    private func matches(pattern: String, in text: String) -> [(Substring, Substring, Substring?)] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: nsRange).compactMap { result in
            guard result.numberOfRanges >= 2,
                  let r0 = Range(result.range(at: 0), in: text),
                  let r1 = Range(result.range(at: 1), in: text) else { return nil }
            let r2: Range<String.Index>? = result.numberOfRanges > 2 && result.range(at: 2).location != NSNotFound ? Range(result.range(at: 2), in: text) : nil
            return (text[r0], text[r1], r2.map { text[$0] })
        }
    }
}

public typealias SemanticParser = EstimateRequestParser
