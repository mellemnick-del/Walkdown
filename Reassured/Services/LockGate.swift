import SwiftUI
import LocalAuthentication

/// Covers the app with a lock screen when Face ID lock is on.
struct LockGate<Content: View>: View {
    @AppStorage(SettingsKeys.requireFaceID) private var requireFaceID = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var unlocked = false
    @State private var authenticating = false
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            content
            if requireFaceID && !unlocked {
                LockScreen(unlock: authenticate)
                    .transition(.opacity)
            }
        }
        .onAppear {
            if requireFaceID { authenticate() } else { unlocked = true }
        }
        .onChange(of: requireFaceID) { _, isOn in
            // Turning the lock on from Settings should not lock you out of the current session.
            if isOn { unlocked = true }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                if requireFaceID { unlocked = false }
            case .active:
                if requireFaceID && !unlocked { authenticate() }
            default:
                break
            }
        }
    }

    private func authenticate() {
        guard !authenticating else { return }
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // No passcode set on the device, so there is nothing to check against.
            unlocked = true
            return
        }
        authenticating = true
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock your audits") { success, _ in
            Task { @MainActor in
                authenticating = false
                withAnimation { unlocked = success }
            }
        }
    }
}

private struct LockScreen: View {
    let unlock: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)
                Text("Reassured is locked")
                    .font(.title2.bold())
                Button("Unlock", action: unlock)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}
