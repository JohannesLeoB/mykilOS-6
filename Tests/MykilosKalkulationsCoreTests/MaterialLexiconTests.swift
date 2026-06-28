import XCTest
@testable import MykilosKalkulationsCore

// MARK: - MaterialLexiconTests
// Sichert die Sprach-/Materialwissen-Schicht: humane Eingabe (Synonyme, Marken, Tippfehler,
// Plurale, Bindestrich-Komposita) wird robust auf kanonische Preis-Tokens gemappt — OHNE die
// bestehende Schätzgenauigkeit zu verändern. Vokabular stammt aus dem Recherche-Workflow,
// die kanonische Zuordnung ist bewusst legacy-kompatibel (siehe MaterialLexicon.swift).
final class MaterialLexiconTests: XCTestCase {
    private let lex = MaterialLexicon.shared
    private func mats(_ t: String) -> Set<String> { lex.materialCanonicals(in: t) }
    private func parse(_ t: String) -> EstimateRequest { EstimateRequestParser().parse(t) }
    private func classes(_ t: String) -> Set<CalculationComponentClass> { Set(parse(t).components.map(\.componentClass)) }

    // MARK: Tippfehler & Komposita-Zerlegung

    func testVeneerTypoDecomposesToWoodPlusVeneer() {
        // "wrichenfurnier" ist der reale Vertipper für "eichenfurnier".
        XCTAssertEqual(mats("wrichenfurnier zeile 6m"), ["eiche", "furnier"])
        // "eiche furnier" / "eiche-furnier" müssen IMMER in zwei Tokens zerfallen.
        XCTAssertEqual(mats("9 lfm eiche furnier"), ["eiche", "furnier"])
        XCTAssertTrue(mats("eiche-furnier fronten").isSuperset(of: ["eiche", "furnier"]))
    }

    func testWoodTyposAndSolidWoodMarker() {
        XCTAssertTrue(mats("insel nissbaum massiv").isSuperset(of: ["nussbaum", "massivholz"]))
        XCTAssertTrue(mats("nußbaum furniert").contains("nussbaum"))
        XCTAssertTrue(mats("eiche massiv 60mm").isSuperset(of: ["eiche", "massivholz"]))
    }

    func testLinoleumSynonymsAndTypos() {
        XCTAssertEqual(mats("linolium fronten forbo"), ["linoleum"])
        XCTAssertTrue(mats("forbo desktop fronten").contains("linoleum"))
        XCTAssertTrue(mats("5m zeile mit lino kante").contains("linoleum"))
    }

    // MARK: Dekorgruppen-Neutralität (gleiche Ausführung = ein Preis, Farbe egal)

    func testDecorGroupCollapsesToSinglePriceClass() {
        for surface in ["melamin", "egger dekor", "schichtstoff hpl", "resopal", "kunstharz", "dekorspan", "kunststoffbeschichtet"] {
            XCTAssertEqual(mats("fronten \(surface), 4m zeile"), ["dekorspan"],
                           "Dekorgruppe '\(surface)' muss preisneutral auf dekorspan kollabieren.")
        }
        // Farbe ist KEIN Preisfaktor und darf gar kein Materialtoken erzeugen.
        XCTAssertEqual(mats("korpus dekorspan weiss anthrazit grau"), ["dekorspan"])
    }

    // MARK: Stein / Mineralwerkstoff / Marken

    func testStoneAndMineralBrandsRecognised() {
        XCTAssertTrue(mats("silestone apl 6 m2").contains("quarz"))      // engineered quartz
        XCTAssertTrue(mats("dekton sirius apl").contains("dekton"))
        XCTAssertTrue(mats("hi-macs theke").contains("hi-macs"))
        XCTAssertTrue(mats("corian apl 4m2").contains("corian"))
        XCTAssertTrue(mats("keramik apl 5m2").contains("keramik"))
    }

    func testLegacyStonesStayCanonicalStein() {
        // Diese kannte die alte Tabelle bereits -> "stein" (Stein-Rabatt). Muss erhalten bleiben.
        XCTAssertEqual(mats("Arbeitsplatte Naturstein 5,4 m2"), ["stein"])
        XCTAssertEqual(mats("marmor carrara apl"), ["stein"])
        XCTAssertEqual(mats("granit nero assoluto apl"), ["stein"])
    }

