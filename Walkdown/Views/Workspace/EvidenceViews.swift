import SwiftUI
import SwiftData

struct EvidenceThumbnail: View {
    let evidence: Evidence
    @State private var image: UIImage?

    var body: some View {
        Color.secondary.opacity(0.1)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    ProgressView()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .task(id: evidence.persistentModelID) {
                image = UIImage(data: evidence.imageData)?.preparingThumbnail(of: CGSize(width: 240, height: 240))
            }
            .accessibilityLabel(evidence.caption.isEmpty ? "Evidence photo" : evidence.caption)
    }
}

struct EvidenceDetailView: View {
    @Bindable var evidence: Evidence
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var confirmingDelete = false

    var body: some View {
        NavigationStack {
            Form {
                if let image = UIImage(data: evidence.imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .listRowInsets(EdgeInsets())
                }
                Section("Caption") {
                    TextField("Describe what this shows", text: $evidence.caption, axis: .vertical)
                }
                Section {
                    LabeledContent("Captured", value: evidence.createdAt.formatted(date: .abbreviated, time: .shortened))
                    Button("Delete Photo", role: .destructive) { confirmingDelete = true }
                }
            }
            .navigationTitle("Evidence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Delete this photo?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    context.delete(evidence)
                    dismiss()
                }
            }
        }
    }
}
