import SwiftUI
import PDFKit

/// Preview, adjust, and share or print the Certificate of Completion.
struct CertificateView: View {
    let audit: Audit
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKeys.companyName) private var companyName = ""
    @State private var includeScore = true
    @State private var signerName = ""
    @State private var signerTitle = ""
    @State private var pdfURL: URL?
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let pdfURL {
                        PDFPreview(url: pdfURL)
                            .frame(height: 260)
                            .listRowInsets(EdgeInsets())
                    } else {
                        ProgressView().frame(maxWidth: .infinity, minHeight: 260)
                    }
                }
                Section {
                    Toggle("Show the score", isOn: $includeScore)
                    TextField("Signed by", text: $signerName)
                    TextField("Title (optional)", text: $signerTitle)
                } header: {
                    Text("Details")
                } footer: {
                    Text("Certificate ID \(CertificateBuilder.certificateID(for: audit)). The certificate recognizes that the assessment was completed. It doesn't claim compliance.")
                }
                Section {
                    if let pdfURL {
                        ShareLink(item: pdfURL) {
                            Label("Share or Print Certificate", systemImage: "printer")
                        }
                    }
                } footer: {
                    Text("Use Print in the share sheet for paper, or send the PDF to your client.")
                }
            }
            .calmBackground()
            .navigationTitle("Certificate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                signerName = audit.auditorName
            }
            .task(id: "\(includeScore)|\(signerName)|\(signerTitle)") {
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                pdfURL = try? CertificateBuilder.makePDF(
                    for: audit, companyName: companyName,
                    options: .init(includeScore: includeScore, signerName: signerName, signerTitle: signerTitle))
            }
        }
    }
}

private struct PDFPreview: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePage
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        view.document = PDFDocument(url: url)
    }
}
