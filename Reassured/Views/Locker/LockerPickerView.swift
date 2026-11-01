import SwiftUI
import SwiftData

/// Link Evidence Locker items to a control. Items whose topics match the control are suggested first.
struct LockerPickerView: View {
    @Bindable var control: ControlResult
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \LockerItem.title) private var items: [LockerItem]
    @State private var searchText = ""

    private var suggestedTopics: Set<EvidenceTopic> { EvidenceTopic.suggested(for: control) }

    /// Only evidence for this audit's client (or your own organization's when there's no client).
    private var visible: [LockerItem] {
        let clientID = control.audit?.client?.id
        let scoped = items.filter { $0.client?.id == clientID }
        return searchText.isEmpty ? scoped : scoped.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                let suggested = visible.filter { !$0.topics.isDisjoint(with: suggestedTopics) }
                let others = visible.filter { $0.topics.isDisjoint(with: suggestedTopics) }

                if items.isEmpty {
                    ContentUnavailableView("No Evidence Yet", systemImage: "lock.doc",
                                           description: Text("Add documents in the Locker tab, then attach them here."))
                        .listRowBackground(Color.clear)
                } else if visible.isEmpty && searchText.isEmpty {
                    ContentUnavailableView("No Evidence for This Client", systemImage: "lock.doc",
                                           description: Text("Add evidence in the Locker tab and set Belongs to \(control.audit?.client?.name ?? "My Organization")."))
                        .listRowBackground(Color.clear)
                }
                if !suggested.isEmpty {
                    Section {
                        ForEach(suggested) { row($0) }
                    } header: {
                        Text("Suggested")
                    } footer: {
                        Text("Matched by topic: \(suggestedTopics.map(\.label).sorted().joined(separator: ", ")).")
                    }
                }
                if !others.isEmpty {
                    Section(suggested.isEmpty ? "Evidence" : "Other Evidence") {
                        ForEach(others) { row($0) }
                    }
                }
            }
            .searchable(text: $searchText)
            .calmBackground()
            .navigationTitle("Attach Evidence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func isLinked(_ item: LockerItem) -> Bool {
        (control.lockerItems ?? []).contains { $0.persistentModelID == item.persistentModelID }
    }

    private func toggle(_ item: LockerItem) {
        if isLinked(item) {
            control.lockerItems?.removeAll { $0.persistentModelID == item.persistentModelID }
        } else {
            if control.lockerItems == nil { control.lockerItems = [] }
            control.lockerItems?.append(item)
        }
    }

    private func row(_ item: LockerItem) -> some View {
        Button { toggle(item) } label: {
            HStack {
                LockerRow(item: item)
                Spacer()
                Image(systemName: isLinked(item) ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isLinked(item) ? Color.accentColor : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
