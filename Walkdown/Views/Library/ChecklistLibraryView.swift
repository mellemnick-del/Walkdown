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

/// Read-only look at every control in a checklist.
struct TemplatePreviewView: View {
    let template: ChecklistTemplate

    var body: some View {
        List {
            Section {
                Text(template.summary)
                LabeledContent("Source", value: template.source)
                    .font(.caption)
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
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
