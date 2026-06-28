import SwiftUI
import AppKit
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - DriveWidget
// Dateien & Zeichnungen, lesend aus dem im Projekt verlinkten Drive-Ordner
// (Project.links.driveFolderID). Nie Schreiben, nie Inhalte herunterladen —
// nur Metadaten + Link zum Öffnen im Browser.
public struct DriveWidget: View {
    public let projectID: String
    public let driveFolderID: String?

    public init(projectID: String, driveFolderID: String?) {
        self.projectID = projectID
        self.driveFolderID = driveFolderID
    }

    @State private var loader = DriveFolderLoader()
    @Environment(StudioContext.self) private var context

    public var body: some View {
        WidgetContainer(
            kind: .drive,
            sourceLabel: sourceLabel,
            renderState: loader.renderState,
            projectID: projectID
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                widgetHeader
                fileList
            }
        }
        .task(id: driveFolderID) {
            await loader.load(folderID: driveFolderID)
            emitDriveSignals()
        }
    }

    private func emitDriveSignals() {
        guard case .content = loader.renderState else { return }
        // Neueste Datei (keine Ordner) als Signal — Assistent sieht sie
        let files = loader.files.filter { $0.mimeType != "application/vnd.google-apps.folder" }
        if let newest = files.sorted(by: { ($0.modifiedAt ?? .distantPast) > ($1.modifiedAt ?? .distantPast) }).first {
            context.emit(.driveFileAdded(projectID: projectID, fileName: newest.name))
        }
    }

    private var sourceLabel: String {
        switch loader.renderState {
        case .content: "DRIVE  ·  \(loader.files.count) DATEIEN"
        default:       "DRIVE"
        }
    }

    private var widgetHeader: some View {
        HStack {
            SourceChip(kind: .drive)
            Text("Zeichnungen & Pläne").mykWidgetTitle()
            Spacer()
            if case .error = loader.renderState {
                retryButton
            } else if case .permissionRequired = loader.renderState {
                retryButton
            }
        }
    }

    private var retryButton: some View {
        Button("Erneut versuchen") {
            Task { await loader.load(folderID: driveFolderID) }
        }
        .font(.mykMono(9.5))
        .buttonStyle(.plain)
        .foregroundStyle(MykColor.drive.color)
    }

    private var fileList: some View {
        VStack(spacing: 0) {
            ForEach(loader.files) { file in
                DriveFileRow(file: file)
                if file.id != loader.files.last?.id {
                    Divider().overlay(MykColor.line.color.opacity(0.6))
                }
            }
        }
    }
}

// MARK: - DriveFolderLoader
// Pro Widget-Instanz, kein geteilter Zustand nötig — Drive-Daten sind reine
// Lesefetches, kein Speichern-Vertrag wie bei NoteStore/WidgetBoardStore.
@MainActor
@Observable
private final class DriveFolderLoader {
    private(set) var files: [GoogleDriveFile] = []
    private(set) var renderState: WidgetRenderState = .loading

    private let client: GoogleDriveFetching

    init(client: GoogleDriveFetching = GoogleDriveClient()) {
        self.client = client
    }

    func load(folderID: String?) async {
        guard let folderID, folderID.isEmpty == false else {
            files = []
            renderState = .empty
            return
        }
        renderState = .loading
        do {
            let result = try await client.listFolder(folderID: folderID)
            files = result
            renderState = result.isEmpty ? .empty : .content
        } catch GoogleDriveError.notConnected {
            files = []
            renderState = .permissionRequired
        } catch {
            files = []
            renderState = .error(String(describing: error))
        }
    }
}

// MARK: - DriveFileRow
private struct DriveFileRow: View {
    let file: GoogleDriveFile

    var body: some View {
        Button {
            if let link = file.webViewLink, let url = URL(string: link) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(spacing: MykSpace.s4) {
                Image(systemName: file.iconName)
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.drive.color)
                    .frame(width: 20)
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
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, MykSpace.s3)
    }
}
