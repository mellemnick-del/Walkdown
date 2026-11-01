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
    @State private var markingUp = false

    var body: some View {
        NavigationStack {
            Form {
                if let image = UIImage(data: evidence.imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .listRowInsets(EdgeInsets())
                }
                if UIImage(data: evidence.imageData) != nil {
                    Section {
                        Button { markingUp = true } label: {
                            Label("Mark Up", systemImage: "pencil.tip.crop.circle")
                        }
                    } footer: {
                        Text("Circle or point out what matters. The marked-up copy is saved as a new photo, and the original is kept as-is.")
                    }
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
            .fullScreenCover(isPresented: $markingUp) {
                if let image = UIImage(data: evidence.imageData) {
                    MarkupView(image: image) { marked in
                        guard let data = ImageTools.jpegData(from: marked, quality: 0.8) else { return }
                        let copy = Evidence(imageData: data, caption: evidence.caption.isEmpty ? "Marked up" : "\(evidence.caption) (marked up)")
                        context.insert(copy)
                        copy.control = evidence.control
                    }
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
