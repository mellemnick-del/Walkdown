import SwiftUI

struct ReportView: View {
    let audit: Audit
    @AppStorage(SettingsKeys.companyName) private var companyName = ""
    @State private var pdfURL: URL?
    @State private var errorMessage: String?

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
                        .foregroundStyle(.orange)
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
                    Text(errorMessage).foregroundStyle(.red)
                } else {
                    HStack {
                        ProgressView()
                        Text("Building report")
                    }
                }
            } footer: {
                Text("The report is created on this device. Nothing is uploaded unless you share it.")
            }
        }
        .navigationTitle("Report")
        .task { build() }
    }

    private func build() {
        do {
            pdfURL = try ReportBuilder.makePDF(for: audit, companyName: companyName)
        } catch {
            errorMessage = "Couldn't build the report: \(error.localizedDescription)"
        }
    }
}
