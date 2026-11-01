import SwiftUI

/// Browse the built-in checklists grouped by audit area.
/// Pass a selection binding to pick one; leave it nil to just browse.
struct ChecklistLibraryView: View {
    var selection: Binding<String>?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private func matches(_ template: ChecklistTemplate) -> Bool {
        guard !searchText.isEmpty else { return true }
        let query = searchText.lowercased()
        return template.name.lowercased().contains(query)
            || template.summary.lowercased().contains(query)
            || template.area.label.lowercased().contains(query)
    }

    var body: some View {
        List {
            ForEach(ChecklistArea.allCases) { area in
                let templates = TemplateLibrary.templates(in: area).filter(matches)
                if !templates.isEmpty {
                    Section {
                        ForEach(templates) { template in
                            row(template)
                        }
                    } header: {
                        Label(area.label, systemImage: area.symbol)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search checklists")
        .calmBackground()
        .navigationTitle("Checklists")
    }

    @ViewBuilder
    private func row(_ template: ChecklistTemplate) -> some View {
        if let selection {
            Button {
                selection.wrappedValue = template.id
                dismiss()
            } label: {
                HStack {
                    TemplateSummary(template: template)
                    Spacer()
                    if selection.wrappedValue == template.id {
                        Image(systemName: "checkmark").foregroundStyle(.tint)
                    }
                }
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink {
                TemplatePreviewView(template: template)
            } label: {
                TemplateSummary(template: template)
            }
        }
    }
}

private struct TemplateSummary: View {
    let template: ChecklistTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(template.name).font(.body.weight(.medium))
            Text("\(template.itemCount) controls. \(template.summary)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }
}

/// A framework's guide, a button to start, and every control in the checklist.
struct TemplatePreviewView: View {
    let template: ChecklistTemplate
    @Environment(AppRouter.self) private var router
    @State private var startingKind: AuditKind?

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Label(template.area.label, systemImage: template.area.symbol)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(template.summary)
                    Text("\(template.itemCount) controls. Source: \(template.source)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        Button("Self-Assess") { startingKind = .selfAssessment }
                            .buttonStyle(.borderedProminent)
                        Button("On-Site Audit") { startingKind = .onSite }
                            .buttonStyle(.bordered)
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 4)
            }

            if let guide = FrameworkGuides.guide(for: template.id) {
                Section("What It Is") { Text(guide.whatItIs) }
                Section("Who Needs It") { Text(guide.whoNeedsIt) }
                Section("How It's Assessed") { Text(guide.howAssessed) }
                Section {
                    ForEach(Array(guide.firstSteps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .frame(width: 22, height: 22)
                                .background(Color.accentColor.opacity(0.15), in: Circle())
                                .foregroundStyle(.tint)
                            Text(step)
                        }
                    }
                } header: {
                    Text("First Steps")
                } footer: {
                    Text("General guidance, not legal advice. Confirm requirements with the official source.")
                }
            }
            ForEach(template.groups, id: \.name) { group in
                Section(group.name) {
                    ForEach(group.items, id: \.id) { item in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.id).font(.caption.monospaced()).foregroundStyle(.secondary)
                            Text(item.title)
                            Text(item.guidance).font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .calmBackground()
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $startingKind) { kind in
            NewAuditView(initialTemplateID: template.id, initialKind: kind) { audit in router.open(audit) }
        }
    }
}
