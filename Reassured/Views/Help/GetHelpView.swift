import SwiftUI

/// "Talk to an expert" plus trusted official resources.
struct GetHelpView: View {
    var topic: String?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage(SettingsKeys.helpEmail) private var helpEmail = ""

    private struct Resource: Identifiable {
        let name: String
        let detail: String
        let url: String
        var id: String { url }
    }

    private let resources: [Resource] = [
        Resource(name: "CISA Services", detail: "Free federal cybersecurity services and tools", url: "https://www.cisa.gov/resources-tools/services"),
        Resource(name: "NIST Cybersecurity Framework", detail: "The CSF and quick start guides", url: "https://www.nist.gov/cyberframework"),
        Resource(name: "CMMC (DoD CIO)", detail: "Official CMMC program information", url: "https://dodcio.defense.gov/CMMC/"),
        Resource(name: "HHS HIPAA Security", detail: "HIPAA Security Rule guidance", url: "https://www.hhs.gov/hipaa/for-professionals/security/index.html"),
        Resource(name: "PCI Security Standards Council", detail: "PCI DSS documents and SAQs", url: "https://www.pcisecuritystandards.org"),
    ]

    private var mailURL: URL? {
        guard !helpEmail.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = helpEmail
        components.queryItems = [URLQueryItem(name: "subject", value: topic.map { "Reassured help: \($0)" } ?? "Reassured help request")]
        return components.url
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "person.wave.2.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.tint)
                        Text("Talk to an expert")
                            .font(.title3.bold())
                        Text("Stuck on a control or not sure where to start? Reach out and get help from someone who does this every day.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let mailURL {
                            Button("Email for Help") { openURL(mailURL) }
                                .buttonStyle(.borderedProminent)
                                .padding(.top, 4)
                        } else {
                            Text("Add a help contact email in Settings to turn this on.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("Official Resources") {
                    ForEach(resources) { resource in
                        if let url = URL(string: resource.url) {
                            Link(destination: url) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(resource.name)
                                    Text(resource.detail).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .calmBackground()
            .navigationTitle("Get Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
