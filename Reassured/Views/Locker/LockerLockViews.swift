import SwiftUI

/// Shows its content only when the Evidence Locker is unlocked (or the lock is off).
struct LockerGate<Content: View>: View {
    @Environment(LockerLock.self) private var lock
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if lock.isOpen {
            content
        } else {
            LockerLockScreen()
        }
    }
}

/// The calm unlock screen: Face ID or Touch ID first, with the passcode keypad as backup.
struct LockerLockScreen: View {
    @Environment(LockerLock.self) private var lock
    @State private var code = ""
    @State private var shake = false
    @State private var message: String?
    @State private var resetting = false
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                ZStack {
                    Circle().fill(Theme.dusk).frame(width: 96, height: 96)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(Theme.sunrise)
                }
                .padding(.top, 40)

                VStack(spacing: 6) {
                    Text("Evidence Locker is locked")
                        .font(.system(.title2, design: .serif).weight(.semibold))
                    Text("Enter your Reassured PIN to open it.")
                        .foregroundStyle(.secondary)
                }

                PasscodeDots(count: code.count)
                    .offset(x: shake ? -10 : 0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.2), value: shake)
                    .onTapGesture { focused = true }

                SecureField("", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($focused)
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
                    .onChange(of: code) { _, newValue in
                        let digits = String(newValue.filter(\.isNumber).prefix(LockerLock.passcodeLength))
                        if digits != newValue { code = digits }
                        if digits.count == LockerLock.passcodeLength { submit(digits) }
                    }

                if let message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(Theme.calmCoral)
                        .multilineTextAlignment(.center)
                }

                if lock.useBiometrics, let name = LockerLock.biometryName {
                    Button {
                        Task { _ = await lock.unlockWithBiometrics() }
                    } label: {
                        Label("Unlock with \(name)", systemImage: name == "Touch ID" ? "touchid" : "faceid")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Theme.sunrise, in: Capsule())
                            .foregroundStyle(Theme.deepNavy)
                    }
                }

                Button("Forgot PIN?") { resetting = true }
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .calmBackground()
        .task {
            if lock.useBiometrics, LockerLock.biometryName != nil, await lock.unlockWithBiometrics() { return }
            focused = true
        }
        .sheet(isPresented: $resetting) {
            ResetPasscodeSheet()
        }
    }

    private func submit(_ digits: String) {
        if lock.isLockedOut {
            message = "Too many tries. Wait 30 seconds and try again."
        } else if lock.unlock(with: digits) {
            message = nil
            return
        } else {
            message = lock.isLockedOut ? "Too many tries. Wait 30 seconds and try again." : "That PIN didn't match."
        }
        shake.toggle()
        code = ""
    }
}

/// Six dots that fill in as the passcode is typed.
struct PasscodeDots: View {
    let count: Int

    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<LockerLock.passcodeLength, id: \.self) { index in
                Circle()
                    .strokeBorder(Theme.teal, lineWidth: 2)
                    .background(Circle().fill(index < count ? Theme.teal : .clear))
                    .frame(width: 16, height: 16)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) of \(LockerLock.passcodeLength) digits entered")
    }
}

/// Create or change the Locker passcode: enter it twice.
struct SetPasscodeView: View {
    var onFinish: (Bool) -> Void

    @Environment(LockerLock.self) private var lock
    @Environment(\.dismiss) private var dismiss
    @State private var first = ""
    @State private var code = ""
    @State private var message: String?
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                    .padding(.top, 30)
                Text(first.isEmpty ? "Choose a 6-digit Reassured PIN" : "Enter it again to confirm")
                    .font(.system(.title3, design: .serif).weight(.semibold))
                    .multilineTextAlignment(.center)
                PasscodeDots(count: code.count)
                    .onTapGesture { focused = true }
                SecureField("", text: $code)
                    .keyboardType(.numberPad)
                    .focused($focused)
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
                    .onChange(of: code) { _, newValue in
                        let digits = String(newValue.filter(\.isNumber).prefix(LockerLock.passcodeLength))
                        if digits != newValue { code = digits }
                        if digits.count == LockerLock.passcodeLength { step(digits) }
                    }
                if let message {
                    Text(message).font(.subheadline).foregroundStyle(Theme.calmCoral)
                }
                Text("Use something different from your phone's passcode. If you forget it, you can reset it with your device's Face ID, Touch ID, or passcode.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .calmBackground()
            .navigationTitle("Reassured PIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onFinish(false)
                        dismiss()
                    }
                }
            }
            .onAppear { focused = true }
            .interactiveDismissDisabled()
        }
    }

    private func step(_ digits: String) {
        if first.isEmpty {
            first = digits
            code = ""
            message = nil
        } else if digits == first {
            lock.setPasscode(digits)
            onFinish(true)
            dismiss()
        } else {
            first = ""
            code = ""
            message = "Those didn't match. Start again."
        }
    }
}

