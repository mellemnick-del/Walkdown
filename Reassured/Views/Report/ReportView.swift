import SwiftUI
import Charts

struct ReportView: View {
    let audit: Audit
    @AppStorage(SettingsKeys.companyName) private var companyName = ""
    @State private var pdfURL: URL?
    @State private var errorMessage: String?
    @State private var summary = ""
    @State private var writingSummary = false

    var body: some View {
        List {
            Section("Overview") {
                LabeledContent("Client", value: audit.displayName)
                LabeledContent("Checklist", value: audit.checklistName)
                LabeledContent("Completed", value: "\(audit.answeredCount) of \(audit.totalCount)")
                LabeledContent("Score", value: audit.score.map { "\(Int(($0 * 100).rounded()))%" } ?? "n/a")
            }

            if audit.answeredCount < audit.totalCount {
                Section {
                    Label("\(audit.totalCount - audit.answeredCount) controls are still not started. They'll show as Not Started in the report.",
                          systemImage: "exclamationmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(Theme.calmAmber)
                }
            }

            if AuditWriter.isAvailable || !summary.isEmpty {
                Section {
                    TextField("A short overview for the client", text: $summary, axis: .vertical)
                        .lineLimit(4...14)
                    if AuditWriter.isAvailable {
                        Button {
                            Task { await writeSummary() }
                        } label: {
                            HStack {
                                Label(summary.isEmpty ? "Write with Apple Intelligence" : "Rewrite with Apple Intelligence", systemImage: "sparkles")
                                if writingSummary { Spacer(); ProgressView() }
                            }
                        }
                        .disabled(writingSummary)
                    }
                } header: {
                    Text("Executive Summary")
                } footer: {
                    Text("Appears at the top of the report summary. Written on this device; review it before sharing.")
                }
            }

            let areas = areaScores
            if !areas.isEmpty {
                Section("Score by Area") {
                    Chart(areas, id: \.name) { area in
                        BarMark(
                            x: .value("Score", area.score * 100),
                            y: .value("Area", area.name)
                        )
                        .foregroundStyle(area.score >= 0.8 ? Theme.calmGreen : area.score >= 0.5 ? Theme.calmAmber : Theme.calmCoral)
                        .annotation(position: .trailing) {
                            Text("\(Int((area.score * 100).rounded()))%")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .chartXScale(domain: 0...100)
                    .chartXAxis(.hidden)
                    .frame(height: CGFloat(areas.count) * 34 + 10)
                    .padding(.vertical, 6)
                }
            }

            Section("Findings") {
                let findings = audit.findings ?? []
                if findings.isEmpty {
                    Text("No findings").foregroundStyle(.secondary)
                } else {
                    ForEach(Severity.allCases) { severity in
                        let count = findings.filter { $0.severity == severity }.count
                        if count > 0 {
                            HStack {
                                SeverityBadge(severity: severity)
                                Spacer()
                                Text("\(count)").monospacedDigit()
                            }
                        }
                    }
                }
            }

            Section {
                if let pdfURL {
                    ShareLink(item: pdfURL) {
                        Label("Share PDF Report", systemImage: "square.and.arrow.up")
                    }
                } else if let errorMessage {
                    Text(errorMessage).foregroundStyle(Theme.calmCoral)
                } else {
                    HStack {
                        ProgressView()
                        Text("Building report")
                    }
                }
            } footer: {
                Text("The report is created on this device. Nothing is uploaded unless you share it.\n\n\(ReportBuilder.disclaimer)")
            }
        }
        .calmBackground()
        .navigationTitle("Report")
        .task {
            summary = AuditWriter.savedSummary(for: audit)
            build()
        }
        .task(id: summary) {
            // Wait for typing to pause before saving and rebuilding the PDF.
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            AuditWriter.saveSummary(summary, for: audit)
            build()
        }
    }

    /// Score per area, in checklist order, for areas with at least one scored control.
    private var areaScores: [(name: String, score: Double)] {
        var names: [String] = []
        for control in audit.sortedControls where !names.contains(control.groupName) {
            names.append(control.groupName)
        }
        return names.compactMap { name in
            let controls = audit.sortedControls.filter { $0.groupName == name }
            return ComplianceScore.score(for: controls).map { (name: name, score: $0) }
        }
    }

    private func writeSummary() async {
        writingSummary = true
        defer { writingSummary = false }
        if let text = await AuditWriter.executiveSummary(for: audit) { summary = text }
    }

    private func build() {
        do {
            pdfURL = try ReportBuilder.makePDF(for: audit, companyName: companyName, summary: summary)
        } catch {
            errorMessage = "Couldn't build the report: \(error.localizedDescription)"
        }
    }
}
