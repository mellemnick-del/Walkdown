import SwiftUI
import SwiftData

struct ClientDetailView: View {
    @Bindable var client: Client
    @Environment(AppRouter.self) private var router
    @Environment(\.openURL) private var openURL
    @State private var editing = false
    @State private var startingAudit = false

    var body: some View {
        List {
            Section {
                HStack(spacing: 18) {
                    ScoreRing(score: client.latestScore, size: 90, lineWidth: 10)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(client.name).font(.title3.bold())
                        if !client.industry.isEmpty {
                            Text(client.industry).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Text("\(client.audits?.count ?? 0) audits, \(client.openTaskCount) open tasks, \(client.lockerItems?.count ?? 0) evidence items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
                Button { startingAudit = true } label: {
                    Label("New Audit for \(client.name)", systemImage: "plus.viewfinder")
                }
            }

            if !client.contactName.isEmpty || !client.contactEmail.isEmpty {
                Section("Contact") {
                    if !client.contactName.isEmpty { Text(client.contactName) }
                    if !client.contactEmail.isEmpty, let url = URL(string: "mailto:\(client.contactEmail)") {
                        Button(client.contactEmail) { openURL(url) }
                    }
                }
            }

            Section("Audits") {
                if client.sortedAudits.isEmpty {
                    Text("No audits yet.").foregroundStyle(.secondary)
                }
                ForEach(client.sortedAudits) { audit in
                    Button { router.open(audit) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(audit.checklistName).foregroundStyle(.primary)
                                Text("\(audit.kind.label), \(audit.date.formatted(date: .abbreviated, time: .omitted)), \(audit.status.label)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let score = audit.score {
                                Text("\(Int((score * 100).rounded()))%")
                                    .font(.subheadline.bold())
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }

            let evidence = (client.lockerItems ?? []).sorted { $0.title < $1.title }
            if !evidence.isEmpty {
                Section("Evidence") {
                    ForEach(evidence) { item in
                        NavigationLink {
                            LockerItemDetailView(item: item)
                        } label: {
                            LockerRow(item: item)
                        }
                    }
                }
            }

            if !client.notes.isEmpty {
                Section("Notes") { Text(client.notes) }
            }
        }
        .calmBackground()
        .navigationTitle(client.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { editing = true }
            }
        }
        .sheet(isPresented: $editing) {
            NavigationStack { ClientEditorView(client: client) }
        }
        .sheet(isPresented: $startingAudit) {
            NewAuditView(initialClient: client) { audit in router.open(audit) }
        }
    }
}
