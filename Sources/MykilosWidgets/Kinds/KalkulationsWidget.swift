import SwiftUI
import MykilosKit
import MykilosDesign

// MARK: - KalkulationsWidget
// Der Schätz-Brain. Gibt Min/Mitte/Max-Netto plus Konfidenz und Top-Evidenzen aus.
// Abhängigkeit nur über Protokoll — kein GRDB, kein direkter Store-Zugriff.
public struct KalkulationsWidget: View {
    public let projektID: String
    public let engine: any KalkulationsEngineProviding

    public init(projektID: String, engine: any KalkulationsEngineProviding) {
        self.projektID = projektID
        self.engine   = engine
    }

    @State private var freitext: String = ""
    @State private var state: KalkulationsRenderState = .empty

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
            sourceRow
        }
        .background(MykColor.paper2.color)
        .clipShape(RoundedRectangle(cornerRadius: MykRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: MykRadius.md)
                .stroke(MykColor.tasks.color.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: Hauptinhalt

    private var content: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            // Header
            HStack {
                SourceChip(kind: .kalkulation)
                Text("Kalkulation")
                    .mykWidgetTitle()
                    .foregroundStyle(MykColor.ink.color)
                Spacer()
                confidenceBadge
            }

            // Eingabefeld
            freitextField

            // Ergebnis-Bereich
            resultArea
        }
        .padding(MykSpace.s6)
    }

    // MARK: Freitext-Eingabe

    private var freitextField: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            TextField("Projektbeschreibung eingeben …", text: $freitext, axis: .vertical)
                .font(.mykBody)
                .foregroundStyle(MykColor.ink.color)
                .lineLimit(3...6)
                .textFieldStyle(.plain)
                .padding(MykSpace.s4)
                .background(
                    RoundedRectangle(cornerRadius: MykRadius.sm)
                        .fill(MykColor.card.color)
                        .overlay(
                            RoundedRectangle(cornerRadius: MykRadius.sm)
                                .stroke(MykColor.line.color, lineWidth: 1)
                        )
                )

            Button {
                Task { await schaetzen() }
            } label: {
                HStack(spacing: MykSpace.s3) {
                    if case .loading = state {
                        ProgressView().controlSize(.small)
                            .tint(MykColor.tasks.color)
                    }
                    Text(freitext.trimmingCharacters(in: .whitespaces).isEmpty
                         ? "Schätzen"
                         : "Neu schätzen")
                        .font(.mykSmall).fontWeight(.semibold)
                        .foregroundStyle(MykColor.paper.color)
                }
                .padding(.horizontal, MykSpace.s5)
                .padding(.vertical, MykSpace.s3)
                .background(
                    RoundedRectangle(cornerRadius: MykRadius.sm)
                        .fill(freitext.trimmingCharacters(in: .whitespaces).isEmpty
                              ? MykColor.faint.color
                              : MykColor.tasks.color)
                )
            }
            .buttonStyle(.plain)
            .disabled(freitext.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: Ergebnis-Bereich

    @ViewBuilder
    private var resultArea: some View {
        switch state {
        case .empty:
            Text("Beschreibe das Projekt, um eine Schätzung zu erhalten.")
                .font(.mykSmall)
                .foregroundStyle(MykColor.muted.color)

        case .loading:
            HStack(spacing: MykSpace.s3) {
                ProgressView().controlSize(.small).tint(MykColor.tasks.color)
                Text("Schätzung läuft …")
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.muted.color)
            }

        case .content(let schaetzung):
            KalkulationsResultView(schaetzung: schaetzung)

        case .error(let msg):
            HStack(spacing: MykSpace.s3) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(MykColor.critical.color)
                Text(msg)
                    .font(.mykSmall)
                    .foregroundStyle(MykColor.critical.color)
            }
        }
    }

    // MARK: Konfidenz-Badge

    @ViewBuilder
    private var confidenceBadge: some View {
        if case .content(let s) = state {
            let pct = Int(s.confidence * 100)
            let color: Color = s.confidence >= 0.7
                ? MykColor.positive.color
                : (s.confidence >= 0.4 ? MykColor.tasks.color : MykColor.critical.color)
            Text("\(pct) %")
                .font(.mykMono(10))
                .foregroundStyle(color)
                .padding(.horizontal, MykSpace.s4)
                .padding(.vertical, MykSpace.s2)
                .background(Capsule().fill(color.opacity(0.12)))
        }
    }

    // MARK: Quellenzeile

    private var sourceRow: some View {
        HStack(spacing: 8) {
            Circle().fill(MykColor.tasks.color).frame(width: 5, height: 5)
            Text("KALKULATION  ·  BASELINE-ANKER")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)
            Spacer()
        }
        .padding(.horizontal, MykSpace.s6)
        .padding(.vertical, MykSpace.s4)
        .overlay(alignment: .top) {
            Divider().overlay(MykColor.line.color)
        }
    }

    // MARK: Engine-Aufruf

    private func schaetzen() async {
        let text = freitext.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { state = .empty; return }
        state = .loading
        do {
            let ergebnis = try await engine.schaetze(projektID: projektID, freitext: text)
            state = .content(ergebnis)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

// MARK: - KalkulationsRenderState

private enum KalkulationsRenderState {
    case empty
    case loading
    case content(KostenSchaetzung)
    case error(String)
}

// MARK: - KalkulationsResultView

private struct KalkulationsResultView: View {
    let schaetzung: KostenSchaetzung

    var body: some View {
        VStack(alignment: .leading, spacing: MykSpace.s5) {
            preisRange
            if !schaetzung.topEvidences.isEmpty {
                evidences
            }
            metaRow
        }
    }

    // Min / Mitte / Max

    private var preisRange: some View {
        HStack(spacing: 0) {
            PreisSaeule(label: "Min", betrag: schaetzung.minNetto, accent: MykColor.people.color)
            Divider().frame(height: 48).overlay(MykColor.line.color).padding(.horizontal, MykSpace.s4)
            PreisSaeule(label: "Mitte", betrag: schaetzung.mitteNetto, accent: MykColor.tasks.color, prominent: true)
            Divider().frame(height: 48).overlay(MykColor.line.color).padding(.horizontal, MykSpace.s4)
            PreisSaeule(label: "Max", betrag: schaetzung.maxNetto, accent: MykColor.drive.color)
            Spacer()
        }
    }

    // Top-Evidenzen

    private var evidences: some View {
        VStack(alignment: .leading, spacing: MykSpace.s3) {
            Text("Quellen")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)
            ForEach(Array(schaetzung.topEvidences.prefix(3).enumerated()), id: \.offset) { _, ev in
                EvidenceRow(evidence: ev)
            }
        }
    }

    // Kostenboden & Evidenz-Anzahl

    private var metaRow: some View {
        HStack(spacing: MykSpace.s5) {
            Label {
                Text(formatPreis(schaetzung.kostenboden))
                    .font(.mykMono(10))
                    .foregroundStyle(MykColor.inkSoft.color)
            } icon: {
                Text("Kostenboden")
                    .font(.mykMono(9.5))
                    .foregroundStyle(MykColor.muted.color)
            }
            Spacer()
            Text("\(schaetzung.evidenceCount) Evidenzen")
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)
        }
    }

    // MARK: Hilfsmethoden

    private func formatPreis(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "–"
    }
}

