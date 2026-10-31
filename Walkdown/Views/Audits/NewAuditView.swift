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
    @State private var kind: AuditKind = .onSite

    private var template: ChecklistTemplate? { TemplateLibrary.template(id: templateID) }

    private var canCreate: Bool { !clientName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $kind) {
                        ForEach(AuditKind.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text(kind == .onSite
                         ? "Walk the site and record what you see."
                         : "Answer the checklist for your own organization or a client's.")
                }
                Section(kind == .onSite ? "Client" : "Organization") {
                    TextField(kind == .onSite ? "Client name" : "Organization name", text: $clientName)
                        .textInputAutocapitalization(.words)
                    if kind == .onSite {
                        TextField("Site (optional)", text: $siteName)
                        TextField("Location (optional)", text: $location)
                    }
                }
                Section("Checklist") {
                    NavigationLink {
                        ChecklistLibraryView(selection: $templateID)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template?.name ?? "Choose a checklist")
                            if let template {
                                Text("\(template.area.label). \(template.itemCount) controls.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section(kind == .onSite ? "Audit" : "Assessment") {
                    TextField(kind == .onSite ? "Auditor" : "Completed by", text: $auditorName)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                Section("Scope") {
                    TextField("What's in and out of scope?", text: $scopeNotes, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle(kind == .onSite ? "New Audit" : "New Self-Assessment")
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
        guard let template else { return }
        let audit = AuditFactory.create(
            from: template,
            clientName: clientName.trimmingCharacters(in: .whitespaces),
            siteName: kind == .onSite ? siteName.trimmingCharacters(in: .whitespaces) : "",
            location: kind == .onSite ? location.trimmingCharacters(in: .whitespaces) : "",
            auditorName: auditorName.trimmingCharacters(in: .whitespaces),
            date: date,
            scopeNotes: scopeNotes,
            kind: kind,
            in: context
        )
        dismiss()
        onCreate(audit)
    }
}