/// Forgot the passcode: verify with the device, then choose a new one.
private struct ResetPasscodeSheet: View {
    @Environment(LockerLock.self) private var lock
    @Environment(\.dismiss) private var dismiss
    @State private var verified = false

    var body: some View {
        Group {
            if verified {
                SetPasscodeView { _ in }
            } else {
                VStack(spacing: 18) {
                    Image(systemName: "key.fill").font(.system(size: 44)).foregroundStyle(.tint)
                    Text("Reset Reassured PIN").font(.title3.bold())
                    Text("Confirm it's you with your device's Face ID, Touch ID, or passcode, then choose a new PIN.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("Verify It's Me") {
                        Task { verified = await lock.unlockWithDeviceOwner() }
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Cancel") { dismiss() }
                }
                .padding(30)
                .presentationDetents([.medium])
            }
        }
    }
}

/// Something destructive waiting for confirmation. Holds plain text only, so the sheet never
/// reads a record that's about to be deleted.
struct DeleteRequest: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let perform: () -> Void
}

/// Confirms a delete by typing DELETE, or with the Reassured PIN when Use PIN for Deletes is on.
struct ConfirmDeleteView: View {
    let request: DeleteRequest

    @Environment(LockerLock.self) private var lock
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var typed = ""
    @State private var message: String?
    @State private var shake = false
    @FocusState private var focused: Bool

    private var usesPIN: Bool { lock.hasPasscode && lock.protectsDeletes }
    private var typedMatches: Bool { typed.trimmingCharacters(in: .whitespaces).uppercased() == "DELETE" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    ZStack {
                        Circle().fill(Theme.calmCoral.opacity(0.15)).frame(width: 84, height: 84)
                        Image(systemName: "trash.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(Theme.calmCoral)
                    }
                    .padding(.top, 24)
                    Text(request.title)
                        .font(.system(.title3, design: .serif).weight(.semibold))
                        .multilineTextAlignment(.center)
                    Text(request.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    if usesPIN {
                        Text("Enter your Reassured PIN to delete.")
                            .font(.subheadline.weight(.semibold))
                            .padding(.top, 6)
                        PasscodeDots(count: code.count)
                            .offset(x: shake ? -10 : 0)
                            .animation(.spring(response: 0.2, dampingFraction: 0.2), value: shake)
                            .onTapGesture { focused = true }
                        SecureField("", text: $code)
                            .keyboardType(.numberPad)
                            .focused($focused)
                            .frame(width: 1, height: 1)
                            .opacity(0.01)
                            .onChange(of: code) { _, newValue in
                                let digits = String(newValue.filter(\.isNumber).prefix(LockerLock.passcodeLength))
                                if digits != newValue { code = digits }
                                if digits.count == LockerLock.passcodeLength { submit(digits) }
                            }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type DELETE to confirm.")
                                .font(.subheadline.weight(.semibold))
                            TextField("DELETE", text: $typed)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .focused($focused)
                                .submitLabel(.done)
                                .onSubmit { if typedMatches { confirmed() } }
                                .padding(12)
                                .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(typedMatches ? Theme.calmCoral : Color.secondary.opacity(0.3), lineWidth: 1.5))
                        }
                        .padding(.top, 6)
                        Button(action: confirmed) {
                            Text("Delete")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.calmCoral)
                        .disabled(!typedMatches)
                    }

                    if let message {
                        Text(message).font(.subheadline).foregroundStyle(Theme.calmCoral)
                    }
                }
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity)
            }
            .calmBackground()
            .navigationTitle("Confirm Delete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.large])
    }

    private func submit(_ digits: String) {
        if lock.isLockedOut {
            message = "Too many tries. Wait 30 seconds and try again."
        } else if lock.check(digits) {
            confirmed()
            return
        } else {
            message = lock.isLockedOut ? "Too many tries. Wait 30 seconds and try again." : "That PIN didn't match. Nothing was deleted."
        }
        shake.toggle()
        code = ""
    }

    private func confirmed() {
        let perform = request.perform
        dismiss()
        // Delete after the sheet has gone, so nothing on screen is showing the deleted record.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            perform()
        }
    }
}
