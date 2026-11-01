import SwiftUI
import UIKit

/// Organization branding: logo, brand color, and company name.
/// This is the foundation for white-label plans, where a paying organization brands the app and its reports.
enum Branding {
    static let colorKey = "brandColorHex"
    static let defaultHex = "1F6F8B"

    private static var logoURL: URL? {
        guard let folder = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                        appropriateFor: nil, create: true) else { return nil }
        return folder.appendingPathComponent("brand-logo.png")
    }

    static func loadLogo() -> UIImage? {
        guard let url = logoURL, let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Saves the logo as PNG, scaled down to at most 600 px.
    static func saveLogo(_ image: UIImage) {
        guard let url = logoURL else { return }
        let scale = min(1, 600 / max(image.size.width, image.size.height, 1))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        try? resized.pngData()?.write(to: url, options: [.atomic, .completeFileProtection])
    }

    static func removeLogo() {
        guard let url = logoURL else { return }
        try? FileManager.default.removeItem(at: url)
    }

    static func uiColor(hex: String) -> UIColor {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else {
            return uiColor(hex: defaultHex)
        }
        return UIColor(red: CGFloat((value >> 16) & 0xFF) / 255,
                       green: CGFloat((value >> 8) & 0xFF) / 255,
                       blue: CGFloat(value & 0xFF) / 255,
                       alpha: 1)
    }

    static func hex(from color: Color) -> String {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        func clamp(_ v: CGFloat) -> Int { Int((min(max(v, 0), 1) * 255).rounded()) }
        return String(format: "%02X%02X%02X", clamp(red), clamp(green), clamp(blue))
    }

    static var currentUIColor: UIColor {
        uiColor(hex: UserDefaults.standard.string(forKey: colorKey) ?? defaultHex)
    }
}
