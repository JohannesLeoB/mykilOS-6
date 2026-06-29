import Testing
import Foundation
import MykilosKit
@testable import MykilosServices

// MARK: - AssistantNotesStore (S4) — Cold-Start + CRUD

struct AssistantNotesStoreTests {

    @Test func notizUeberlebtNeustart() async throws {
        let db = try GRDBDatabase.inMemory()
        let storeA = AssistantNotesStore(db: db)
        let note = try await storeA.create("Miele Brüheinheit — Frau Jacob 0403005018048")

        // Neue Instanz auf derselben DB → laden → identisch.
        let storeB = AssistantNotesStore(db: db)
        let loaded = try await storeB.all()
        #expect(loaded.count == 1)
        #expect(loaded.first?.id == note.id)
        #expect(loaded.first?.body == "Miele Brüheinheit — Frau Jacob 0403005018048")
    }

    @Test func loeschenPerRefUndTextfund() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = AssistantNotesStore(db: db)
        let a = try await store.create("Angebot Hustadt nachfassen")
        _ = try await store.create("Material bei Blum bestellen")

        // per ID-Präfix (ref) löschen
        let deleted = try await store.delete(matching: a.ref)
        #expect(deleted?.id == a.id)

        // per Text-Teilstring finden
        let found = try await store.find(matching: "blum")
        #expect(found?.body.contains("Blum") == true)

        #expect(try await store.all().count == 1)
    }

    @Test func bearbeitenAendertTextUndPersistiert() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = AssistantNotesStore(db: db)
        let n = try await store.create("alt")
        let updated = try await store.update(matching: n.ref, newBody: "neu")
        #expect(updated?.body == "neu")

        let fresh = AssistantNotesStore(db: db)
        #expect(try await fresh.all().first?.body == "neu")
    }

    @Test func leereDatenbankLiefertKeineNotizen() async throws {
        let db = try GRDBDatabase.inMemory()
        let store = AssistantNotesStore(db: db)
        #expect(try await store.all().isEmpty)
        #expect(try await store.delete(matching: "irgendwas") == nil)
    }
}

// MARK: - Notiz-Tools über die Registry

struct NoteToolsTests {
    private func registry(_ db: GRDBDatabase) -> AssistantToolRegistry {
        AssistantToolRegistry.standard(notesStore: AssistantNotesStore(db: db))
    }

    @Test func createUndListUeberRegistry() async throws {
        let db = try GRDBDatabase.inMemory()
        let reg = registry(db)
        let created = await reg.run(name: "create_note", inputJSON: Data(#"{"text":"Brüheinheit prüfen"}"#.utf8))
        #expect(created.isError == false)
        #expect(created.text.contains("Brüheinheit prüfen"))

        let listed = await reg.run(name: "list_notes", inputJSON: Data("{}".utf8))
        #expect(listed.text.contains("Brüheinheit prüfen"))
    }

    @Test func deleteOhneTrefferIstFehler() async throws {
        let db = try GRDBDatabase.inMemory()
        let reg = registry(db)
        let r = await reg.run(name: "delete_note", inputJSON: Data(#"{"note":"gibtsnicht"}"#.utf8))
        #expect(r.isError == true)
    }

    @Test func notizToolsFehlenOhneStore() {
        let reg = AssistantToolRegistry.standard()
        #expect(reg.toolNames.contains("create_note") == false)
    }
}
