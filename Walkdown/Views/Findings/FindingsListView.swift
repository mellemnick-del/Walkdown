import SwiftUI
import SwiftData

struct FindingsListView: View {
    let audit: Audit
    @Environment(\.modelContext) private var context
    @State private var editing: EditTarget?

    private struct EditTarget: Identifiable {
        let id = UUID()
        let finding: Finding?
    }

    var body: some View {
        let findings = audit.sortedFindings
        List {
            if findings.isEmpty {
                ContentUnavailableView {
                    Label("No Findings Yet", systemImage: "exclamationmark.triangle")
                } description: {
                    Text("Create findings from a failed control, or add one here.")
                }
                .listRowBackground(Color.clear)
            }
            ForEach(Severity.allCases) { severity in
                let group = findings.filter { $0.severity == severity }
                if !group.isEmpty {
                    Section(severity.label) {
                        ForEach(group) { finding in
                            Button { editing = EditTarget(finding: finding) } label: {
                                FindingRow(finding: finding)
                            }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button(role: .destructive) { context.delete(finding) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Findings")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { editing = EditTarget(finding: nil) } label: { Label("Add Finding", systemImage: "plus") }
            }
        }
        .sheet(item: $editing) { target in
            FindingEditorView(audit: audit, control: target.finding?.control, finding: target.finding)
        }
    }
}

private struct FindingRow: View {
    let finding: Finding

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(finding.title).font(.headline)
                Spacer()
                SeverityBadge(severity: finding.severity)
            }
            if let control = finding.control {
                Text("\(control.controlID)  \(control.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !finding.detail.isEmpty {
                Text(finding.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }
}
