import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - SettingsView
// Akt 3, Schritt 1: nur das Google-OAuth-Fundament. Drive/Kalender/Mail live,
// Clockodo, Airtable-Sync folgen in eigenen Sessions.
struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var clientID: String = ""
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MykSpace.s7) {
                Text("Einstellungen")
                    .font(.mykDisplay)
                    .foregroundStyle(MykColor.ink.color)
                googleSection
                Spacer()
            }
            .padding(MykSpace.s9)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(MykColor.paper.color)
        .task {
            clientID = (try? appState.googleAuth.storedClientID()) ?? ""
        }
    }

    private var googleSection: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            Text("Google Workspace")
                .font(.mykHeadline)
                .foregroundStyle(MykColor.ink.color)
            statusBadge
            TextField("OAuth-Client-ID (Desktop App)", text: $clientID)
                .textFieldStyle(.roundedBorder)
                .font(.mykMono(12))
            HStack(spacing: MykSpace.s4) {
                Button(connectLabel) { connect() }
                    .disabled(appState.googleAuth.status == .connecting)
                if appState.googleAuth.status == .connected {
                    Button("Trennen", role: .destructive) { disconnect() }
                }
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.critical.color)
            }
            Text("Nur Lesezugriff (Drive-Metadaten, Kalender, Gmail, Kontakte) — keine Schreibrechte.")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.faint.color)
        }
        .padding(MykSpace.s6)
        .background(
            RoundedRectangle(cornerRadius: MykRadius.md).fill(MykColor.card.color)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MykRadius.md).stroke(MykColor.line.color, lineWidth: 1)
        )
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle().fill(statusColor).frame(width: 7, height: 7)
            Text(statusText).font(.mykMono(10)).foregroundStyle(MykColor.muted.color)
        }
    }

    private var statusColor: Color {
        switch appState.googleAuth.status {
        case .connected:    MykColor.positive.color
        case .connecting:   MykColor.tasks.color
        case .disconnected: MykColor.faint.color
        case .error:        MykColor.critical.color
        }
    }

    private var statusText: String {
        switch appState.googleAuth.status {
        case .connected:          "VERBUNDEN"
        case .connecting:         "VERBINDET…"
        case .disconnected:       "NICHT VERBUNDEN"
        case .error(let message): "FEHLER · \(message)"
        }
    }

    private var connectLabel: String {
        switch appState.googleAuth.status {
        case .connected:  "Erneut verbinden"
        case .connecting: "Verbindet…"
        default:          "Verbinden"
        }
    }

    private func connect() {
        errorMessage = nil
        let clientID = self.clientID
        Task {
            do {
                try await appState.googleAuth.startAuthorization(clientID: clientID)
            } catch {
                errorMessage = "Verbindung fehlgeschlagen: \(error)"
            }
        }
    }

    private func disconnect() {
        do {
            try appState.googleAuth.disconnect()
        } catch {
            errorMessage = "Trennen fehlgeschlagen: \(error)"
        }
    }
}
