import SwiftUI
import SwiftData

/// Creates a new finding, or edits an existing one when `finding` is set.
struct FindingEditorView: View {
    let audit: Audit?
    let control: ControlResult?
    let finding: Finding?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var title = ""
    @State private var severity: Severity = .medium
    @State private var detail = ""
    @State private var recommendation = ""
    @State private var loaded = false
    @State private var drafting = false

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Finding title", text: $title)
                    Picker("Severity", selection: $severity) {
                        ForEach(Severity.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                if let control {
                    Section("Control") {
                        Text("\(control.controlID)  \(control.title)")
                            .font(.subheadline)
                    }
                }
                if AuditWriter.isAvailable, let control {
                    Section {
                        Button {
                            Task { await draft(from: control) }
                        } label: {
                            HStack {
                                Label(drafting ? "Writing" : "Write with Apple Intelligence", systemImage: "sparkles")
                                if drafting { Spacer(); ProgressView() }
                            }
                        }
                        .disabled(drafting)
                    } footer: {
                        Text("Drafts the finding from this control and your notes, on this iPhone. Nothing is sent anywhere. Review it before sharing.")
                    }
                }
                Section("Details") {
                    TextField("What's wrong and why it matters", text: $detail, axis: .vertical)
                        .lineLimit(3...10)
                }
                Section("Recommendation") {
                    TextField("How to fix it", text: $recommendation, axis: .vertical)
                        .lineLimit(3...10)
                }
            }
            .calmBackground()
            .navigationTitle(finding == nil ? "New Finding" : "Edit Finding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!canSave)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let finding {
            title = finding.title
            severity = finding.severity
            detail = finding.detail
            recommendation = finding.recommendation
        } else if let control {
            // Start from what the auditor already wrote on the control.
            title = control.title
            detail = control.notes
            severity = control.status == .partial ? .low : .medium
        }
    }

    private func draft(from control: ControlResult) async {
        drafting = true
        defer { drafting = false }
        guard let draft = await AuditWriter.draftFinding(for: control, framework: control.audit?.checklistName ?? "") else { return }
        title = draft.title
        detail = draft.detail
        recommendation = draft.recommendation
        severity = draft.severity
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        if let finding {
            finding.title = trimmed
            finding.severity = severity
            finding.detail = detail
            finding.recommendation = recommendation
        } else {
            let newFinding = Finding(title: trimmed, detail: detail, recommendation: recommendation, severity: severity)
            context.insert(newFinding)
            newFinding.audit = audit
            newFinding.control = control
        }
        dismiss()
    }
}
