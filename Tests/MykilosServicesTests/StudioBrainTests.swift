import Testing
import Foundation
@testable import MykilosServices

struct StudioBrainTests {

    private let sampleJSON = """
    {
      "_meta": {"generated": "2026-06-27 21:10", "totals": {"channels": 229, "messages": 12465, "project_channels": 96, "issue_signals": 443}},
      "team": [{"name": "Daniel", "messages": 2733}, {"name": "Frauke Fudickar", "messages": 2097}],
      "suppliers": [{"name": "Weichsel78 (Tischlerei)", "mentions": 176}, {"name": "Quooker (Armaturen)", "mentions": 96}],
      "projects": [
        {"channel": "p_hh_schneider_dk", "phase": "p", "phase_label": "Projekt", "client_display": "Schneider", "client_key": "schneider", "location": "Hamburg", "messages": 120, "max_amount_eur": 48000, "price_mentions": 5, "issue_signals": 21, "issue_keywords": ["edelstahl", "lieferzeit"], "days_since_last": 10, "last": "2026-06-18"},
        {"channel": "a_b_amklubhaus", "phase": "a", "phase_label": "Angebot/Anfrage", "client_display": "Amklubhaus", "client_key": "amklubhaus", "location": "Berlin", "messages": 0, "max_amount_eur": null, "price_mentions": 0, "issue_signals": 0, "issue_keywords": [], "days_since_last": 400, "last": "2025-05-13"}
      ]
    }
    """

    @Test func parstStrukturUndTotals() throws {
        let brain = try #require(StudioBrain(data: Data(sampleJSON.utf8)))
        #expect(brain.projects.count == 2)
        #expect(brain.suppliers.count == 2)
        #expect(brain.team.count == 2)
        #expect(brain.totals["channels"] == 229)
        #expect(brain.overview.contains("Daniel"))
        #expect(brain.overview.contains("Weichsel78 (Tischlerei)"))
    }

    @Test func lookupFindetProjektUndLieferant() throws {
        let brain = try #require(StudioBrain(data: Data(sampleJSON.utf8)))
        let hits = brain.lookup("Schneider")
        #expect(hits.isEmpty == false)
        let text = hits.map(brain.describe).joined(separator: "\n")
        #expect(text.contains("Schneider"))
        #expect(text.contains("Problem-Signale"))   // 21 issue_signals

        let supHits = brain.lookup("Quooker")
        #expect(supHits.contains { if case .supplier = $0 { return true }; return false })
    }

    @Test func leererTreffer() throws {
        let brain = try #require(StudioBrain(data: Data(sampleJSON.utf8)))
        #expect(brain.lookup("zzzznichtvorhanden").isEmpty)
    }
}
