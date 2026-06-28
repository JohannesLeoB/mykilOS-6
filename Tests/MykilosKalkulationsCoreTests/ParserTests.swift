import XCTest
@testable import MykilosKalkulationsCore

final class ParserTests: XCTestCase {
    func testGermanMoneyParsing() throws {
        XCTAssertEqual(GermanNumberParser.decimal("3.886,00 €"), Decimal(3886))
        XCTAssertEqual(GermanNumberParser.decimal("10.289,70"), Decimal(string: "10289.70"))
        XCTAssertEqual(GermanNumberParser.decimal("15300.0"), Decimal(15300))
    }

    func testKnownMYKILOSRequest() throws {
        let text = "5 Laufmeter Küchenzeile mit linoleumfronten, 7 legraboxen und vier eichenschubkästen sowie ca 2,4 x 3 m hochschränke mit Türen, ohne Arbeitsplatte, ohne Geräte, mit Lieferung und Montage."
        let request = EstimateRequestParser().parse(text)

        let base = try XCTUnwrap(request.components.first { $0.type == .baseCabinetRun })
        XCTAssertEqual(base.quantity, 5, accuracy: 0.001)
        XCTAssertEqual(base.drawerCount, 11)
        XCTAssertTrue(base.materials.contains("linoleum"))

        let tall = try XCTUnwrap(request.components.first { $0.type == .tallCabinetBlock })
        XCTAssertEqual(tall.widthM ?? 0, 2.4, accuracy: 0.001)
        XCTAssertEqual(tall.heightM ?? 0, 3.0, accuracy: 0.001)

        XCTAssertTrue(request.scope.excludesAppliances)
        XCTAssertTrue(request.scope.excludesWorktop)
        XCTAssertTrue(request.scope.includesDelivery)
        XCTAssertTrue(request.scope.includesInstallation)
    }

    func testSecondAcceptanceRequestParsesIslandAndDrawers() throws {
        let request = EstimateRequestParser().parse("5 laufmeter unterschränke mit linoleumfronten. 15 eichenschubkästen. Insel ca 2 x 1,2 m in Edelstahl.")
        XCTAssertNotNil(request.components.first { $0.type == .baseCabinetRun })
        let island = try XCTUnwrap(request.components.first { $0.type == .island })
        XCTAssertEqual(island.widthM ?? 0, 2, accuracy: 0.001)
        XCTAssertTrue(island.materials.contains("edelstahl"))
        XCTAssertTrue(request.materials.contains("linoleum"))
        XCTAssertEqual(request.components.map(\.drawerCount).max(), 15)
    }

    func testCarryforwardForbiddenContexts() {
        XCTAssertTrue(CarryforwardRule.isForbiddenContext("Übertrag 10.289,70"))
        XCTAssertTrue(CarryforwardRule.isForbiddenContext("19% MwSt"))
        XCTAssertFalse(CarryforwardRule.isForbiddenContext("Schubkasten Eiche 180,00 180,00"))
    }
}
