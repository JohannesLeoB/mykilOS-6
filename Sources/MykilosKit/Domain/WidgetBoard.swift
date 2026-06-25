import Foundation

// MARK: - WidgetBoardID
// Eindeutige Identität eines Widget-Boards. "home" ist das Heute-Board,
// alle anderen sind Projekt-Boards (Projektnummer als Key).
public enum WidgetBoardID: Hashable, Sendable, CustomStringConvertible {
    case home
    case project(String)   // Projektnummer z. B. "ME-24"

    public var rawValue: String {
        switch self { case .home: "home"; case let .project(p): "project_\(p)" }
    }
    public var description: String { rawValue }
}

// MARK: - Home-Default-Layout
extension WidgetBoardDefault {
    public static var homeLayout: [WidgetInstance] {[
        WidgetInstance(kind: .focus,          size: .wide,   position: 0),
        WidgetInstance(kind: .notes,          size: .medium, position: 1),
        WidgetInstance(kind: .projectFaves,   size: .full,   position: 2),
        WidgetInstance(kind: .recentActivity, size: .wide,   position: 3),
        WidgetInstance(kind: .clockodo,       size: .medium, position: 4),
    ]}
}
