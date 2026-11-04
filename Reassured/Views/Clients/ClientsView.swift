import SwiftUI
import SwiftData

struct ClientsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Client.name) private var clients: [Client]
    @State private var showingNew = false
    @State private var searchText = ""
    @State private var deleteRequest: DeleteRequest?
    @Environment(LockerLock.self) private var lock

    private var filtered: [Client] {
        searchText.isEmpty ? clients : clients.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            if clients.isEmpty {
                ContentUnavailableView {
                    Label("No Clients Yet", systemImage: "person.2")
                } description: {
                    Text("Add the organizations you audit or manage. Each client keeps its own audits, tasks, and evidence.")
                } actions: {
                    Button("Add Client") { showingNew = true }
                        .buttonStyle(.borderedProminent)
                }
                .listRowBackground(Color.clear)
            }
            ForEach(filtered) { client in
                NavigationLink {
                    ClientDetailView(client: client)
                } label: {
                    ClientRow(client: client)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    // Not role: .destructive, which hides the row before the delete is confirmed.
                    Button { requestDelete(client) } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search clients")
        .calmBackground()
        .navigationTitle("Clients")
        .toolbar {
            if !clients.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingNew = true } label: { Label("Add Client", systemImage: "plus") }
                }
            }
        }
        .sheet(isPresented: $showingNew) {
            NavigationStack { ClientEditorView(client: nil) }
        }
        .sheet(item: $deleteRequest) { ConfirmDeleteView(request: $0) }
    }

    private func requestDelete(_ client: Client) {
        deleteRequest = DeleteRequest(
            title: "Delete \"\(client.name)\"?",
            message: "The client is removed. Their audits and evidence are kept and become unassigned.",
            perform: { [context] in context.delete(client) }
        )
    }
}

private struct ClientRow: View {
    let client: Client

    var body: some View {
        HStack(spacing: 14) {
            ScoreRing(score: client.latestScore, size: 44, lineWidth: 5)
            VStack(alignment: .leading, spacing: 3) {
                Text(client.name).font(.headline)
                HStack(spacing: 10) {
                    if !client.industry.isEmpty { Text(client.industry) }
                    Text("\(client.audits?.count ?? 0) audits")
                    let tasks = client.openTaskCount
                    if tasks > 0 { Text("\(tasks) open tasks") }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct ClientEditorView: View {
    let client: Client?
    var onSave: ((Client) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name = ""
    @State private var industry = ""
    @State private var contactName = ""
    @State private var contactEmail = ""
    @State private var notes = ""
    @State private var loaded = false

    var body: some View {
        Form {
            Section("Organization") {
                TextField("Client name", text: $name)
                    .textInputAutocapitalization(.words)
                TextField("Industry (for example, Healthcare)", text: $industry)
            }
            Section("Primary Contact") {
                TextField("Name", text: $contactName)
                    .textContentType(.name)
                TextField("Email", text: $contactEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            Section("Notes") {
                TextField("Scope, frameworks, contract details", text: $notes, axis: .vertical)
                    .lineLimit(2...8)
            }
        }
        .calmBackground()
        .navigationTitle(client == nil ? "New Client" : "Edit Client")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            guard !loaded, let client else { return }
            loaded = true
            name = client.name
            industry = client.industry
            contactName = client.contactName
            contactEmail = client.contactEmail
            notes = client.notes
        }
    }

    private func save() {
        let target: Client
        if let client {
            target = client
        } else {
            target = Client(name: "")
            context.insert(target)
        }
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.industry = industry
        target.contactName = contactName
        target.contactEmail = contactEmail
        target.notes = notes
        onSave?(target)
        dismiss()
    }
}
