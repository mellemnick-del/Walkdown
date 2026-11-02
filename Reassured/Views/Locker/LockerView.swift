import SwiftUI
import SwiftData
import PhotosUI
import VisionKit

struct LockerView: View {
    @Environment(\.modelContext) private var context
    @Environment(LockerLock.self) private var lock
    @Query(sort: \LockerItem.addedAt, order: .reverse) private var items: [LockerItem]
    @State private var searchText = ""
    @State private var topicFilter: EvidenceTopic?
    @State private var showingImporter = false
    @State private var showingScanner = false
    @State private var photoItem: PhotosPickerItem?
    @State private var pending: PendingImport?
    @State private var importError: String?

    struct PendingImport: Identifiable {
        let id = UUID()
        let imported: EvidenceImporter.Imported
    }

    private var filtered: [LockerItem] {
        items.filter { item in
            (topicFilter == nil || item.topics.contains(topicFilter!))
                && (searchText.isEmpty
                    || item.title.localizedCaseInsensitiveContains(searchText)
                    || item.notes.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        NavigationStack {
            Group {
            if lock.isOpen {
            List {
                let expired = filtered.filter(\.isExpired)
                let expiring = filtered.filter(\.isExpiringSoon)
                let current = filtered.filter { !$0.isExpired && !$0.isExpiringSoon }

                if items.isEmpty {
                    ContentUnavailableView {
                        Label("Your Evidence Locker Is Empty", systemImage: "lock.doc")
                    } description: {
                        Text("Store policies, reports, screenshots, and certificates in one place. Link them to controls in any audit and get reminded before they expire.")
                    } actions: {
                        addMenu(prominent: true)
                    }
                    .listRowBackground(Color.clear)
                }

                section("Expired", expired)
                section("Expiring Soon", expiring)
                section(expired.isEmpty && expiring.isEmpty ? "All Evidence" : "Current", current)
            }
            .searchable(text: $searchText, prompt: "Search evidence")
            } else {
                LockerLockScreen()
            }
            }
            .calmBackground()
            .navigationTitle("Evidence Locker")
            .toolbar {
                if lock.isOpen {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Topic", selection: $topicFilter) {
                            Text("All Topics").tag(EvidenceTopic?.none)
                            ForEach(EvidenceTopic.allCases) { Text($0.label).tag(EvidenceTopic?.some($0)) }
                        }
                    } label: {
                        Label("Filter", systemImage: topicFilter == nil
                              ? "line.3.horizontal.decrease.circle"
                              : "line.3.horizontal.decrease.circle.fill")
                    }
                }
                ToolbarItem(placement: .primaryAction) { addMenu(prominent: false) }
                if lock.isEnabled {
                    ToolbarItem(placement: .primaryAction) {
                        Button { lock.lock() } label: { Label("Lock", systemImage: "lock") }
                    }
                }
                }
            }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.pdf, .image, .plainText, .commaSeparatedText, .spreadsheet, .presentation, .data]) { result in
                do {
                    let url = try result.get()
                    pending = PendingImport(imported: try EvidenceImporter.file(at: url))
                } catch {
                    importError = error.localizedDescription
                }
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let imported = EvidenceImporter.photo(data) {
                        pending = PendingImport(imported: imported)
                    }
                    photoItem = nil
                }
            }
            .fullScreenCover(isPresented: $showingScanner) {
                DocumentScanner { pages in
                    if let imported = EvidenceImporter.scan(pages) { pending = PendingImport(imported: imported) }
                }
                .ignoresSafeArea()
            }
            .sheet(item: $pending) { pending in
                NavigationStack { LockerItemEditor(newImport: pending.imported) }
            }
            .alert("Couldn't Import File", isPresented: Binding(
                get: { importError != nil }, set: { if !$0 { importError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importError ?? "")
            }
        }
    }

    private func addMenu(prominent: Bool) -> some View {
        Menu {
            Button { showingImporter = true } label: { Label("Import File", systemImage: "folder") }
            if VNDocumentCameraViewController.isSupported {
                Button { showingScanner = true } label: { Label("Scan Document", systemImage: "doc.viewfinder") }
            }
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Choose Photo or Screenshot", systemImage: "photo")
            }
        } label: {
            if prominent {
                Label("Add Evidence", systemImage: "plus")
                    .labelStyle(.titleAndIcon)
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.accentColor, in: Capsule())
                    .foregroundStyle(.white)
                    .fixedSize()
            } else {
                Label("Add Evidence", systemImage: "plus")
            }
        }
    }

    @ViewBuilder
    private func section(_ title: String, _ list: [LockerItem]) -> some View {
        if !list.isEmpty {
            Section(title) {
                ForEach(list) { item in
                    NavigationLink {
                        LockerItemDetailView(item: item)
                    } label: {
                        LockerRow(item: item)
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        ReminderScheduler.cancel(list[index])
                        context.delete(list[index])
                    }
                }
            }
        }
    }
}

struct LockerRow: View {
    let item: LockerItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.kind.symbol)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title.isEmpty ? item.fileName : item.title)
                    .lineLimit(1)
                Text(item.client.map { "\(item.kind.label) for \($0.name)" } ?? item.kind.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 10) {
                    if let expiry = item.expiryText {
                        Label(expiry, systemImage: "calendar")
                            .foregroundStyle(item.isExpired ? Theme.calmCoral : item.isExpiringSoon ? Theme.calmAmber : .secondary)
                            .lineLimit(1)
                    }
                    let linked = item.controls?.count ?? 0
                    if linked > 0 {
                        Label("\(linked) control\(linked == 1 ? "" : "s")", systemImage: "link")
                            .lineLimit(1)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}
