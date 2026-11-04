import Foundation
import CryptoKit
import LocalAuthentication
import Observation

/// A separate lock for the Evidence Locker: a 6-digit passcode, plus Face ID or Touch ID if wanted.
/// The passcode is stored as a salted hash in the Keychain, never as plain text.
@Observable
final class LockerLock {
    static let passcodeLength = 6
    private static let passcodeKey = "lockerPasscode"
    private static let enabledKey = "lockerLockEnabled"
    private static let biometricsKey = "lockerUseBiometrics"
    private static let deletesKey = "pinForDeletes"
    private static let maxAttempts = 5

    private(set) var isUnlocked = false
    private(set) var failedAttempts = 0
    private(set) var lockedOutUntil: Date?

    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
            if !isEnabled { isUnlocked = false }
        }
    }

    var useBiometrics: Bool {
        didSet { UserDefaults.standard.set(useBiometrics, forKey: Self.biometricsKey) }
    }

    /// Deleting audits and clients asks for the PIN (or Face ID / device passcode when there's no PIN).
    var protectsDeletes: Bool {
        didSet { UserDefaults.standard.set(protectsDeletes, forKey: Self.deletesKey) }
    }

    init() {
        isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        useBiometrics = UserDefaults.standard.object(forKey: Self.biometricsKey) as? Bool ?? true
        protectsDeletes = UserDefaults.standard.object(forKey: Self.deletesKey) as? Bool ?? true
    }

    /// True when the Locker's contents can be shown.
    var isOpen: Bool { !isEnabled || isUnlocked }

    var hasPasscode: Bool { Keychain.get(Self.passcodeKey) != nil }

    var isLockedOut: Bool {
        guard let lockedOutUntil else { return false }
        return lockedOutUntil > .now
    }

    // MARK: Biometrics

    /// "Face ID", "Touch ID", "Optic ID", or nil if the device has none set up.
    static var biometryName: String? {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else { return nil }
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return nil
        }
    }

    @MainActor
    func unlockWithBiometrics() async -> Bool {
        guard useBiometrics, Self.biometryName != nil else { return false }
        let context = LAContext()
        context.localizedFallbackTitle = "Enter Passcode"
        let success = (try? await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                                         localizedReason: "Unlock your Evidence Locker")) ?? false
        if success { didUnlock() }
        return success
    }

    /// Confirms it's the device owner (Face ID, Touch ID, or device passcode) without unlocking anything.
    @MainActor
    func confirmOwner(reason: String) async -> Bool {
        let context = LAContext()
        return (try? await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)) ?? false
    }

    /// For a forgotten passcode: prove you own the device with its Face ID, Touch ID, or passcode.
    @MainActor
    func unlockWithDeviceOwner() async -> Bool {
        let context = LAContext()
        let success = (try? await context.evaluatePolicy(.deviceOwnerAuthentication,
                                                         localizedReason: "Reset your Evidence Locker passcode")) ?? false
        if success { didUnlock() }
        return success
    }

    // MARK: Passcode

    func setPasscode(_ code: String) {
        var salt = Data(count: 16)
        _ = salt.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 16, $0.baseAddress!) }
        Keychain.set(salt + Self.hash(code, salt: salt), for: Self.passcodeKey)
    }

    /// Checks the PIN and opens the Locker. After 5 wrong tries, entry pauses for 30 seconds.
    func unlock(with code: String) -> Bool {
        guard check(code) else { return false }
        didUnlock()
        return true
    }

    /// Checks the PIN without opening the Locker, for confirming deletes. Same 5-try limit.
    func check(_ code: String) -> Bool {
        guard !isLockedOut, let stored = Keychain.get(Self.passcodeKey), stored.count > 16 else { return false }
        let salt = stored.prefix(16)
        if Self.hash(code, salt: Data(salt)) == stored.dropFirst(16) {
            failedAttempts = 0
            lockedOutUntil = nil
            return true
        }
        failedAttempts += 1
        if failedAttempts >= Self.maxAttempts {
            lockedOutUntil = Date.now.addingTimeInterval(30)
            failedAttempts = 0
        }
        return false
    }

    func lock() {
        isUnlocked = false
    }

    func removePasscode() {
        Keychain.delete(Self.passcodeKey)
        isEnabled = false
    }

    private func didUnlock() {
        isUnlocked = true
        failedAttempts = 0
        lockedOutUntil = nil
    }

    private static func hash(_ code: String, salt: Data) -> Data {
        Data(SHA256.hash(data: salt + Data(code.utf8)))
    }
}
