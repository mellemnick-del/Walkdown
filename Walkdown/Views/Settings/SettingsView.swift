import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKeys.auditorName) private var auditorName = ""
    @AppStorage(SettingsKeys.companyName) private var companyName = ""
    @AppStorage(SettingsKeys.requireFaceID) private var requireFaceID = false

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Your name", text: $auditorName)
                    TextField("Company", text: $companyName)
                } header: {
                    Text("Reports")
                } footer: {
                    Text("Your name fills in new audits. Your company appears on report cover pages.")
                }
                Section {
                    Toggle("Require Face ID", isOn: $requireFaceID)
                } header: {
                    Text("Security")
                } footer: {
                    Text("Locks Walkdown whenever it goes to the background. All audit data stays on this device.")
                }
                Section("Checklists") {
                    ForEach(TemplateLibrary.all) { template in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.name)
                            Text("\(template.itemCount) controls. Source: \(template.source)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section {
                    LabeledContent("Version", value: version)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
