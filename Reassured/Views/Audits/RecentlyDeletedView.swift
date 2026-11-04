import SwiftUI
import SwiftData

/// Deleted audits, kept for 30 days. Restore puts an audit back exactly as it was.
struct RecentlyDeletedView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Audit.date, order: .reverse) private var audits: [Audit]
    @State private var deleteRequest: DeleteRequest?

    private var deleted: [Audit] { audits.filter(\.isInTrash) }

    var body: some View {
        List {
            if deleted.isEmpty {
                ContentUnavailableView("Nothing Here", systemImage: "trash",
                                       description: Text("Deleted audits stay here for \(RecentlyDeleted.keepDays) days, so you can bring them back."))
                    .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(deleted) { audit in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(audit.displayName).font(.headline)
                                Text(audit.checklistName).font(.subheadline).foregroundStyle(.secondary)
                                let days = RecentlyDeleted.daysLeft(audit)
                                Text(days == 1 ? "Deletes tomorrow" : "Deletes in \(days) days")
                                    .font(.caption)
                                    .foregroundStyle(days <= 3 ? Theme.calmCoral : .secondary)
                            }
                            Spacer()
                            Button("Restore") {
                                withAnimation { RecentlyDeleted.restore(audit) }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) { requestPermanentDelete(audit) } label: {
                                Label("Delete Now", systemImage: "trash")
                            }
                        }
                    }
                } footer: {
                    Text("Audits here are removed for good \(RecentlyDeleted.keepDays) days after they're deleted. Swipe left to delete one now.")
                }
            }
        }
        .calmBackground()
        .navigationTitle("Recently Deleted")
        .sheet(item: $deleteRequest) { ConfirmDeleteView(request: $0) }
    }

    private func requestPermanentDelete(_ audit: Audit) {
        deleteRequest = DeleteRequest(
            title: "Delete \"\(audit.displayName)\" for good?",
            message: "This removes the audit permanently, with all its results, photos, findings, and tasks. It can't be restored.",
            perform: { [context] in RecentlyDeleted.deletePermanently(audit, in: context) }
        )
    }
}
