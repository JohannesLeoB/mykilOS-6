import Foundation

// MARK: - ProjectClickUpRef (S11)
// Leichte Referenz für die projektübergreifende ClickUp-Aggregation: welche Liste
// gehört zu welchem Projekt. Erlaubt dem Assistenten eine Gesamtübersicht offener
// Aufgaben über alle Projekte mit verknüpfter ClickUp-Liste.
public struct ProjectClickUpRef: Sendable, Equatable {
    public let projectNumber: String
    public let title: String
    public let listID: String

    public init(projectNumber: String, title: String, listID: String) {
        self.projectNumber = projectNumber
        self.title = title
        self.listID = listID
    }
}
