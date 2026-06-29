import Testing
import Foundation
import MykilosKit
@testable import MykilosServices

// MARK: - AssistantTasksStore (S6)

struct AssistantTasksStoreTests {

    @Test func anlegenUndAuflisten() async throws {
        let store = AssistantTasksStore(db: try GRDBDatabase.inMemory())
        try await store.create("Brüheinheit prüfen")
        try await store.create("Angebot Cirnavuk nachfassen")
        let all = try await store.all()
        #expect(all.count == 2)
        #expect(all.allSatisfy { !$0.done })
    }

    @Test func offeneZuerstDannErledigte() async throws {
        let store = AssistantTasksStore(db: try GRDBDatabase.inMemory())
        let a = try await store.create("erste")
        try await store.create("zweite")
        // erste abhaken → muss ans Ende rutschen
        try await store.setDone(matching: a.ref, done: true)
        let all = try await store.all()
        #expect(all.first?.done == false)
        #expect(all.last?.done == true)
        let open = try await store.open()
        #expect(open.count == 1)
        #expect(open.first?.title == "zweite")
    }

    @Test func faelligkeitSortiertOffene() async throws {
        let store = AssistantTasksStore(db: try GRDBDatabase.inMemory())
        let spaet = Date(timeIntervalSince1970: 2_000_000)
        let frueh = Date(timeIntervalSince1970: 1_000_000)
        try await store.create("spät", dueDate: spaet)
        try await store.create("früh", dueDate: frueh)
        try await store.create("ohne")
        let open = try await store.open()
        #expect(open[0].title == "früh")   // frühere Fälligkeit zuerst
        #expect(open[1].title == "spät")
        #expect(open[2].title == "ohne")   // ohne Fälligkeit zuletzt
    }

    @Test func findetPerRefUndTitel() async throws {
        let store = AssistantTasksStore(db: try GRDBDatabase.inMemory())
        let t = try await store.create("Material bestellen")
        #expect(try await store.find(matching: t.ref)?.id == t.id)
        #expect(try await store.find(matching: "material")?.id == t.id)
        #expect(try await store.find(matching: "gibtsnicht") == nil)
    }

    @Test func loeschenEntfernt() async throws {
        let store = AssistantTasksStore(db: try GRDBDatabase.inMemory())
        let t = try await store.create("wegwerfen")
        let deleted = try await store.delete(matching: "wegwerfen")
        #expect(deleted?.id == t.id)
        #expect(try await store.all().isEmpty)
    }

    // Merge-Gate: Cold-Start. Schreiben → neue Instanz auf derselben Datei → identisch.
    @Test func aufgabeUeberlebtNeustart() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("tasks-coldstart-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("db.sqlite")
        let due = Date(timeIntervalSince1970: 1_700_000)

        let created: AssistantTask
        do {
            let store = AssistantTasksStore(db: try GRDBDatabase(url: url))
            created = try await store.create("überlebt Neustart", dueDate: due)
            try await store.setDone(matching: created.ref, done: true)
        }

        let store2 = AssistantTasksStore(db: try GRDBDatabase(url: url))
        let all = try await store2.all()
        #expect(all.count == 1)
        let t = try #require(all.first)
        #expect(t.id == created.id)
        #expect(t.title == "überlebt Neustart")
        #expect(t.done == true)
        #expect(t.dueDate.map { Int($0.timeIntervalSince1970) } == Int(due.timeIntervalSince1970))
    }

    // MARK: - Tools

    @Test func toolsLegenAnHakenAbUndLoeschen() async throws {
        let db = try GRDBDatabase.inMemory()
        let reg = AssistantToolRegistry.standard(tasksStore: AssistantTasksStore(db: db))

        let create = await reg.run(name: "create_task", inputJSON: Data(#"{"titel":"Küche aufmessen","faellig":"2026-07-01"}"#.utf8))
        #expect(create.isError == false)
        #expect(create.text.contains("01.07.26"))

        let list = await reg.run(name: "list_tasks", inputJSON: Data("{}".utf8))
        #expect(list.text.contains("Küche aufmessen"))
        #expect(list.text.contains("○"))   // offen

        let done = await reg.run(name: "complete_task", inputJSON: Data(#"{"aufgabe":"Küche"}"#.utf8))
        #expect(done.isError == false)
        #expect(done.text.contains("erledigt"))

        let list2 = await reg.run(name: "list_tasks", inputJSON: Data(#"{"nur_offen":"true"}"#.utf8))
        #expect(list2.text.contains("Keine offenen Aufgaben"))

        let del = await reg.run(name: "delete_task", inputJSON: Data(#"{"aufgabe":"Küche"}"#.utf8))
        #expect(del.isError == false)
    }

    @Test func toolMeldetUnbekannteAufgabe() async throws {
        let reg = AssistantToolRegistry.standard(tasksStore: AssistantTasksStore(db: try GRDBDatabase.inMemory()))
        let r = await reg.run(name: "complete_task", inputJSON: Data(#"{"aufgabe":"gibtsnicht"}"#.utf8))
        #expect(r.isError == true)
    }
}
