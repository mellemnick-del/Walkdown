import SwiftUI

/// Edit an audit's client details after it has been created.
struct AuditInfoView: View {
    @Bindable var audit: Audit
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    TextField("Client name", text: $audit.clientName)
                    TextField("Site", text: $audit.siteName)
                    TextField("Location", text: $audit.location)
                }
                Section("Audit") {
                    TextField("Auditor", text: $audit.auditorName)
                    DatePicker("Date", selection: $audit.date, displayedComponents: .date)
                    LabeledContent("Checklist", value: audit.checklistName)
                }
                Section("Scope") {
                    TextField("Scope notes", text: $audit.scopeNotes, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("Audit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
