import SwiftUI
import SwiftData

struct AuditWorkspaceView: View {
    @Bindable var audit: Audit
    @State private var filter: ControlFilter = .all
    @State private var showingInfo = false
    @State private var showingHelp = false
    @State private var planMessage: String?
    @State private var celebrating = false
    @Environment(\.modelContext) private var context

    enum ControlFilter: String, CaseIterable, Identifiable {
        case all, open, issues

        var id: String { rawValue }

        var label: String {
            switch self {
            case .all: "All Controls"
            case .open: "Not Started"
            case .issues: "Fail and Partial"
            }
        }

        func includes(_ control: ControlResult) -> Bool {
            switch self {
            case .all: true
            case .open: control.status == .notStarted
            case .issues: control.status == .fail || control.status == .partial
            }
        }
    }

    private struct ControlGroup: Identifiable {
        let name: String
        var controls: [ControlResult]
        var id: String { name }
    }

    private var groups: [ControlGroup] {
        var result: [ControlGroup] = []
        for control in audit.sortedControls where filter.includes(control) {
            if result.last?.name == control.groupName {
                result[result.count - 1].controls.append(control)
            } else {
                result.append(ControlGroup(name: control.groupName, controls: [control]))
            }
        }
        return result
    }

    var body: some View {
        List {
            Section {
                ProgressHeader(audit: audit)
            }

            if groups.isEmpty {
                ContentUnavailableView("Nothing Here", systemImage: "line.3.horizontal.decrease.circle",
                                       description: Text("No controls match \"\(filter.label)\"."))
                    .listRowBackground(Color.clear)
            }

            ForEach(groups) { group in
                Section {
                    ForEach(group.controls) { control in
                        NavigationLink {
                            ControlDetailView(control: control)
                        } label: {
                            ControlRow(control: control)
                        }
                    }
                } header: {
                    AreaHeader(name: group.name, controls: audit.sortedControls.filter { $0.groupName == group.name })
                }
            }
        }
        .calmBackground()
        .navigationTitle(audit.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Picker("Show", selection: $filter) {
                        ForEach(ControlFilter.allCases) { Text($0.label).tag($0) }
                    }
                } label: {
                    Label("Filter", systemImage: filter == .all
                          ? "line.3.horizontal.decrease.circle"
                          : "line.3.horizontal.decrease.circle.fill")
                }
                Menu {
                    Button(action: buildPlan) {
                        Label("Build Remediation Plan", systemImage: "wrench.and.screwdriver")
                    }
                    Button { showingHelp = true } label: { Label("Get Help", systemImage: "person.wave.2") }
                    Divider()
                    Button { showingInfo = true } label: { Label("Audit Details", systemImage: "info.circle") }
                    if audit.status == .inProgress {
                        Button {
                            audit.status = .complete
                            celebrating = true
                        } label: {
                            Label("Mark Complete", systemImage: "checkmark.seal")
                        }
                    } else {
                        Button { audit.status = .inProgress } label: {
                            Label("Reopen Audit", systemImage: "arrow.uturn.backward")
                        }
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                NavigationLink {
                    FindingsListView(audit: audit)
                } label: {
                    Label("Findings (\(audit.findings?.count ?? 0))", systemImage: "exclamationmark.triangle")
                        .labelStyle(.titleAndIcon)
                }
                Spacer()
                NavigationLink {
                    ReportView(audit: audit)
                } label: {
                    Label("Report", systemImage: "doc.richtext")
                        .labelStyle(.titleAndIcon)
                }
            }
        }
        .sheet(isPresented: $showingInfo) { AuditInfoView(audit: audit) }
        .overlay {
            if celebrating {
                CompletionCelebration(score: audit.score) { celebrating = false }
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: celebrating)
        .sensoryFeedback(.success, trigger: celebrating) { _, new in new }
        .sheet(isPresented: $showingHelp) { GetHelpView(topic: audit.checklistName) }
        .alert("Remediation Plan", isPresented: Binding(
            get: { planMessage != nil },
            set: { if !$0 { planMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(planMessage ?? "")
        }
    }

    private func buildPlan() {
        let created = RemediationPlanner.buildPlan(for: audit, in: context)
        planMessage = created == 0
            ? "Every failed or partial control already has an open task."
            : "Created \(created) task\(created == 1 ? "" : "s") from failed and partial controls. Find them in the Tasks tab."
    }
}

private struct ProgressHeader: View {
    let audit: Audit

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(audit.answeredCount) of \(audit.totalCount) controls done")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                let openTasks = audit.openTasks.count
                if openTasks > 0 {
                    Label("\(openTasks)", systemImage: "wrench.and.screwdriver")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("\(openTasks) open tasks")
                }
                if audit.status != .inProgress {
                    Text(audit.status.label)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
            ProgressView(value: audit.progress)
            HStack(spacing: 12) {
                ForEach(ControlStatus.answerable) { status in
                    HStack(spacing: 4) {
                        Image(systemName: status.symbol)
                        Text("\(audit.count(status))")
                            .monospacedDigit()
                    }
                    .foregroundStyle(status.color)
                    .lineLimit(1)
                    .fixedSize()
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(audit.count(status)) \(status.label)")
                }
                Spacer(minLength: 8)
                if let score = audit.score {
                    Text("Score \(Int((score * 100).rounded()))%")
                        .font(.caption.bold())
                        .monospacedDigit()
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

private struct ControlRow: View {
    let control: ControlResult

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            StatusIcon(status: control.status)
            VStack(alignment: .leading, spacing: 3) {
                Text(control.controlID)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Text(control.title)
                    .font(.body)
                HStack(spacing: 10) {
                    let photos = control.evidence?.count ?? 0
                    let findings = control.findings?.count ?? 0
                    if photos > 0 { Label("\(photos)", systemImage: "camera") }
                    if findings > 0 { Label("\(findings)", systemImage: "exclamationmark.triangle") }
                    if !control.notes.isEmpty { Image(systemName: "note.text").accessibilityLabel("Has notes") }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

/// Area name with a small progress bar and count, used as each section's header.
private struct AreaHeader: View {
    let name: String
    let controls: [ControlResult]

    var body: some View {
        let done = controls.filter { $0.status != .notStarted }.count
        let progress = controls.isEmpty ? 0 : Double(done) / Double(controls.count)
        HStack(spacing: 10) {
            Text(name)
            Spacer(minLength: 8)
            Capsule()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 54, height: 5)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(progress >= 1 ? Theme.calmGreen : Color.accentColor)
                        .frame(width: 54 * progress, height: 5)
                }
            Text("\(done)/\(controls.count)")
                .monospacedDigit()
                .fixedSize()
        }
    }
}

/// A short, calm celebration when an audit is marked complete.
private struct CompletionCelebration: View {
    let score: Double?
    let dismiss: () -> Void
    @State private var rise = false

    var body: some View {
        ZStack {
            Theme.dusk.opacity(0.96).ignoresSafeArea()
            VStack(spacing: 18) {
                ReassuredMark(size: 140)
                    .offset(y: rise ? 0 : 40)
                    .opacity(rise ? 1 : 0)
                Text("Audit complete")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                if let score {
                    Text("Final score \(Int((score * 100).rounded()))%")
                        .font(.headline)
                        .foregroundStyle(Theme.sunrise)
                }
                Text("Build the remediation plan and share the report when you're ready.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 40)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: dismiss)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) { rise = true }
        }
        .task {
            try? await Task.sleep(for: .seconds(2.6))
            dismiss()
        }
        .accessibilityAddTraits(.isModal)
    }
}
