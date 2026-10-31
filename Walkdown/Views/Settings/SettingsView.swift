import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKeys.auditorName) private var auditorName = ""
    @AppStorage(SettingsKeys.companyName) private var companyName = ""
    @AppStorage(SettingsKeys.requireFaceID) private var requireFaceID = false
    @AppStorage(SettingsKeys.helpEmail) private var helpEmail = ""

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Your name", text: $auditorName)
                    NavigationLink {
                        BrandingView()
                    } label: {
                        LabeledContent("Branding", value: companyName.isEmpty ? "Not set" : companyName)
                    }
                } header: {
                    Text("You and Your Organization")
                } footer: {
                    Text("Your name fills in new audits. Branding adds your company name, logo, and color to the app and reports.")
                }
                Section {
                    TextField("help@example.com", text: $helpEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Get Help Contact")
                } footer: {
                    Text("Where \"Email for Help\" requests go. Leave blank to show official resources only.")
                }
                Section {
                    Toggle("Require Face ID", isOn: $requireFaceID)
                } header: {
                    Text("Security")
                } footer: {
                    Text("Locks Walkdown whenever it goes to the background. All audit data stays on this device.")
                }
                Section("Checklists") {
                    NavigationLink {
                        ChecklistLibraryView()
                    } label: {
                        LabeledContent("Checklist Library", value: "\(TemplateLibrary.all.count)")
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
