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

    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selectedAudit: Audit?

    /// iPad (and other wide layouts): the list stays on the left and the audit fills the right.
    private var isSplit: Bool { sizeClass == .regular }

    var body: some View {
        Group {
            if isSplit {
                NavigationSplitView {
                    auditList(selectable: true)
                } detail: {
                    NavigationStack {
                        if let selectedAudit, !selectedAudit.isInTrash {
                            AuditWorkspaceView(audit: selectedAudit)
                                .id(selectedAudit.persistentModelID)
                        } else {
                            ContentUnavailableView {
                                Label("Choose an Audit", systemImage: "checklist")
                            } description: {
                                Text("Pick an audit from the list to see its controls, or start a new one.")
                            }
                            .calmBackground()
                        }
                    }
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                NavigationStack(path: $path) {
                    auditList(selectable: false)
                        .navigationDestination(for: Audit.self) { AuditWorkspaceView(audit: $0) }
                }
            }
        }
        .sheet(isPresented: $showingNewAudit) {
            NewAuditView { audit in
                filter = .inProgress
                show(audit)
            }
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(item: $deleteRequest) { ConfirmDeleteView(request: $0) }
        .onChange(of: router.auditToOpen, initial: true) { _, audit in
            guard let audit else { return }
            filter = audit.status
            show(audit)
            router.auditToOpen = nil
        }
    }

    /// Opens an audit: selects it beside the list on iPad, or pushes it on iPhone.
    private func show(_ audit: Audit) {
        if isSplit {
            selectedAudit = audit
        } else {
            path = NavigationPath()
            path.append(audit)
        }
    }

    private func auditList(selectable: Bool) -> some View {
        Group {
            if selectable {
                List(selection: $selectedAudit) { listRows }
            } else {
                List { listRows }
            }
        }
        .calmBackground()
        .navigationTitle(isSplit ? "Audits" : "Reassured")
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
    }

    @ViewBuilder
    private var listRows: some View {
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
                            // Not role: .destructive. That role makes the list hide the row right away,
                            // before the delete is confirmed, so a canceled delete looked like a real one.
                            Button {
                                requestDelete(audit)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
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
