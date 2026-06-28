import SwiftUI
import MykilosDesign
import MykilosServices

// MARK: - FilePreviewView (L17)
// Datei-Vorschau: Thumbnail (thumbnailLink) wenn vorhanden, sonst Type-Icon + Name.
// Öffnet Datei via webViewLink im Browser — kein Download, kein Schreiben.
// Requires drive.readonly scope for thumbnails (M5 — Re-Consent ausstehend).
public struct FilePreviewView: View {
    public let file: GoogleDriveFile
    public var showOpenButton: Bool = true

    public init(file: GoogleDriveFile, showOpenButton: Bool = true) {
        self.file = file
        self.showOpenButton = showOpenButton
    }

    public var body: some View {
        VStack(spacing: MykSpace.s4) {
            thumbnail
            info
            if showOpenButton, let link = file.webViewLink, let url = URL(string: link) {
                Button {
                    NSWorkspace.shared.open(url)
                } label: {
                    Label("Im Browser öffnen", systemImage: "arrow.up.right.square")
                        .font(.mykSmall)
                        .foregroundStyle(MykColor.drive.color)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(MykSpace.s5)
        .background(RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.paper2.color))
        .overlay(RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1))
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private var thumbnail: some View {
        if let thumbURL = file.thumbnailLink.flatMap({ URL(string: $0) }) {
            AsyncImage(url: thumbURL) { phase in
                switch phase {
                case .success(let img):
                    img.resizable()
                        .scaledToFit()
                        .frame(maxWidth: 280, maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: MykRadius.sm))
                case .failure:
                    typeIcon
                case .empty:
                    ProgressView().scaleEffect(0.7).frame(height: 60)
                @unknown default:
                    typeIcon
                }
            }
        } else {
            typeIcon
        }
    }

    private var typeIcon: some View {
        Image(systemName: file.iconName)
            .font(.system(size: 40))
            .foregroundStyle(MykColor.drive.color)
            .frame(height: 60)
    }

    // MARK: - Info

    private var info: some View {
        VStack(spacing: 2) {
            Text(file.name)
                .font(.mykBody)
                .foregroundStyle(MykColor.ink.color)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            HStack(spacing: MykSpace.s2) {
                Text(file.typeLabel)
                if let size = file.fileSize, size > 0 {
                    Text("·")
                    Text(file.fileSizeLabel)
                }
            }
            .font(.mykMono(9))
            .foregroundStyle(MykColor.muted.color)
        }
    }
}
