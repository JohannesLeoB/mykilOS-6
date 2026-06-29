import Testing
import Foundation
import MykilosKit
@testable import MykilosServices

// MARK: - S11: projektübergreifende ClickUp-Übersicht (list_all_clickup_tasks)

struct AllClickUpTasksToolTests {

    private func registry(_ client: ClickUpFetching, _ listings: [ProjectClickUpRef]) -> AssistantToolRegistry {
        AssistantToolRegistry.standard(clickUp: client, clickUpListings: listings)
    }

    @Test func aggregiertUeberMehrereProjekte() async {
        let client = FakeClickUp(byList: [
            "L1": [ClickUpTask(id: "1", name: "Aufmaß", status: "open")],
            "L2": [ClickUpTask(id: "2", name: "Angebot", status: "in progress"),
                   ClickUpTask(id: "3", name: "Montage", status: "open")],
        ])
        let listings = [
            ProjectClickUpRef(projectNumber: "2026-001", title: "Cirnavuk", listID: "L1"),
            ProjectClickUpRef(projectNumber: "2026-002", title: "Hustadt", listID: "L2"),
        ]
        let r = await registry(client, listings).run(name: "list_all_clickup_tasks", inputJSON: Data("{}".utf8))
        #expect(r.isError == false)
        #expect(r.text.contains("2026-001 Cirnavuk"))
        #expect(r.text.contains("2026-002 Hustadt"))
        #expect(r.text.contains("Montage"))
        #expect(r.text.contains("3 über 2 Projekt"))   // total/Projekte-Header
    }

    @Test func projektFilterGreiftUndUeberspringtFehler() async {
        let client = FakeClickUp(byList: ["L1": [ClickUpTask(id: "1", name: "Aufmaß", status: "open")]],
                                 failing: ["L2"])
        let listings = [
            ProjectClickUpRef(projectNumber: "2026-001", title: "Cirnavuk", listID: "L1"),
            ProjectClickUpRef(projectNumber: "2026-002", title: "Hustadt", listID: "L2"),
        ]
        // Filter auf Cirnavuk → nur L1, kein Fehler trotz kaputter L2
        let filtered = await registry(client, listings).run(name: "list_all_clickup_tasks", inputJSON: Data(#"{"projekt":"cirnavuk"}"#.utf8))
        #expect(filtered.text.contains("Cirnavuk"))
        #expect(filtered.text.contains("Hustadt") == false)
    }

    @Test func toolFehltOhneListings() {
        let reg = AssistantToolRegistry.standard()
        #expect(reg.toolNames.contains("list_all_clickup_tasks") == false)
    }
}

private struct FakeClickUp: ClickUpFetching {
    let byList: [String: [ClickUpTask]]
    var failing: Set<String> = []
    func tasks(listID: String) async throws -> [ClickUpTask] {
        if failing.contains(listID) { throw ClickUpError.httpError(500) }
        return byList[listID] ?? []
    }
}
