import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosServices

// MARK: - AssistantWidget
// Der Dolmetscher. Liest alle Signale des Projekts, formt Insights, schlägt vor.
// Dunkel, dominant, 3 Spalten breit. Schreibt NIE ohne Freigabe.
public struct AssistantWidget: View {
    public let projectID: String
    public let auditStore: AuditStore?
    public let llmProvider: (any AssistantLLMProviding)?

    public init(
        projectID: String,
        auditStore: AuditStore? = nil,
        llmProvider: (any AssistantLLMProviding)? = nil
    ) {
        self.projectID = projectID
        self.auditStore = auditStore
        self.llmProvider = llmProvider
    }

    @Environment(StudioContext.self) private var context
    @State private var confirmedIDs: Set<UUID> = []
    @State private var auditError: String?
    @State private var llmSummaryState: LLMSummaryState = .idle

    private var signals: [WidgetSignal] {
        context.signals(for: projectID)
    }

    private var insights: [AssistantInsight] {
        AssistantEngine().generateInsights(
            projectID: projectID,
            signals: signals
        )
    }

    private var llmTaskID: String {
        signals.map(String.init(describing:)).joined(separator: "|")
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
            sourceLineAssistant
        }
        .background(
            LinearGradient(
                colors: [MykColor.ink.color, MykColor.inkSoft.color.opacity(0.6)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.md))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 4)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            HStack {
                SourceChip(kind: .assistant)
                Text("Assistent").mykWidgetTitle().foregroundStyle(MykColor.paper.color.opacity(0.55))
                Spacer()
                priorityBadge
            }
            llmSummary
            insightsList
        }
        .padding(MykSpace.s6)
        .task(id: llmTaskID) {
            await loadLLMSummary()
        }
    }

    @ViewBuilder
    private var priorityBadge: some View {
        let highest = insights.map(\.priority).max() ?? .info
        switch highest {
        case .urgent:
            PriorityChip(label: "DRINGEND", color: MykColor.critical.color)
        case .attention:
            PriorityChip(label: "HINWEIS", color: MykColor.tasks.color)
        case .info:
            EmptyView()
        }
    }

    private var insightsList: some View {
        VStack(alignment: .leading, spacing: MykSpace.s4) {
            ForEach(insights) { insight in
                InsightRow(
                    insight: insight,
                    isConfirmed: confirmedIDs.contains(insight.id),
                    auditState: auditStore?.saveState ?? .idle,
                    auditError: auditError,
                    onConfirm: { action in confirm(insight: insight, action: action) }
                )
            }
        }
    }

    @ViewBuilder
    private var llmSummary: some View {
        if llmProvider != nil {
            switch llmSummaryState {
            case .idle:
                EmptyView()
            case .loading:
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Claude fasst die Signale zusammen…")
                        .font(.mykMono(9.5))
                        .foregroundStyle(MykColor.paper.color.opacity(0.45))
                }
            case .loaded(let summary):
                Text(summary)
                    .font(.mykBody)
                    .foregroundStyle(MykColor.paper.color.opacity(0.88))
                    .padding(MykSpace.s4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: MykRadius.sm)
                            .fill(MykColor.paper.color.opacity(0.08))
                    )
            case .failed(let message):
                Text(message)
                    .font(.mykMono(9.5))
                    .foregroundStyle(MykColor.tasks.color)
            }
        }
    }

    private func loadLLMSummary() async {
        guard let llmProvider else {
            llmSummaryState = .idle
            return
        }
        let currentInsights = insights
        let currentSignals = signals
        llmSummaryState = .loading
        do {
            let summary = try await llmProvider.summarize(
                projectID: projectID,
                signals: currentSignals,
                insights: currentInsights
            )
            llmSummaryState = .loaded(summary)
        } catch {
            llmSummaryState = .failed("Claude-Zusammenfassung gerade nicht verfügbar")
        }
    }

    private func confirm(insight: AssistantInsight, action: SuggestedAction) {
        auditError = nil
        do {
            if let auditStore {
                let entry = AuditEntry(
                    actorUserID: "local-user",
                    projectID: projectID,
                    action: action.auditAction,
                    summary: action.auditSummary
                )
                try auditStore.append(entry)
            }
            withAnimation(.easeInOut(duration: 0.2)) {
                _ = confirmedIDs.insert(insight.id)
            }
        } catch {
            auditError = error.localizedDescription
        }
    }

    private var sourceLineAssistant: some View {
        HStack(spacing: 8) {
            Circle().fill(MykColor.positive.color).frame(width: 5, height: 5)
            Text("LIEST: DRIVE · CASH · KALENDER · CLOCKODO · MAIL  ·  SCHREIBT NICHTS OHNE FREIGABE")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.paper.color.opacity(0.4))
            Spacer()
        }
        .padding(.horizontal, MykSpace.s6).padding(.vertical, MykSpace.s4)
        .overlay(alignment: .top) {
            Divider().overlay(MykColor.paper.color.opacity(0.1))
        }
    }
}

// MARK: - LLMSummaryState

private enum LLMSummaryState: Equatable {
    case idle
    case loading
    case loaded(String)
    case failed(String)
}

// MARK: - InsightRow

private struct InsightRow: View {
    let insight: AssistantInsight
    let isConfirmed: Bool
    let auditState: SaveState
    let auditError: String?
    let onConfirm: (SuggestedAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            HStack(spacing: 6) {
                priorityDot
                Text(insight.summary)
                    .font(.mykBody)
                    .foregroundStyle(MykColor.paper.color.opacity(0.96))
            }
            if let detail = insight.detail {
                Text(detail)
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.paper.color.opacity(0.6))
            }
            if let action = insight.suggestedAction {
                actionButtons(action: action)
            }
        }
        .padding(.vertical, MykSpace.s3)
    }

    private var priorityDot: some View {
        Circle()
            .fill(dotColor)
            .frame(width: 6, height: 6)
    }

    private var dotColor: Color {
        switch insight.priority {
        case .urgent:    MykColor.critical.color
        case .attention: MykColor.tasks.color
        case .info:      MykColor.faint.color
        }
    }

    @ViewBuilder
    private func actionButtons(action: SuggestedAction) -> some View {
        if isConfirmed {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(MykColor.positive.color)
                Text(auditStatusText)
                    .font(.mykMono(9.5))
                    .foregroundStyle(MykColor.paper.color.opacity(0.5))
            }
        } else {
            HStack(spacing: MykSpace.s4) {
                Button {
                    onConfirm(action)
                } label: {
                    Text(action.label)
                        .font(.mykSmall).fontWeight(.semibold)
                        .foregroundStyle(MykColor.ink.color)
                        .padding(.horizontal, MykSpace.s5).padding(.vertical, MykSpace.s3)
                        .background(RoundedRectangle(cornerRadius: MykRadius.sm).fill(MykColor.paper.color))
                }
                .buttonStyle(.plain)
            }
        }
        if let auditError {
            Text(auditError)
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.critical.color)
        }
    }

    private var auditStatusText: String {
        switch auditState {
        case .idle:
            "Bestätigt"
        case .saving:
            "Bestätigt — Audit speichert…"
        case .saved:
            "Bestätigt — Audit gespeichert"
        case .failed:
            "Bestätigt — Audit fehlgeschlagen"
        }
    }
}

// MARK: - PriorityChip

private struct PriorityChip: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.mykMono(9))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(color.opacity(0.15))
            )
    }
}
