import SwiftUI
import SwiftData
import PhotosUI
import VisionKit

struct ControlDetailView: View {
    @Bindable var control: ControlResult
    @Environment(\.modelContext) private var context

    @State private var photoItems: [PhotosPickerItem] = []
    @State private var showingCamera = false
    @State private var showingScanner = false
    @State private var selectedEvidence: Evidence?
    @State private var findingSheet: FindingSheet?

    private struct FindingSheet: Identifiable {
        let id = UUID()
        let finding: Finding?
    }

    private let columns = [GridItem(.adaptive(minimum: 90), spacing: 8)]

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(control.controlID)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    Text(control.title)
                        .font(.headline)
                    Text(control.guidance)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text(control.groupName)
            }

            Section("Result") {
                StatusPicker(status: $control.status)
                    .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            }

            Section("Notes") {
                TextField("What did you see?", text: $control.notes, axis: .vertical)
                    .lineLimit(3...12)
            }

            Section("Evidence") {
                let evidence = control.sortedEvidence
                if !evidence.isEmpty {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(evidence) { item in
                            Button { selectedEvidence = item } label: {
                                EvidenceThumbnail(evidence: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button { showingCamera = true } label: { Label("Take Photo", systemImage: "camera") }
                }
                if VNDocumentCameraViewController.isSupported {
                    Button { showingScanner = true } label: { Label("Scan Document", systemImage: "doc.viewfinder") }
                }
                PhotosPicker(selection: $photoItems, maxSelectionCount: 10, matching: .images) {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                }
            }

            Section("Findings") {
                ForEach(control.findings ?? []) { finding in
                    Button { findingSheet = FindingSheet(finding: finding) } label: {
                        HStack {
                            Text(finding.title).foregroundStyle(.primary)
                            Spacer()
                            SeverityBadge(severity: finding.severity)
                        }
                    }
                }
                Button { findingSheet = FindingSheet(finding: nil) } label: {
                    Label("Create Finding", systemImage: "exclamationmark.triangle")
                }
            }
        }
        .navigationTitle(control.controlID)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: photoItems) { _, items in
            guard !items.isEmpty else { return }
            Task { await importPhotos(items) }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker { image in addImage(image) }
                .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showingScanner) {
            DocumentScanner { pages in pages.forEach(addImage) }
                .ignoresSafeArea()
        }
        .sheet(item: $selectedEvidence) { EvidenceDetailView(evidence: $0) }
        .sheet(item: $findingSheet) { sheet in
            FindingEditorView(audit: control.audit, control: control, finding: sheet.finding)
        }
    }

    private func importPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let jpeg = ImageTools.jpegData(from: data) {
                addEvidence(jpeg)
            }
        }
        photoItems = []
    }

    private func addImage(_ image: UIImage) {
        if let jpeg = ImageTools.jpegData(from: image) { addEvidence(jpeg) }
    }

    private func addEvidence(_ data: Data) {
        let evidence = Evidence(imageData: data)
        context.insert(evidence)
        evidence.control = control
    }
}

/// Four big, thumb-friendly result buttons.
private struct StatusPicker: View {
    @Binding var status: ControlStatus

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ControlStatus.answerable) { option in
                let selected = status == option
                Button {
                    // Tapping the selected result again clears it.
                    status = selected ? .notStarted : option
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: option.symbol).font(.title2)
                        Text(option.label).font(.caption.bold())
                    }
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(selected ? option.color.opacity(0.2) : Color.secondary.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(selected ? option.color : .clear, lineWidth: 2))
                    .foregroundStyle(selected ? option.color : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: status)
    }
}
