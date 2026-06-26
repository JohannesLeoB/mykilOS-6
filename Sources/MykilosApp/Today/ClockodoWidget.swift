import SwiftUI
import MykilosKit
import MykilosDesign
import MykilosWidgets
import MykilosServices

// MARK: - ClockodoWidget
// Zeitstatus für Heute, gruppiert nach Clockodos eigenen Kunden-/Projekt-
// namen (kein Versuch einer exakten Verknüpfung zu mykilOS-Projekten in V1,
// da dieses Widget ohnehin projektübergreifend aggregiert).
// ZEITEN-Regel: mykilOS ist Mapping-Layer — niemals zweite Zeit-Wahrheit.
struct ClockodoWidget: View {
    @State private var loader = ClockodoLoader()

    var body: some View {
        WidgetContainer(
            kind: .clockodo,
            sourceLabel: "CLOCKODO  ·  HEUTE",
            renderState: loader.renderState,
            projectID: "home"
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                widgetHeader
                VStack(alignment: .leading, spacing: 2) {
                    Text(loader.totalHoursText)
                        .font(.mykDisplay)
                        .foregroundStyle(MykColor.ink.color)
                    Text("heute gebucht")
                        .font(.mykMono(10))
                        .foregroundStyle(MykColor.muted.color)
                }
                Divider().overlay(MykColor.line.color)
                VStack(spacing: MykSpace.s3) {
                    ForEach(Array(loader.groups.enumerated()), id: \.element.label) { index, group in
                        TimeBar(
                            label: group.label.uppercased(),
                            value: group.hours,
                            total: max(loader.totalHours, group.hours),
                            color: groupColor(at: index)
                        )
                    }
                }
                Text("Quelle: Clockodo · Nur Anzeige, keine Buchung hier")
                    .font(.mykMono(9))
                    .foregroundStyle(MykColor.faint.color)
            }
        }
        .task {
            await loader.load()
        }
    }

    private var widgetHeader: some View {
        HStack {
            SourceChip(kind: .clockodo)
            Text("Zeit · Heute").mykWidgetTitle()
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
            Task { await loader.load() }
        }
        .font(.mykMono(9.5))
        .buttonStyle(.plain)
        .foregroundStyle(MykColor.tasks.color)
    }

    private func groupColor(at index: Int) -> Color {
        let palette = [MykColor.drive.color, MykColor.people.color, MykColor.cash.color, MykColor.personal.color]
        return palette[index % palette.count]
    }
}

// MARK: - ClockodoLoader
@MainActor
@Observable
private final class ClockodoLoader {
    struct Group { let label: String; let hours: Double }

    private(set) var groups: [Group] = []
    private(set) var renderState: WidgetRenderState = .loading

    private let client: ClockodoFetching

    init(client: ClockodoFetching = ClockodoClient()) {
        self.client = client
    }

    var totalHours: Double {
        groups.reduce(0) { $0 + $1.hours }
    }

    var totalHoursText: String {
        String(format: "%.1f h", totalHours).replacingOccurrences(of: ".", with: ",")
    }

    func load() async {
        renderState = .loading
        do {
            let entries = try await client.todaysEntries()
            groups = Self.grouped(entries)
            renderState = groups.isEmpty ? .empty : .content
        } catch ClockodoError.notConnected {
            groups = []
            renderState = .permissionRequired
        } catch {
            groups = []
            renderState = .error(String(describing: error))
        }
    }

    private static func grouped(_ entries: [ClockodoTimeEntry]) -> [Group] {
        var totals: [String: Int] = [:]
        var order: [String] = []
        for entry in entries {
            if totals[entry.label] == nil { order.append(entry.label) }
            totals[entry.label, default: 0] += entry.durationSeconds
        }
        return order.map { label in
            Group(label: label, hours: Double(totals[label] ?? 0) / 3600.0)
        }
    }
}

private struct TimeBar: View {
    let label: String
    let value: Double
    let total: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label).font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
                Spacer()
                Text(String(format: "%.1f h", value)).font(.mykMono(9.5)).foregroundStyle(MykColor.ink.color)
            }
            GeometryReader { geo in
                // total kann 0 sein (z. B. nur ein laufender Timer → duration 0):
                // value/total wäre dann NaN/∞ → ungültige Frame-Breite. Clampen.
                let ratio = total > 0 ? min(max(value / total, 0), 1) : 0
                ZStack(alignment: .leading) {
                    Capsule().fill(MykColor.bone.color).frame(height: 4)
                    Capsule().fill(color).frame(width: geo.size.width * ratio, height: 4)
                }
            }.frame(height: 4)
        }
    }
}

// MARK: - RecentActivityWidget
struct RecentActivityWidget: View {
    var body: some View {
        WidgetContainer(
            kind: .recentActivity,
            sourceLabel: "DRIVE + CLICKUP  ·  LETZTE AKTIVITÄT",
            renderState: .content,
            projectID: "home"
        ) {
            VStack(alignment: .leading, spacing: MykSpace.s5) {
                HStack {
                    SourceChip(kind: .recentActivity)
                    Text("Letzte Aktivität").mykWidgetTitle()
                    Spacer()
                }
                VStack(spacing: 0) {
                    ForEach(demoActivity, id: \.title) { item in
                        ActivityRow(item: item)
                        if item.title != demoActivity.last?.title {
                            Divider().overlay(MykColor.line.color.opacity(0.5))
                        }
                    }
                }
            }
        }
    }

    struct ActivityItem { let icon: String; let title: String; let sub: String; let color: Color }
    var demoActivity: [ActivityItem] {[
        ActivityItem(icon: "folder",    title: "Zeichnung Bartresen_v3.pdf", sub: "DRIVE · MEYER · vor 2 Std", color: MykColor.drive.color),
        ActivityItem(icon: "checklist", title: "Korpusmaße an Tischlerei",   sub: "CLICKUP · MEYER · vor 4 Std", color: MykColor.tasks.color),
        ActivityItem(icon: "folder",    title: "Moodboard Loft Küche.pdf",   sub: "DRIVE · LOFT · gestern",     color: MykColor.drive.color),
    ]}
}

private struct ActivityRow: View {
    let item: RecentActivityWidget.ActivityItem
    var body: some View {
        HStack(spacing: MykSpace.s4) {
            Image(systemName: item.icon)
                .font(.mykCaption)
                .foregroundStyle(item.color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title).font(.mykSmall).foregroundStyle(MykColor.ink.color).lineLimit(1)
                Text(item.sub).font(.mykMono(9.5)).foregroundStyle(MykColor.muted.color)
            }
        }
        .padding(.vertical, MykSpace.s3)
    }
}
