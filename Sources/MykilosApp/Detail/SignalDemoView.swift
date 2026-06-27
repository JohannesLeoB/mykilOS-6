import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - SignalDemoView
// Sichtbarer Sofort-Check der Widget-Kommunikation in der Detailseite.
// "Drive meldet Angebot" — der Nutzer sieht, wie das Cash-Widget reagiert.
// Löst einen echten DriveOfferWatcher-Poll gegen den verlinkten Drive-Ordner
// aus (denselben Watcher, der ohnehin alle 60 s im Hintergrund pollt, siehe
// ProjectDetailView) statt Fake-Signale zu emittieren.
struct SignalDemoView: View {
    let projectID: String
    let driveFolderID: String?
    @Environment(AppState.self) private var appState
    @Environment(StudioContext.self) private var context
    @State private var isPolling = false
    @State private var lastResultCount: Int?

    var body: some View {
        HStack(spacing: MykSpace.s5) {
            // Status-Punkt
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
                .animation(.easeInOut(duration: 0.3), value: isPolling)
            Text(statusText)
                .font(.mykMono(10))
                .foregroundStyle(MykColor.muted.color)
            Spacer()
            if let driveFolderID, driveFolderID.isEmpty == false {
                Button("Jetzt prüfen") {
                    Task { await forcePoll(folderID: driveFolderID) }
                }
                .font(.mykSmall).foregroundStyle(MykColor.drive.color)
                .buttonStyle(.plain)
                .disabled(isPolling)
            }
        }
        .padding(.horizontal, MykSpace.s9)
        .padding(.vertical, MykSpace.s4)
        .background(MykColor.paper2.color)
        .overlay(alignment: .bottom) { Divider().overlay(MykColor.line.color) }
    }

    private var statusColor: Color {
        if isPolling { return MykColor.tasks.color }
        if let lastResultCount, lastResultCount > 0 { return MykColor.drive.color }
        return MykColor.faint.color
    }

    private var statusText: String {
        if isPolling { return "Prüfe Drive-Ordner …" }
        if let lastResultCount {
            return lastResultCount > 0
                ? "\(lastResultCount) neues Signal — Cash-Widget zeigt Review-Vorschlag"
                : "Keine neuen Angebote im Drive-Ordner"
        }
        return driveFolderID == nil || driveFolderID?.isEmpty == true
            ? "Kein Drive-Ordner verlinkt"
            : "Drive-Ordner noch nicht geprüft"
    }

    private func forcePoll(folderID: String) async {
        isPolling = true
        let watcher = appState.offerWatcher(for: projectID)
        let signals = await watcher.poll(projectID: projectID, folderID: folderID)
        withAnimation {
            for signal in signals { context.emit(signal) }
            lastResultCount = signals.count
            isPolling = false
        }
    }
}
