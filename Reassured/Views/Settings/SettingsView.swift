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
    @State private var enableLockerAfterPIN = false

    private var biometry: String { LockerLock.biometryName ?? "Face ID" }

    private var lockerToggle: Binding<Bool> {
        Binding(
            get: { lock.isEnabled },
            set: { on in
                if on {
                    if lock.hasPasscode {
                        lock.isEnabled = true
                    } else {
                        enableLockerAfterPIN = true
                        settingPasscode = true
                    }
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
                    if lock.hasPasscode {
                        Button("Change PIN") { settingPasscode = true }
                    } else {
                        Button { settingPasscode = true } label: {
                            Label("Set Up Reassured PIN", systemImage: "lock.shield")
                        }
                    }
                    if lock.hasPasscode {
                        Toggle("Use PIN for Deletes", isOn: Binding(get: { lock.protectsDeletes }, set: { lock.protectsDeletes = $0 }))
                    }
                    Toggle("Lock Evidence Locker", isOn: lockerToggle)
                    if lock.isEnabled, LockerLock.biometryName != nil {
                        Toggle("Unlock Locker with \(biometry)", isOn: Binding(get: { lock.useBiometrics }, set: { lock.useBiometrics = $0 }))
                    }
                    if lock.hasPasscode {
                        Button("Remove PIN", role: .destructive) { confirmingRemove = true }
                    }
                } header: {
                    Text("Reassured PIN")
                } footer: {
                    Text("One 6-digit PIN. It can lock the Evidence Locker, which locks again every time you leave the app. Deletes always need you to type DELETE; turn on Use PIN for Deletes to ask for the PIN instead.")
                }
                Section {
                    NavigationLink {
                        MilestonesView()
                    } label: {
                        Label("Milestones", systemImage: "rosette")
                    }
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
                    if saved && enableLockerAfterPIN { lock.isEnabled = true }
                    enableLockerAfterPIN = false
                }
            }
            .confirmationDialog("Remove your Reassured PIN?", isPresented: $confirmingRemove, titleVisibility: .visible) {
                Button("Remove PIN", role: .destructive) { lock.removePasscode() }
            } message: {
                Text("The Evidence Locker will open without a PIN, and deletes will ask you to type DELETE.")
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
