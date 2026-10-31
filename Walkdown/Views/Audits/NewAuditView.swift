import SwiftUI
import SwiftData

struct NewAuditView: View {
    var onCreate: (Audit) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(SettingsKeys.auditorName) private var defaultAuditor = ""

    @State private var clientName = ""
    @State private var siteName = ""
    @State private var location = ""
    @State private var auditorName = ""
    @State private var date = Date.now
    @State private var scopeNotes = ""
    @State private var templateID = TemplateLibrary.all[0].id

    private var canCreate: Bool { !clientName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    TextField("Client name", text: $clientName)
                        .textInputAutocapitalization(.words)
                    TextField("Site (optional)", text: $siteName)
                    TextField("Location (optional)", text: $location)
                }
                Section("Audit") {
                    TextField("Auditor", text: $auditorName)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                Section("Checklist") {
                    Picker("Checklist", selection: $templateID) {
                        ForEach(TemplateLibrary.all) { template in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(template.name)
                                Text("\(template.itemCount) controls. \(template.summary)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(template.id)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section("Scope") {
                    TextField("What's in and out of scope?", text: $scopeNotes, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("New Audit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: create).disabled(!canCreate)
                }
            }
            .onAppear {
                if auditorName.isEmpty { auditorName = defaultAuditor }
            }
        }
    }

    private func create() {
        guard let template = TemplateLibrary.template(id: templateID) else { return }
        let audit = AuditFactory.create(
            from: template,
            clientName: clientName.trimmingCharacters(in: .whitespaces),
            siteName: siteName.trimmingCharacters(in: .whitespaces),
            location: location.trimmingCharacters(in: .whitespaces),
            auditorName: auditorName.trimmingCharacters(in: .whitespaces),
            date: date,
            scopeNotes: scopeNotes,
            in: context
        )
        dismiss()
        onCreate(audit)
    }
}
