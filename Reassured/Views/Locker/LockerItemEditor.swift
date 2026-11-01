import SwiftUI
import SwiftData

/// Add a new locker item from an import, or edit an existing one.
struct LockerItemEditor: View {
    var newImport: EvidenceImporter.Imported?
    var item: LockerItem?
    /// Called with the saved item, used when adding from a control.
    var onSave: ((LockerItem) -> Void)?
    /// Topics to pre-select, for example from the control being worked on.
    var suggestedTopics: Set<EvidenceTopic> = []
    var initialClient: Client?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var title = ""
    @State private var kind: EvidenceKind = .other
    @State private var topics: Set<EvidenceTopic> = []
    @State private var hasExpiry = false
    @State private var expiresAt = Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now
    @State private var notes = ""
    @State private var loaded = false
    @State private var clientID: UUID?
    @Query(sort: \Client.name) private var clients: [Client]

    var body: some View {
        Form {
            Section {
                TextField("Title", text: $title)
                Picker("Type", selection: $kind) {
                    ForEach(EvidenceKind.allCases) { Label($0.label, systemImage: $0.symbol).tag($0) }
                }
                if let name = newImport?.fileName ?? item?.fileName, !name.isEmpty {
                    LabeledContent("File", value: name)
                }
            }

            if !clients.isEmpty {
                Section {
                    Picker("Belongs to", selection: $clientID) {
                        Text("My Organization").tag(UUID?.none)
                        ForEach(clients) { Text($0.name).tag(UUID?.some($0.id)) }
                    }
                } footer: {
                    Text("Client evidence is only suggested in that client's audits.")
                }
            }

            Section {
                Toggle("Expires", isOn: $hasExpiry)
                if hasExpiry {
                    DatePicker("Expiration", selection: $expiresAt, displayedComponents: .date)
                }
            } footer: {
                Text("You'll get reminders 30 days and 7 days before, and on the day it expires. Pen tests, certificates, insurance, and training records usually expire yearly.")
            }

            Section {
                ForEach(EvidenceTopic.allCases) { topic in
                    Button {
                        if topics.contains(topic) { topics.remove(topic) } else { topics.insert(topic) }
                    } label: {
                        HStack {
                            Text(topic.label).foregroundStyle(.primary)
                            Spacer()
                            if topics.contains(topic) {
                                Image(systemName: "checkmark").foregroundStyle(.tint)
                            }
                        }
                    }
                }
            } header: {
                Text("Topics")
            } footer: {
                Text("Topics let Reassured suggest this evidence for matching controls in any framework.")
            }

            Section("Notes") {
                TextField("Version, owner, where it came from", text: $notes, axis: .vertical)
                    .lineLimit(2...8)
            }
        }
        .navigationTitle(item == nil ? "Add Evidence" : "Edit Evidence")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let item {
            clientID = item.client?.id
            title = item.title
            kind = item.kind
            topics = item.topics
            notes = item.notes
            if let date = item.expiresAt {
                hasExpiry = true
                expiresAt = date
            }
        } else if let newImport {
            title = newImport.suggestedTitle
            kind = newImport.contentType.conforms(to: .image) ? .screenshot : .other
            topics = suggestedTopics
            clientID = initialClient?.id
        }
    }

    private func save() {
        let target: LockerItem
        if let item {
            target = item
        } else if let newImport {
            target = LockerItem(title: "", fileData: newImport.data, fileName: newImport.fileName,
                                contentType: newImport.contentType)
            context.insert(target)
        } else {
            return
        }
        target.title = title.trimmingCharacters(in: .whitespaces)
        target.kind = kind
        target.topics = topics
        target.notes = notes
        target.expiresAt = hasExpiry ? expiresAt : nil
        target.client = clients.first { $0.id == clientID }
        ReminderScheduler.schedule(target)
        onSave?(target)
        dismiss()
    }
}
