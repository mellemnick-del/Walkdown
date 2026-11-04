import SwiftUI
import SwiftData

struct AuditListView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppRouter.self) private var router
    @Query(sort: \Audit.date, order: .reverse) private var audits: [Audit]
    @State private var filter: AuditStatus = .inProgress
    @State private var path = NavigationPath()
    @State private var showingNewAudit = false
    @State private var showingSettings = false
    @State private var deleteRequest: DeleteRequest?
    @Environment(LockerLock.self) private var lock

    private var filtered: [Audit] { audits.filter { $0.status == filter } }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Picker("Status", selection: $filter) {
                    ForEach(AuditStatus.listed) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                if filtered.isEmpty {
                    emptyState
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(filtered) { audit in
                        NavigationLink(value: audit) {
                            AuditRow(audit: audit)
                        }
                        // No full swipe: deleting always takes a deliberate tap.
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                requestDelete(audit)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            if audit.status != .archived {
                                Button {
                                    audit.status = .archived
                                } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                                .tint(.gray)
                            }
                        }
                    }
                }

                let trashCount = audits.filter(\.isInTrash).count
                if trashCount > 0 {
                    Section {
                        NavigationLink {
                            RecentlyDeletedView()
                        } label: {
                            LabeledContent {
                                Text("\(trashCount)").monospacedDigit()
                            } label: {
                                Label("Recently Deleted", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .calmBackground()
            .navigationTitle("Reassured")
            .navigationDestination(for: Audit.self) { AuditWorkspaceView(audit: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        ClientsView()
                    } label: {
                        Label("Clients", systemImage: "person.2")
                    }
                }
                if !audits.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button { showingNewAudit = true } label: { Label("New Audit", systemImage: "plus") }
                    }
                }
            }
            .sheet(isPresented: $showingNewAudit) {
                NewAuditView { audit in
                    filter = .inProgress
                    path.append(audit)
                }
            }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .onChange(of: router.auditToOpen, initial: true) { _, audit in
                guard let audit else { return }
                filter = audit.status
                path = NavigationPath()
                path.append(audit)
                router.auditToOpen = nil
            }
            .sheet(item: $deleteRequest) { ConfirmDeleteView(request: $0) }
        }
    }

    private func requestDelete(_ audit: Audit) {
        deleteRequest = DeleteRequest(
            title: "Delete \"\(audit.displayName)\"?",
            message: "This moves the \(audit.checklistName) audit, with all \(audit.totalCount) results, notes, photos, findings, and tasks, to Recently Deleted. You can restore it for \(RecentlyDeleted.keepDays) days.",
            perform: { withAnimation { RecentlyDeleted.delete(audit) } }
        )
    }

    @ViewBuilder
    private var emptyState: some View {
        switch filter {
        case .inProgress:
            ContentUnavailableView {
                Label("No Audits in Progress", systemImage: "checklist")
            } description: {
                Text("Start an audit, pick a checklist, and work through it on site.")
            } actions: {
                if audits.isEmpty {
                    Button("New Audit") { showingNewAudit = true }
                        .buttonStyle(.borderedProminent)
                }
            }
        case .complete:
            ContentUnavailableView("No Completed Audits", systemImage: "checkmark.seal",
                                   description: Text("Audits you mark complete show up here."))
        case .deleted:
            EmptyView()
        case .archived:
            ContentUnavailableView("No Archived Audits", systemImage: "archivebox",
                                   description: Text("Swipe an audit to archive it."))
        }
    }
}

private struct AuditRow: View {
    let audit: Audit

    var body: some View {
        HStack(spacing: 14) {
            ProgressRing(progress: audit.progress)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(audit.displayName)
                    .font(.headline)
                Text(audit.kind == .selfAssessment ? "Self-Assessment: \(audit.checklistName)" : audit.checklistName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Text(audit.date.formatted(date: .abbreviated, time: .omitted))
                    Text("\(audit.answeredCount) of \(audit.totalCount) done")
                    let failCount = audit.count(.fail)
                    if failCount > 0 {
                        Text("\(failCount) failed").foregroundStyle(Theme.calmCoral)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
