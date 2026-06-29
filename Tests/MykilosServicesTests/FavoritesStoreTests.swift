import Testing
import Foundation
@testable import MykilosServices

// MARK: - FavoritesStore Cold-Start-Tests (L25)
@MainActor
struct FavoritesStoreTests {

    @Test func favoritUeberlebtNeustart() throws {
        let db = try GRDBDatabase.inMemory()
        let storeA = FavoritesStore(db: db)
        try storeA.toggle(projectNumber: "2026-015")

        // Neue Instanz auf derselben DB → laden → identisch.
        let storeB = FavoritesStore(db: db)
        try storeB.load()
        #expect(storeB.isFavorite("2026-015"))
        #expect(storeB.favorites == ["2026-015"])
    }

    @Test func toggleEntferntFavorit() throws {
        let db = try GRDBDatabase.inMemory()
        let store = FavoritesStore(db: db)
        try store.toggle(projectNumber: "2026-015")   // an
        try store.toggle(projectNumber: "2026-015")   // aus

        let fresh = FavoritesStore(db: db)
        try fresh.load()
        #expect(fresh.favorites.isEmpty)
        #expect(fresh.isFavorite("2026-015") == false)
    }

    @Test func mehrereFavoritenUeberlebenNeustart() throws {
        let db = try GRDBDatabase.inMemory()
        let store = FavoritesStore(db: db)
        try store.toggle(projectNumber: "2026-001")
        try store.toggle(projectNumber: "2026-002")
        try store.toggle(projectNumber: "2026-003")

        let fresh = FavoritesStore(db: db)
        try fresh.load()
        #expect(fresh.favorites == ["2026-001", "2026-002", "2026-003"])
    }

    @Test func leereDatenbankLiefertLeereMenge() throws {
        let db = try GRDBDatabase.inMemory()
        let store = FavoritesStore(db: db)
        try store.load()
        #expect(store.favorites.isEmpty)
        #expect(store.isFavorite("irgendwas") == false)
    }

    @Test func saveStateWirdGesetzt() throws {
        let db = try GRDBDatabase.inMemory()
        let store = FavoritesStore(db: db)
        try store.toggle(projectNumber: "2026-099")
        if case .saved = store.saveState { } else {
            Issue.record("saveState sollte nach Toggle .saved sein, war \(store.saveState)")
        }
    }
}
