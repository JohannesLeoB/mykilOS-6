import Testing
import Foundation
@testable import MykilosKit

// MARK: - StudioContext-Tests
// Beweist die Signal-Hygiene: kein unbegrenztes Wachstum, kein doppeltes
// projectFocused beim erneuten Fokussieren desselben Projekts.
struct StudioContextTests {

    // MARK: Fokus-Guard: gleiches Projekt erneut → kein neues Signal
    @Test func erneuterFokusDesselbenProjektsEmittiertNicht() {
        let ctx = StudioContext()
        ctx.focus(project: "ME-24")
        let afterFirst = ctx.signals.count
        #expect(afterFirst >= 1)                 // projectFocused emittiert

        ctx.focus(project: "ME-24")              // identischer Fokus
        #expect(ctx.signals.count == afterFirst) // nichts dazugekommen

        ctx.focus(project: "SO-24")              // echter Wechsel
        #expect(ctx.signals.count > afterFirst)  // jetzt emittiert
    }

    // MARK: Cap: der Signal-Log wächst nicht unbegrenzt
    @Test func signalLogIstGedeckelt() {
        let ctx = StudioContext()
        for i in 0..<1000 {
            ctx.emit(.deadlineNear(projectID: "P\(i)", days: i))
        }
        #expect(ctx.signals.count <= 200)
        // Die jüngsten Signale bleiben erhalten (vom Anfang getrimmt).
        #expect(ctx.signals.last == .deadlineNear(projectID: "P999", days: 999))
    }

    // MARK: Abgeleitetes Signal bleibt erhalten (offerDetected → reviewSuggested)
    @Test func mediatorAbleitungLandetImLog() {
        let ctx = StudioContext()
        ctx.emit(.offerDetected(projectID: "ME-24", label: "Naturstein"))
        let reviews = ctx.signals(for: "ME-24").filter {
            if case .reviewSuggested = $0 { return true }; return false
        }
        #expect(reviews.count == 1)
    }
}
