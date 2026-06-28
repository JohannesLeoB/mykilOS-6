import XCTest
import Foundation
@testable import MykilosServices
import MykilosKalkulationsCore

// MARK: - DeviceCatalog Port-Tests
// Verifiziert den verbatim aus mykilO$$ portierten DeviceCatalog/CSVParser.
// Hinweis: ausschließlich SYNTHETISCHE Daten — niemals das reale Preisbuch.
// Der mykilO$$-`testImportCopiesOutsideRepoAndReloads` ist bewusst NICHT übernommen,
// weil er an den echten Application-Support-Pfad schreibt (würde reale App-Daten berühren).
final class DeviceCatalogTests: XCTestCase {
    // BOM voran, deutsche Werte, ein eingebetteter Zeilenumbruch, eine zu kurze Zeile.
    private let csv = """
    \u{FEFF}Suchtext,Artikelnummer,Hersteller,Kategorie,Artikelbeschreibung,Netto-Verkaufspreis LISTE (€),Netto-Einkaufspreis (€),Netto-Verkaufspreis MYKILOS (€),Rabattstufe in %
    quooker flex kochend,Q-001,Quooker,Armatur,"Quooker Flex
    Kochendwasserhahn",1390,900,1190,15
    gaggenau backofen,G-200,Gaggenau,Backofen,Gaggenau Backofen Serie 200,3200,2100,2890,12
    bora kochfeld abzug,B-PUR,BORA,Kochfeld,BORA Pure Kochfeldabzug,2450,1600,2190,10
    leere zeile ohne preis,X-000,,,
    """

    func testParsesManufacturersPricesAndBOM() throws {
        let catalog = try DeviceCatalog(csv: csv)
        XCTAssertEqual(catalog.entries.filter { !$0.manufacturer.isEmpty }.count, 3)
        let quooker = try XCTUnwrap(catalog.entries.first { $0.manufacturer == "Quooker" })
        XCTAssertEqual(quooker.category, "Armatur")
        XCTAssertEqual(quooker.mykilosNet, Decimal(1190))
        XCTAssertEqual(quooker.purchaseNet, Decimal(900))
        XCTAssertTrue(quooker.description.contains("Kochendwasserhahn"), "Eingebetteter Zeilenumbruch muss erhalten bleiben.")
        XCTAssertFalse(catalog.entries.first!.haystack.contains("\u{FEFF}"), "BOM darf nicht im Suchindex landen.")
    }

    func testSearchScoresByTokenAndPrefersMykilosPrice() throws {
        let catalog = try DeviceCatalog(csv: csv)
        let hits = catalog.search("bora kochfeld")
        XCTAssertEqual(hits.first?.manufacturer, "BORA")
        XCTAssertEqual(hits.first?.sellNet, Decimal(2190), "sellNet muss MYKILOS-VK vor Liste bevorzugen.")
    }

    func testSearchEmptyQueryReturnsNothing() throws {
        let catalog = try DeviceCatalog(csv: csv)
        XCTAssertTrue(catalog.search("   ").isEmpty)
        XCTAssertTrue(catalog.search("nichtvorhandenerbegriffxyz").isEmpty)
    }
}
