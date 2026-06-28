import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

// MARK: - OffersTabView (Post-Akt 5, Aufgabe 10; zwei Spalten seit Live-Wiring)
// Die „Angebote"-Tab der Projekt-Detailseite. Zeigt die zwei realen Drive-
// Unterordner eines Projekts nebeneinander: "04 ausgehende Angebote" und
// "05 eingehende Angebote" — nicht mehr eine Namens-Heuristik über den ganzen
// Projektordner (die frühere Variante hätte Belege in diesen Unterordnern nie
// gefunden, weil `listFolder` nicht rekursiv ist).
//
// Read-only: nur Metadaten + Link zum Öffnen im Browser, nie Schreiben. Alle
// Renderstates über den geteilten `WidgetContainer`; Quelle bleibt sichtbar.
struct OffersTabView: View {
    let projectID: String
    let driveFolderID: String?

    @State private var loader = OffersLoader()
    @State private var searchText = ""
    @State private var sortByDate = true   // true = neueste zuerst, false = Name A–Z

    var body: some View {
        WidgetContainer(
            kind: .drive,
            sourceLabel: sourceLabel,
            renderState: loader.renderState,
            projectID: projectID
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                header
                if case .content = loader.renderState { searchAndSort }
                columns
            }
        }
        .task(id: driveFolderID) {
            await loader.load(rootFolderID: driveFolderID)
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.top, MykSpace.s7)
        .padding(.bottom, 64)   // Platz für SaveStateBar
    }

    private var sourceLabel: String {
        switch loader.renderState {
        case .content: "GOOGLE DRIVE  ·  \(loader.incoming.count + loader.outgoing.count) BELEGE"
        default:       "GOOGLE DRIVE"
        }
    }

    private var header: some View {
        HStack {
            SourceChip(kind: .drive)
            Text("Angebote & Rechnungen").mykWidgetTitle()
            Spacer()
            if case .content = loader.renderState { refreshButton }
            else if case .error = loader.renderState { retryButton }
            else if case .permissionRequired = loader.renderState { retryButton }
        }
    }

    private var searchAndSort: some View {
        HStack(spacing: MykSpace.s4) {
            Image(systemName: "magnifyingglass")
                .font(.mykCaption)
                .foregroundStyle(MykColor.muted.color)
            TextField("Dateiname suchen…", text: $searchText)
                .font(.mykSmall)
                .textFieldStyle(.plain)
            Spacer()
            Button {
                sortByDate.toggle()
            } label: {
                Label(sortByDate ? "Datum" : "Name",
                      systemImage: sortByDate ? "calendar" : "textformat.abc")
                    .font(.mykMono(9.5))
                    .foregroundStyle(MykColor.muted.color)
            }
            .buttonStyle(.plain)
            .help(sortByDate ? "Sortierung: Neueste zuerst — klicken für Name A–Z" : "Sortierung: Name A–Z — klicken für Datum")
        }
        .padding(.horizontal, MykSpace.s4)
        .padding(.vertical, MykSpace.s2)
        .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.line.color.opacity(0.18)))
    }

    private func filtered(_ files: [GoogleDriveFile]) -> [GoogleDriveFile] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = q.isEmpty ? files : files.filter { $0.name.localizedCaseInsensitiveContains(q) }
        return sortByDate
            ? base.sorted { ($0.modifiedAt ?? .distantPast) > ($1.modifiedAt ?? .distantPast) }
            : base.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    private var refreshButton: some View {
        Button {
            Task { await loader.load(rootFolderID: driveFolderID) }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.mykCaption)
                .foregroundStyle(MykColor.drive.color)
        }
        .buttonStyle(.plain)
        .help("Aktualisieren")
    }

    private var retryButton: some View {
        Button("Erneut versuchen") {
            Task { await loader.load(rootFolderID: driveFolderID) }
        }
        .font(.mykMono(9.5))
        .buttonStyle(.plain)
        .foregroundStyle(MykColor.drive.color)
    }

    private var columns: some View {
        HStack(alignment: .top, spacing: MykSpace.s7) {
            OfferColumn(title: "Eingehende Angebote", files: filtered(loader.incoming), folderFound: loader.incomingFolderFound)
            Divider().overlay(MykColor.line.color.opacity(0.6))
            OfferColumn(title: "Ausgehende Angebote", files: filtered(loader.outgoing), folderFound: loader.outgoingFolderFound)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - OfferColumn
private struct OfferColumn: View {
    let title: String
    let files: [GoogleDriveFile]
    let folderFound: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            Text("\(title) · \(files.count)")
                .font(.mykCaption)
                .foregroundStyle(MykColor.muted.color)
            if folderFound == false {
                Text("Ordner nicht gefunden")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
            } else if files.isEmpty {
                Text("Keine Belege")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
            } else {
                VStack(spacing: 0) {
                    ForEach(files) { file in
                        OfferRow(file: file)
                        if file.id != files.last?.id {
                            Divider().overlay(MykColor.line.color.opacity(0.6))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - OffersLoader
// Pro Tab-Instanz, reiner Lesefetch. Löst zuerst die zwei realen Unterordner
// ("...ausgehende Angebote" / "...eingehende Angebote") unterhalb des Projekt-
// Drive-Ordners tolerant über den Namen auf, dann werden deren Inhalte separat
// gelistet — alles über den bestehenden read-only `GoogleDriveClient`.
@MainActor
@Observable
private final class OffersLoader {
    private(set) var incoming: [GoogleDriveFile] = []
    private(set) var outgoing: [GoogleDriveFile] = []
    private(set) var incomingFolderFound = true
    private(set) var outgoingFolderFound = true
    private(set) var renderState: WidgetRenderState = .loading

    private let client: GoogleDriveFetching
    // Generation-Token: nur das jüngste load() committet (Projektwechsel/Retry).
    private var loadGeneration = 0

    init(client: GoogleDriveFetching = GoogleDriveClient()) {
        self.client = client
    }

    func load(rootFolderID: String?) async {
        loadGeneration &+= 1
        let generation = loadGeneration
        guard let rootFolderID, rootFolderID.isEmpty == false else {
            incoming = []
            outgoing = []
            renderState = .empty
            return
        }
        renderState = .loading
        do {
            let rootChildren = try await client.listFolder(folderID: rootFolderID)
            guard generation == loadGeneration else { return }

            let incomingFolder = Self.subfolder(in: rootChildren, matching: "eingehende")
            let outgoingFolder = Self.subfolder(in: rootChildren, matching: "ausgehende")
            incomingFolderFound = incomingFolder != nil
            outgoingFolderFound = outgoingFolder != nil

            async let incomingFiles = Self.files(in: incomingFolder, client: client)
            async let outgoingFiles = Self.files(in: outgoingFolder, client: client)
            let (resolvedIncoming, resolvedOutgoing) = try await (incomingFiles, outgoingFiles)
            guard generation == loadGeneration else { return }

            incoming = resolvedIncoming
            outgoing = resolvedOutgoing
            renderState = (resolvedIncoming.isEmpty && resolvedOutgoing.isEmpty) ? .empty : .content
        } catch GoogleDriveError.notConnected {
            guard generation == loadGeneration else { return }
            incoming = []
            outgoing = []
            renderState = .permissionRequired
        } catch {
            guard generation == loadGeneration else { return }
            incoming = []
            outgoing = []
            renderState = .error(String(describing: error))
        }
    }

    // Tolerant: echte Ordner heißen z.B. "04 ausgehende Angebote" /
    // "05 eingehende Angebote" — Nummerierung und Großschreibung ignorieren wir,
    // nur das Schlüsselwort muss im Namen vorkommen.
    private static func subfolder(in children: [GoogleDriveFile], matching keyword: String) -> GoogleDriveFile? {
        children.first {
            $0.mimeType == "application/vnd.google-apps.folder"
                && $0.name.lowercased().contains(keyword)
        }
    }

    private static func files(in folder: GoogleDriveFile?, client: GoogleDriveFetching) async throws -> [GoogleDriveFile] {
        guard let folder else { return [] }
        let children = try await client.listFolder(folderID: folder.id)
        return children.filter { $0.mimeType != "application/vnd.google-apps.folder" }
    }
}

// MARK: - OfferRow
private struct OfferRow: View {
    let file: GoogleDriveFile

    @State private var showPreview = false

    var body: some View {
        HStack(spacing: MykSpace.s4) {
            Button { showPreview.toggle() } label: {
                Image(systemName: file.iconName)
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.cash.color)
                    .frame(width: 20)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showPreview, arrowEdge: .trailing) {
                FilePreviewView(file: file)
                    .frame(width: 300)
                    .padding(MykSpace.s2)
            }

            Button {
                if let link = file.webViewLink, let url = URL(string: link) {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(file.name)
                            .font(.mykSmall)
                            .foregroundStyle(MykColor.ink.color)
                            .lineLimit(1)
                        if let modifiedAt = file.modifiedAt {
                            Text(modifiedAt.formatted(.relative(presentation: .named)))
                                .font(.mykMono(9.5))
                                .foregroundStyle(MykColor.muted.color)
                        }
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.mykMono(10))
                        .foregroundStyle(MykColor.faint.color)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, MykSpace.s3)
    }
}
