import SwiftUI
import PhotosUI

struct BrandingView: View {
    @AppStorage(SettingsKeys.companyName) private var companyName = ""
    @AppStorage(Branding.colorKey) private var colorHex = Branding.defaultHex
    @State private var logo: UIImage?
    @State private var logoItem: PhotosPickerItem?

    private var color: Binding<Color> {
        Binding(
            get: { Color(uiColor: Branding.uiColor(hex: colorHex)) },
            set: { colorHex = Branding.hex(from: $0) }
        )
    }

    var body: some View {
        Form {
            Section {
                BrandPreview(logo: logo, name: companyName, color: Color(uiColor: Branding.uiColor(hex: colorHex)))
                    .listRowInsets(EdgeInsets())
            }

            Section("Organization") {
                TextField("Company name", text: $companyName)
            }

            Section {
                PhotosPicker(selection: $logoItem, matching: .images) {
                    Label(logo == nil ? "Choose Logo" : "Change Logo", systemImage: "photo")
                }
                if logo != nil {
                    Button("Remove Logo", role: .destructive) {
                        Branding.removeLogo()
                        logo = nil
                    }
                }
            } header: {
                Text("Logo")
            } footer: {
                Text("Appears on report cover pages. A square or wide logo on a transparent background works best.")
            }

            Section {
                ColorPicker("Brand color", selection: color, supportsOpacity: false)
                Button("Reset to Default") { colorHex = Branding.defaultHex }
            } header: {
                Text("Color")
            } footer: {
                Text("Used for buttons and highlights in the app, and for headings in reports.")
            }
        }
        .calmBackground()
        .navigationTitle("Branding")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { logo = Branding.loadLogo() }
        .onChange(of: logoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    Branding.saveLogo(image)
                    logo = Branding.loadLogo()
                }
                logoItem = nil
            }
        }
    }
}

private struct BrandPreview: View {
    let logo: UIImage?
    let name: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            if let logo {
                Image(uiImage: logo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 60)
            }
            Text("Security Audit Report")
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(name.isEmpty ? "Your Company" : name)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Capsule().fill(color).frame(width: 60, height: 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
