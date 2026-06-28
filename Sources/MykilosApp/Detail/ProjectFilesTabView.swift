import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosServices
import MykilosWidgets

// MARK: - ProjectFilesTabView
// Zeigt Drive-Inhalte des Projekt-Ordners. Unterordner sind anklickbar.
// Schreibt NIE in Drive — nur lesen + im Browser öffnen.
struct ProjectFilesTabView: View {
    let project: Project

    @State private var loader = DriveTabLoader()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch loader.renderState {
            case .loading:
                loadingView
            case .permissionRequired:
                permissionView
            case .empty:
                emptyView
            case .error(let msg):
                errorView(msg)
            case .offline:
                errorView("Keine Verbindung")
            case .content:
                contentView
            }
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.top, MykSpace.s7)
        .padding(.bottom, 64)
        .task(id: loader.currentFolderID) {
            await loader.load()
        }
        .onAppear {
            loader.setRoot(project.links.driveFolderID)
        }
    }

    // MARK: States

    private var loadingView: some View {
        HStack { Spacer(); ProgressView(); Spacer() }
            .padding(.top, 60)
    }

    private var permissionView: some View {
        VStack(spacing: MykSpace.s5) {
            Spacer().frame(height: 48)
            Image(systemName: "lock.icloud")
                .font(.system(size: 32))
                .foregroundStyle(MykColor.drive.color)
            Text("Google Drive nicht verbunden")
                .font(.mykBody)
                .foregroundStyle(MykColor.ink.color)
            Text("Verbinde Google in den Einstellungen, um Projektdateien zu sehen.")
                .font(.mykCaption)
                .foregroundStyle(MykColor.muted.color)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: MykSpace.s5) {
            Spacer().frame(height: 48)
            Image(systemName: "folder")
                .font(.system(size: 32))
                .foregroundStyle(MykColor.drive.color.opacity(0.4))
            Text(loader.breadcrumb.isEmpty ? "Kein Drive-Ordner verknüpft" : "Ordner leer")
                .font(.mykBody)
                .foregroundStyle(MykColor.muted.color)
            if loader.breadcrumb.isEmpty {
                Text("Trage die Drive-Ordner-ID im Airtable-Projekt ein.")
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.muted.color)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: MykSpace.s5) {
            Spacer().frame(height: 48)
            Image(systemName: "exclamationmark.icloud")
                .font(.system(size: 32))
                .foregroundStyle(MykColor.critical.color)
            Text("Drive konnte nicht geladen werden")
                .font(.mykBody)
                .foregroundStyle(MykColor.ink.color)
            Text(message)
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)
                .multilineTextAlignment(.center)
            Button("Erneut versuchen") {
                Task { await loader.load() }
            }
            .font(.mykSmall)
            .buttonStyle(.plain)
            .foregroundStyle(MykColor.drive.color)
        }
        .frame(maxWidth: .infinity)
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            breadcrumbBar
            Divider().overlay(MykColor.line.color)
            fileListContent
            sourceLine
        }
    }

    // MARK: Breadcrumb

    private var breadcrumbBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                Button {
                    loader.navigateToRoot()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.mykMono(10))
                        Text(project.links.driveFolderID == nil ? "Drive" : "Projekt")
                            .font(.mykSmall)
                    }
                    .foregroundStyle(loader.breadcrumb.isEmpty ? MykColor.drive.color : MykColor.muted.color)
                }
                .buttonStyle(.plain)

                ForEach(Array(loader.breadcrumb.enumerated()), id: \.offset) { idx, crumb in
                    Image(systemName: "chevron.right")
                        .font(.mykMono(9))
                        .foregroundStyle(MykColor.muted.color)
                    Button {
                        loader.navigateToBreadcrumb(index: idx)
                    } label: {
                        Text(crumb.name)
                            .font(.mykSmall)
                            .foregroundStyle(idx == loader.breadcrumb.count - 1 ? MykColor.drive.color : MykColor.muted.color)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, MykSpace.s4)
        }
    }

    // MARK: File list

    private var fileListContent: some View {
        VStack(spacing: 0) {
            ForEach(loader.items) { item in
                DriveTabRow(item: item) {
                    if item.isFolder {
                        loader.navigateInto(item)
                    } else if let link = item.webViewLink, let url = URL(string: link) {
                        NSWorkspace.shared.open(url)
                    }
                }
                Divider().overlay(MykColor.line.color.opacity(0.5))
            }
        }
    }

    private var sourceLine: some View {
        HStack(spacing: 6) {
            Circle().fill(MykColor.drive.color).frame(width: 5, height: 5)
            Text("GOOGLE DRIVE  ·  \(loader.items.count) EINTRÄGE  ·  LESEN")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)
            Spacer()
        }
        .padding(.top, MykSpace.s5)
    }
}

