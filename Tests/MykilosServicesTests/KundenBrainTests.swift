import Testing
import Foundation
import MykilosKit
@testable import MykilosServices

// MARK: - KundenBrain + LookupKundeTool (L24)

struct KundenBrainTests {

    private func brain() -> KundenBrain {
        let customers = [
            Customer(customerNumber: "K-001", name: "Schmidt Wohnbau"),
            Customer(customerNumber: "K-002", name: "Hansen Innenausbau"),
        ]
        let projects = [
            Project(projectNumber: "2026-001", title: "Küche", kind: .kitchen, customerNumber: "K-001"),
            Project(projectNumber: "2026-002", title: "Bad", kind: .kitchen, customerNumber: "K-001"),
        ]
        return KundenBrain(customers: customers, projects: projects)
    }

    @Test func lookupFindetNachName() {
        let hits = brain().lookup("schmidt")
        #expect(hits.count == 1)
        #expect(hits.first?.customerNumber == "K-001")
    }

    @Test func lookupFindetNachKundennummer() {
        let hits = brain().lookup("K-002")
        #expect(hits.first?.name == "Hansen Innenausbau")
    }

    @Test func lookupOhneTrefferLeer() {
        #expect(brain().lookup("zzzz").isEmpty)
    }

    @Test func overviewEnthaeltAnzahl() {
        let o = brain().overview
        #expect(o.contains("2 Kunden"))
        #expect(o.contains("Schmidt Wohnbau"))
    }

    @Test func describeZeigtKundennummerUndProjektzahl() {
        let schmidt = brain().customers.first { $0.customerNumber == "K-001" }!
        let d = brain().describe(schmidt)
        #expect(d.contains("Kundennr. K-001"))
        #expect(d.contains("2 Projekte"))
    }
}

struct LookupKundeToolTests {

    private func registry(with customers: [Customer]) -> AssistantToolRegistry {
        AssistantToolRegistry.standard(kundenDirectory: KundenBrain(customers: customers))
    }

    @Test func toolFindetKunde() async {
        let reg = registry(with: [Customer(customerNumber: "K-007", name: "Berger Manufaktur")])
        let r = await reg.run(name: "lookup_kunde", inputJSON: Data(#"{"query":"berger"}"#.utf8))
        #expect(r.isError == false)
        #expect(r.text.contains("Berger Manufaktur"))
        #expect(r.text.contains("K-007"))
    }

    @Test func toolUebersichtBeiLeererAnfrage() async {
        let reg = registry(with: [Customer(customerNumber: "K-1", name: "Alpha"),
                                  Customer(customerNumber: "K-2", name: "Beta")])
        let r = await reg.run(name: "lookup_kunde", inputJSON: Data(#"{"query":""}"#.utf8))
        #expect(r.text.contains("2 Kunden"))
    }

    @Test func toolFehltOhneDirectory() {
        // Opt-in: ohne kundenDirectory ist das Tool nicht registriert.
        let reg = AssistantToolRegistry.standard()
        #expect(reg.toolNames.contains("lookup_kunde") == false)
    }
}
