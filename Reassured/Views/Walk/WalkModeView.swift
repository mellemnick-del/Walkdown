import SwiftUI
import SwiftData
import PhotosUI

/// Go through an audit one control at a time: read, answer, snap a photo, move on.
/// Built for standing in a server room with one hand free.
struct WalkModeView: View {
    let audit: Audit
    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var loaded = false

    private var controls: [ControlResult] { audit.sortedControls }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                TabView(selection: $index) {
                    ForEach(Array(controls.enumerated()), id: \.element.id) { offset, control in
                        WalkCard(control: control) { advance(from: offset) }
                            .tag(offset)
                    }
                    WalkFinishedCard(audit: audit) { dismiss() }
                        .tag(controls.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .calmBackground()
            .navigationTitle("Walk Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Next Open") { jumpToNextOpen() }
                        .disabled(audit.answeredCount == audit.totalCount)
                }
            }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                index = controls.firstIndex { $0.status == .notStarted } ?? 0
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(index < controls.count ? controls[index].groupName : "Finished")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text("\(min(index + 1, controls.count)) of \(controls.count)")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: audit.progress)
                .tint(Theme.calmGreen)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private func advance(from offset: Int) {
        withAnimation(.easeInOut) { index = min(offset + 1, controls.count) }
    }

    private func jumpToNextOpen() {
        let after = controls.indices.dropFirst(index + 1).first { controls[$0].status == .notStarted }
        let wrapped = after ?? controls.indices.first { controls[$0].status == .notStarted }
        if let target = wrapped { withAnimation { index = target } }
    }
}

/// One control, full screen.
private struct WalkCard: View {
    @Bindable var control: ControlResult
    let next: () -> Void

    @Environment(\.modelContext) private var context
    @State private var showingCamera = false
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var notesFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(control.controlID)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    Text(control.title)
                        .font(.system(.title2, design: .serif).weight(.semibold))
                    Text(control.guidance)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(ControlStatus.answerable) { option in
                        answerButton(option)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    TextField("Notes", text: $control.notes, axis: .vertical)
                        .lineLimit(2...6)
                        .focused($notesFocused)
                        .padding(14)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    HStack(spacing: 12) {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button { showingCamera = true } label: {
                                Label("Photo", systemImage: "camera")
                            }
                        }
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label("Library", systemImage: "photo.on.rectangle")
                        }
                        Spacer()
                        let photos = control.evidence?.count ?? 0
                        if photos > 0 {
                            Label("\(photos)", systemImage: "photo.stack")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Button {
                    notesFocused = false
                    next()
                } label: {
                    Label("Next Control", systemImage: "arrow.right")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker { image in addImage(image) }
                .ignoresSafeArea()
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let jpeg = ImageTools.jpegData(from: data) {
                    addEvidence(jpeg)
                }
                photoItem = nil
            }
        }
        .sensoryFeedback(trigger: control.status) { _, new in
            switch new {
            case .pass: .success
            case .fail: .warning
            default: .selection
            }
        }
    }

    private func answerButton(_ option: ControlStatus) -> some View {
        let selected = control.status == option
        return Button {
            control.status = selected ? .notStarted : option
            if !selected { Milestones.increment(Milestones.walkAnswersKey) }
            // Pass and N/A usually need nothing else, so move along. Fail and Partial stay for notes and photos.
            if !selected && (option == .pass || option == .notApplicable) {
                Task {
                    try? await Task.sleep(for: .milliseconds(450))
                    next()
                }
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: option.symbol).font(.title)
                Text(option.label).font(.headline)
            }
            .frame(maxWidth: .infinity, minHeight: 84)
            .background(selected ? option.color.opacity(0.2) : Theme.card,
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(selected ? option.color : .clear, lineWidth: 2.5))
            .foregroundStyle(selected ? option.color : .primary)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
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

private struct WalkFinishedCard: View {
    let audit: Audit
    let done: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            ReassuredMark(size: 120)
            Text(audit.answeredCount == audit.totalCount ? "Walkthrough complete" : "End of the checklist")
                .font(.system(.title, design: .serif).weight(.semibold))
            Text(audit.answeredCount == audit.totalCount
                 ? "Every control has a result. Build the remediation plan or share the report from the audit."
                 : "\(audit.totalCount - audit.answeredCount) controls are still open. Tap Next Open to go back to them.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            if let score = audit.score {
                Text("Score \(Int((score * 100).rounded()))%")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.calmGreen)
            }
            Button("Back to Audit", action: done)
                .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
    }
}
