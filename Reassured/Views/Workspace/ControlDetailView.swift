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
    @State private var showingHelp = false
    @State private var showingLockerPicker = false

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

            Section {
                ForEach(control.lockerItems ?? []) { item in
                    NavigationLink {
                        LockerItemDetailView(item: item)
                    } label: {
                        LockerRow(item: item)
                    }
                }
                Button { showingLockerPicker = true } label: {
                    Label("Attach from Locker", systemImage: "lock.doc")
                }
            } header: {
                Text("Evidence Locker")
            } footer: {
                Text("Policies, reports, and documents you keep on file. One document can support controls in every audit.")
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

            Section("Remediation") {
                ForEach((control.tasks ?? []).sorted(by: RemediationTask.nextUp)) { task in
                    NavigationLink {
                        TaskDetailView(task: task)
                    } label: {
                        TaskRow(task: task)
                    }
                }
                if control.status == .fail || control.status == .partial {
                    Button(action: addTask) { Label("Add Task", systemImage: "wrench.and.screwdriver") }
                }
                Button { showingHelp = true } label: { Label("Get Help With This Control", systemImage: "person.wave.2") }
            }
        }
        .calmBackground()
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
        .sheet(isPresented: $showingLockerPicker) { LockerPickerView(control: control) }
        .sheet(isPresented: $showingHelp) { GetHelpView(topic: "\(control.controlID) \(control.title)") }
        .sheet(item: $findingSheet) { sheet in
            FindingEditorView(audit: control.audit, control: control, finding: sheet.finding)
        }
    }

    private func addTask() {
        let priority = RemediationPlanner.suggestedPriority(for: control)
        let task = RemediationTask(
            title: "Fix: \(control.title)",
            detail: control.notes.isEmpty ? "Goal: \(control.guidance)" : "Goal: \(control.guidance)\n\nWhat the audit found: \(control.notes)",
            dueDate: Calendar.current.date(byAdding: .day, value: priority.suggestedDays, to: .now),
            priority: priority
        )
        context.insert(task)
        task.audit = control.audit
        task.control = control
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
        .sensoryFeedback(trigger: status) { _, new in
            switch new {
            case .pass: .success
            case .fail: .warning
            default: .selection
            }
        }
    }
}
