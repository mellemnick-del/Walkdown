import SwiftUI
import SwiftData
import QuickLook

struct LockerItemDetailView: View {
    @Bindable var item: LockerItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var fileURL: URL?
    @State private var previewURL: URL?
    @State private var editing = false
    @State private var confirmingDelete = false

    var body: some View {
        LockerGate { detail }
    }

    private var detail: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    if item.isImage, let image = UIImage(data: item.fileData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Image(systemName: item.kind.symbol)
                            .font(.system(size: 44))
                            .foregroundStyle(.tint)
                    }
                    Text(item.title).font(.title3.bold())
                    if let expiry = item.expiryText {
                        Label(expiry, systemImage: "calendar.badge.clock")
                            .font(.subheadline)
                            .foregroundStyle(item.isExpired ? Theme.calmCoral : item.isExpiringSoon ? Theme.calmAmber : .secondary)
                    }
                }
                .padding(.vertical, 4)

                if let fileURL {
                    Button { previewURL = fileURL } label: { Label("Open", systemImage: "eye") }
                    ShareLink(item: fileURL) { Label("Share", systemImage: "square.and.arrow.up") }
                }
            }

            Section("Details") {
                LabeledContent("Type", value: item.kind.label)
                LabeledContent("File", value: item.fileName)
                LabeledContent("Size", value: ByteCountFormatter.string(fromByteCount: Int64(item.fileData.count), countStyle: .file))
                LabeledContent("Added", value: item.addedAt.formatted(date: .abbreviated, time: .omitted))
                if !item.topics.isEmpty {
                    LabeledContent("Topics", value: item.topics.map(\.label).sorted().joined(separator: ", "))
                }
                if !item.notes.isEmpty {
                    Text(item.notes).font(.subheadline)
                }
            }

            Section("Linked Controls") {
                let controls = item.controls ?? []
                if controls.isEmpty {
                    Text("Not linked yet. Open a control in any audit and choose Attach from Locker.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                ForEach(controls) { control in
                    NavigationLink {
                        ControlDetailView(control: control)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(control.controlID)  \(control.title)").font(.subheadline)
                            if let audit = control.audit {
                                Text(audit.displayName).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section {
                Button("Delete Evidence", role: .destructive) { confirmingDelete = true }
            }
        }
        .calmBackground()
        .navigationTitle("Evidence")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { editing = true }
            }
        }
        .task(id: item.fileData.count) { fileURL = try? item.temporaryFileURL() }
        .quickLookPreview($previewURL)
        .sheet(isPresented: $editing) {
            NavigationStack { LockerItemEditor(item: item) }
        }
        .confirmationDialog("Delete this evidence?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                ReminderScheduler.cancel(item)
                context.delete(item)
                dismiss()
            }
        } message: {
            Text("It will be removed from every control it's linked to.")
        }
    }
}
