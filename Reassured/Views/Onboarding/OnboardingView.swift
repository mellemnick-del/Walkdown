import SwiftUI

struct OnboardingView: View {
    @AppStorage(SettingsKeys.hasOnboarded) private var hasOnboarded = false
    @AppStorage(SettingsKeys.userRole) private var roleRaw = UserRole.organization.rawValue
    @AppStorage(SettingsKeys.auditorName) private var name = ""
    @AppStorage(SettingsKeys.companyName) private var company = ""
    @State private var page = 0

    var body: some View {
        TabView(selection: $page) {
            welcome.tag(0)
            rolePicker.tag(1)
            details.tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .background(Theme.canvas.ignoresSafeArea())
        .interactiveDismissDisabled()
    }

    private var welcome: some View {
        VStack(spacing: 20) {
            Spacer()
            ReassuredMark(size: 150)
            Text("Reassured")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Know where you stand.\nKnow what to fix next.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.85))
            VStack(alignment: .leading, spacing: 14) {
                Feature(symbol: "checklist", text: "Audit against CMMC, HIPAA, PCI, SOC 2, NIST, and more")
                Feature(symbol: "wrench.and.screwdriver", text: "Turn every gap into a prioritized task")
                Feature(symbol: "lock.doc", text: "Keep evidence in one place, with expiration reminders")
                Feature(symbol: "lock.shield", text: "Everything stays on your device")
            }
            .padding(.top, 12)
            .foregroundStyle(.white)
            Spacer()
            Button { withAnimation { page = 1 } } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.sunrise, in: Capsule())
                    .foregroundStyle(Theme.deepNavy)
            }
            .padding(.bottom, 48)
        }
        .padding(.horizontal, 24)
        .background(Theme.dusk.ignoresSafeArea())
    }

    private var rolePicker: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Who are you using Reassured for?")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("You can change this later in Settings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ForEach(UserRole.allCases) { role in
                Button {
                    roleRaw = role.rawValue
                    withAnimation { page = 2 }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: role.symbol)
                            .font(.largeTitle)
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(role.label).font(.headline)
                            Text(role.detail).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(roleRaw == role.rawValue ? Color.accentColor : .clear, lineWidth: 2))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var details: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("A little about you")
                .font(.title2.bold())
            Text("Used on your reports. Optional.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            VStack(spacing: 12) {
                TextField("Your name", text: $name)
                    .textContentType(.name)
                TextField(roleRaw == UserRole.assessor.rawValue ? "Your firm" : "Your organization", text: $company)
                    .textContentType(.organizationName)
            }
            .textFieldStyle(.roundedBorder)
            Spacer()
            Button { hasOnboarded = true } label: {
                Text("Start Using Reassured").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 48)
        }
        .padding(.horizontal, 24)
    }
}

private struct Feature: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Theme.sunrise)
                .frame(width: 30)
            Text(text)
        }
    }
}