// MARK: - PreisSaeule

private struct PreisSaeule: View {
    let label: String
    let betrag: Double
    var accent: Color = MykColor.tasks.color
    var prominent: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.mykMono(9.5))
                .foregroundStyle(MykColor.muted.color)
            Text(formattedBetrag)
                .font(prominent ? .mykTitle : .mykHeadline)
                .foregroundStyle(prominent ? accent : MykColor.inkSoft.color)
        }
    }

    private var formattedBetrag: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: betrag)) ?? "–"
    }
}

// MARK: - EvidenceRow

private struct EvidenceRow: View {
    let evidence: PriceEvidence

    var body: some View {
        HStack(spacing: MykSpace.s3) {
            RoundedRectangle(cornerRadius: 3)
                .fill(MykColor.tasks.color.opacity(0.2))
                .frame(width: 3, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(evidence.lieferant)
                        .font(.mykSmall).fontWeight(.medium)
                        .foregroundStyle(MykColor.inkSoft.color)
                    Text("·")
                        .font(.mykMono(9.5))
                        .foregroundStyle(MykColor.faint.color)
                    Text(evidence.dokument)
                        .font(.mykMono(9.5))
                        .foregroundStyle(MykColor.muted.color)
                        .lineLimit(1)
                }
                Text(evidence.originalZitat)
                    .font(.mykCaption)
                    .foregroundStyle(MykColor.muted.color)
                    .lineLimit(1)
            }
            Spacer()
            Text(formatPreis(evidence.nettoPreis))
                .font(.mykMono(10))
                .foregroundStyle(MykColor.tasks.color)
        }
    }

    private func formatPreis(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "–"
    }
}