// MARK: - DriveTabRow

private struct DriveTabRow: View {
    let item: GoogleDriveFile
    let onTap: () -> Void

    @State private var hovered = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: MykSpace.s5) {
                Image(systemName: item.iconName)
                    .font(.system(size: 15))
                    .foregroundStyle(item.isFolder ? MykColor.drive.color : MykColor.muted.color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.mykBody)
                        .foregroundStyle(MykColor.ink.color)
                        .lineLimit(1)
                    if let modified = item.modifiedAt, !item.isFolder {
                        Text(modified.formatted(.relative(presentation: .named)))
                            .font(.mykMono(9.5))
                            .foregroundStyle(MykColor.muted.color)
                    }
                }

                Spacer()

                if item.isFolder {
                    Image(systemName: "chevron.right")
                        .font(.mykCaption)
                        .foregroundStyle(MykColor.muted.color)
                } else {
                    Image(systemName: "arrow.up.right.square")
                        .font(.mykCaption)
                        .foregroundStyle(MykColor.muted.color.opacity(hovered ? 1 : 0))
                }
            }
            .padding(.vertical, MykSpace.s4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}

// MARK: - DriveTabLoader

@MainActor
@Observable
private final class DriveTabLoader {
    struct BreadcrumbEntry {
        let name: String
        let folderID: String
    }

    private(set) var items: [GoogleDriveFile] = []
    private(set) var renderState: WidgetRenderState = .loading
    private(set) var breadcrumb: [BreadcrumbEntry] = []
    private(set) var currentFolderID: String?

    private var rootFolderID: String?
    private let client: GoogleDriveFetching

    init(client: GoogleDriveFetching = GoogleDriveClient()) {
        self.client = client
    }

    func setRoot(_ folderID: String?) {
        guard rootFolderID == nil else { return }
        rootFolderID = folderID
        currentFolderID = folderID
    }

    func load() async {
        guard let folderID = currentFolderID, !folderID.isEmpty else {
            items = []; renderState = .empty; return
        }
        renderState = .loading
        do {
            let result = try await client.listFolder(folderID: folderID)
            // Ordner zuerst, dann Dateien; alphabetisch je Gruppe
            items = result.sorted {
                if $0.isFolder != $1.isFolder { return $0.isFolder }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            renderState = items.isEmpty ? .empty : .content
        } catch GoogleDriveError.notConnected {
            items = []; renderState = .permissionRequired
        } catch {
            items = []; renderState = .error(error.localizedDescription)
        }
    }

    func navigateInto(_ folder: GoogleDriveFile) {
        breadcrumb.append(BreadcrumbEntry(name: folder.name, folderID: folder.id))
        currentFolderID = folder.id
    }

    func navigateToBreadcrumb(index: Int) {
        breadcrumb = Array(breadcrumb.prefix(index + 1))
        currentFolderID = breadcrumb.last?.folderID ?? rootFolderID
    }

    func navigateToRoot() {
        breadcrumb = []
        currentFolderID = rootFolderID
    }
}

// MARK: - Helper

private extension GoogleDriveFile {
    var isFolder: Bool { mimeType == "application/vnd.google-apps.folder" }
}