    // MARK: Longest-Match-Sicherheit (keine Substring-Fehlauslöser)

    func testEdelstahlDoesNotAlsoEmitStahl() {
        // "stahl" darf NICHT innerhalb von "edelstahl" zünden (würde Scoring/Preis verzerren).
        XCTAssertEqual(mats("edelstahl insel 2x1,2"), ["edelstahl"])
    }

    func testArbeitsplatteDoesNotEmitDecorPlatte() {
        // "platte" darf NICHT innerhalb von "arbeitsplatte" als Dekorgruppe zünden.
        XCTAssertEqual(mats("Arbeitsplatte Naturstein 5,4 m2 mit Montage"), ["stein"])
    }

    // MARK: Abkürzungen & Bauteil-Synonyme im Parser

    func testWorktopAbbreviationsCreateWorktopComponent() {
        XCTAssertTrue(lex.mentionsWorktopSurface(in: "quarzit apl obendrauf"))
        XCTAssertTrue(classes("silestone apl ca 6 m2 mit montage").contains(.worktopSurface))
        XCTAssertTrue(classes("9 lfm eiche furnier, quarzit apl, ohne geräte").contains(.worktopSurface))
    }

    func testScopeGateStillSuppressesExcludedWorktop() {
        // "ohne apl" / "ohne arbeitsplatte" darf trotz Erkennung KEINE Arbeitsplatte anlegen.
        XCTAssertFalse(classes("4,5 lfm zeile eiche furniert, ohne apl ohne geräte").contains(.worktopSurface))
        XCTAssertFalse(classes("60cm Unterschrank, Dekorspan, ohne Arbeitsplatte, ohne Geräte").contains(.worktopSurface))
    }

    // MARK: Regression — Legacy-/Korridor-Eingaben byte-genau unverändert

    func testLegacyInputMaterialSetsUnchanged() {
        XCTAssertEqual(mats("60cm Unterschrank mit einer Tür, Dekorspan, ein Einlegeboden, ohne Arbeitsplatte, ohne Geräte"), ["dekorspan"])
        XCTAssertEqual(mats("5 laufmeter Küchenzeile mit Linoleumfronten, 7 Legraboxen, ohne Arbeitsplatte, ohne Geräte"), ["linoleum", "legrabox"])
        XCTAssertEqual(mats("5 laufmeter unterschränke mit linoleumfronten. 15 eichenschubkästen. Insel ca 2 x 1,2 m in Edelstahl."), ["linoleum", "eiche", "edelstahl"])
        XCTAssertEqual(mats("Arbeitsplatte Naturstein 5,4 m2 mit Ausschnitten und Montage"), ["stein"])
    }

    // MARK: Breiter Stresstest — reale unordentliche Eingaben werden korrekt erkannt

    func testMessyHumanInputsDetectExpectedComponents() {
        let cases: [(String, [CalculationComponentClass])] = [
            ("9 lfm eiche furnier, insel ~2,8x1,2, quarzit apl obendrauf, ohne geräte", [.kitchenRun, .island, .worktopSurface]),
            ("linolium fronten forbo, 5m zeile, 7 legraboxen, ohne geräte", [.kitchenRun]),
            ("silestone apl ca 6 m2, ausschnitt für spüle, mit montage", [.worktopSurface, .logistics]),
            ("dekton arbeitsplatte 6m2 küche, ohne geräte", [.worktopSurface]),
            ("hi-macs theke weiss, mineralwerkstoff, l-form ca 3,2m", [.worktopSurface]),
            ("granit apl nero assoluto 5,5m2 ohne montage", [.worktopSurface]),
            ("valchromat fronten durchgefärbt anthrazit, 4m zeile, ohne apl", [.kitchenRun]),
            ("mdf lackiert RAL9010 hochglanz, 5lfm zeile mit 8 auszügen", [.kitchenRun]),
            ("fenix nano fronten schwarz, insel 2,2x1,1, ohne geräte", [.island]),
            ("furnierspan eiche us-zeile 5,5m, 9 schubladen, apl multiplex", [.kitchenRun, .worktopSurface]),
        ]
        for (text, expected) in cases {
            let got = classes(text)
            for cls in expected {
                XCTAssertTrue(got.contains(cls), "\(text) → erwartete Komponente \(cls.rawValue) fehlt (erkannt: \(got.map(\.rawValue)))")
            }
        }
    }
}
