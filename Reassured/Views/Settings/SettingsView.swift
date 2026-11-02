import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKeys.auditorName) private var auditorName = ""
    @AppStorage(SettingsKeys.companyName) private var companyName = ""
    @AppStorage(SettingsKeys.requireFaceID) private var requireFaceID = false
    @AppStorage(SettingsKeys.helpEmail) private var helpEmail = ""
    @AppStorage(SettingsKeys.userRole) private var roleRaw = UserRole.organization.rawValue
    @Environment(LockerLock.self) private var lock
    @State private var settingPasscode = false
    @State private var confirmingRemove = false

    private var biometry: String { LockerLock.biometryName ?? "Face ID" }

    private var lockerToggle: Binding<Bool> {
        Binding(
            get: { lock.isEnabled },
            set: { on in
                if on {
                    if lock.hasPasscode { lock.isEnabled = true } else { settingPasscode = true }
                } else {
                    lock.isEnabled = false
                }
            }
        )
    }

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Your name", text: $auditorName)
                    Picker("I use Reassured for", selection: $roleRaw) {
                        ForEach(UserRole.allCases) { Text($0.label).tag($0.rawValue) }
                    }
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
                    Toggle("Lock the App with \(biometry)", isOn: $requireFaceID)
                } header: {
                    Text("Security")
                } footer: {
                    Text("Asks for \(biometry) or your device passcode whenever Reassured opens. All audit data stays on this device.")
                }
                Section {
                    Toggle("Lock Evidence Locker", isOn: lockerToggle)
                    if lock.isEnabled {
                        if LockerLock.biometryName != nil {
                            Toggle("Unlock with \(biometry)", isOn: Binding(get: { lock.useBiometrics }, set: { lock.useBiometrics = $0 }))
                        }
                        Button("Change Locker Passcode") { settingPasscode = true }
                        Button("Turn Off and Remove Passcode", role: .destructive) { confirmingRemove = true }
                    }
                } footer: {
                    Text("A separate 6-digit passcode for your most sensitive documents. The Locker locks again every time you leave the app.")
                }
                Section {
                    NavigationLink {
                        BackupView()
                    } label: {
                        Label("Backup and Restore", systemImage: "externaldrive")
                    }
                } header: {
                    Text("Your Data")
                } footer: {
                    Text("Everything is stored only on this device. Back up regularly.")
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
            .calmBackground()
            .sheet(isPresented: $settingPasscode) {
                SetPasscodeView { saved in
                    if saved { lock.isEnabled = true }
                }
            }
            .confirmationDialog("Remove the Locker passcode?", isPresented: $confirmingRemove, titleVisibility: .visible) {
                Button("Remove Passcode", role: .destructive) { lock.removePasscode() }
            } message: {
                Text("The Evidence Locker will open without a passcode.")
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
