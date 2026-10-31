import SwiftUI
import SwiftData

struct NewAuditView: View {
    var initialTemplateID: String?
    var initialKind: AuditKind?
    var initialClient: Client?
    var onCreate: (Audit) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(SettingsKeys.auditorName) private var defaultAuditor = ""
    @AppStorage(SettingsKeys.userRole) private var roleRaw = UserRole.organization.rawValue

    @State private var clientName = ""
    @State private var siteName = ""
    @State private var location = ""
    @State private var auditorName = ""
    @State private var date = Date.now
    @State private var scopeNotes = ""
    @State private var templateID = TemplateLibrary.all[0].id
    @State private var kind: AuditKind = .onSite
    @State private var loaded = false
    @State private var clientID: UUID?
    @State private var showingNewClient = false
    @Query(sort: \Client.name) private var clients: [Client]

    private var selectedClient: Client? { clients.first { $0.id == clientID } }

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
                    if !clients.isEmpty {
                        Picker("Client", selection: $clientID) {
                            Text("None").tag(UUID?.none)
                            ForEach(clients) { Text($0.name).tag(UUID?.some($0.id)) }
                        }
                    }
                    Button { showingNewClient = true } label: {
                        Label("New Client", systemImage: "person.badge.plus")
                    }
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
            .onChange(of: clientID) { _, _ in
                if let selectedClient { clientName = selectedClient.name }
            }
            .sheet(isPresented: $showingNewClient) {
                NavigationStack {
                    ClientEditorView(client: nil) { client in clientID = client.id }
                }
            }
            .onAppear {
                // Runs once. onAppear fires again when returning from the checklist picker.
                guard !loaded else { return }
                loaded = true
                if auditorName.isEmpty { auditorName = defaultAuditor }
                if let initialTemplateID { templateID = initialTemplateID }
                if let initialClient {
                    clientID = initialClient.id
                    clientName = initialClient.name
                }
                kind = initialKind ?? (UserRole(rawValue: roleRaw) ?? .organization).defaultAuditKind
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
            client: selectedClient,
            in: context
        )
        dismiss()
        onCreate(audit)
    }
}
