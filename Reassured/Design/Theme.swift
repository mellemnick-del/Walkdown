import SwiftUI

/// Reassured's palette, taken from the app icon: a navy night sky, teal dawn, and a warm sunrise.
enum Theme {
    static let navy = Color(red: 0.059, green: 0.173, blue: 0.361)      // #0F2C5C
    static let deepNavy = Color(red: 0.039, green: 0.090, blue: 0.188)  // #0A1730
    static let teal = Color(red: 0.141, green: 0.373, blue: 0.498)      // #245F7F
    static let ember = Color(red: 0.788, green: 0.541, blue: 0.294)     // #C98A4B
    static let sunrise = Color(red: 1.0, green: 0.851, blue: 0.541)     // #FFD98A
    static let sunriseLight = Color(red: 1.0, green: 0.945, blue: 0.800) // #FFF1CC

    /// The icon's sky: night at the top, dawn at the bottom.
    static let dusk = LinearGradient(
        stops: [
            .init(color: navy, location: 0),
            .init(color: teal, location: 0.72),
            .init(color: ember, location: 1),
        ],
        startPoint: .top, endPoint: .bottom
    )

    static let sun = LinearGradient(colors: [sunriseLight, sunrise], startPoint: .top, endPoint: .bottom)
}

/// The Reassured mark (the cradled sun), drawn in SwiftUI so it stays sharp at any size.
struct ReassuredMark: View {
    var size: CGFloat = 120
    /// 0 is the sun below the cradle and faded out, 1 is fully risen. Used by the opening animation.
    var sunProgress: Double = 1
    /// How much of the cradle is drawn, from 0 to 1.
    var cradleProgress: Double = 1

    var body: some View {
        let unit = size / 644
        ZStack {
            Circle()
                .fill(Theme.sun)
                .frame(width: 340 * unit, height: 340 * unit)
                .offset(y: (500 - 580) * unit + (1 - sunProgress) * 260 * unit)
                .opacity(sunProgress)
            CradleShape()
                .trim(from: 0.5 - cradleProgress / 2, to: 0.5 + cradleProgress / 2)
                .stroke(.white, style: StrokeStyle(lineWidth: 76 * unit, lineCap: .round))
        }
        .frame(width: size, height: size * 580 / 644)
        .accessibilityHidden(true)
    }

    /// The supporting curve under the sun, matching the icon artwork.
    private struct CradleShape: Shape {
        func path(in rect: CGRect) -> Path {
            // Artwork coordinates span x 190...834 and y 290...870.
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: rect.minX + (x - 190) / 644 * rect.width, y: rect.minY + (y - 290) / 580 * rect.height)
            }
            var path = Path()
            path.move(to: point(230, 470))
            path.addCurve(to: point(512, 830), control1: point(230, 730), control2: point(380, 830))
            path.addCurve(to: point(794, 470), control1: point(644, 830), control2: point(794, 730))
            return path
        }
    }
}

extension Theme {
    /// A color that adapts to light and dark mode.
    static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }

    private static func rgb(_ hex: UInt32) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }

    /// Soft background: misty dawn fading into warm cream by day, deep night sky in dark mode.
    static let canvasTop = adaptive(light: rgb(0xE6F0F3), dark: rgb(0x0B1A33))
    static let canvasBottom = adaptive(light: rgb(0xFBF7F0), dark: rgb(0x081224))
    static let canvas = LinearGradient(colors: [canvasTop, canvasBottom], startPoint: .top, endPoint: .bottom)

    /// Calm status colors that still read clearly.
    static let calmGreen = adaptive(light: rgb(0x2FA67A), dark: rgb(0x5FD3A6))
    static let calmAmber = adaptive(light: rgb(0xD9922E), dark: rgb(0xF2B866))
    static let calmCoral = adaptive(light: rgb(0xD9534F), dark: rgb(0xF07C76))
    static let calmPlum = adaptive(light: rgb(0x8A5FBF), dark: rgb(0xB592E0))
    static let calmBlue = adaptive(light: rgb(0x2F7FA6), dark: rgb(0x6CC3D6))

    /// Navy titles by day, white by night.
    static let titleUIColor = UIColor { $0.userInterfaceStyle == .dark ? .white : rgb(0x0F2C5C) }

    /// Rounded, friendly navigation titles across the app.
    static func applyNavigationStyle() {
        func rounded(_ style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
            let base = UIFont.preferredFont(forTextStyle: style)
            let font = UIFont.systemFont(ofSize: base.pointSize, weight: weight)
            guard let descriptor = font.fontDescriptor.withDesign(.rounded) else { return font }
            return UIFont(descriptor: descriptor, size: base.pointSize)
        }
        let appearance = UINavigationBar.appearance()
        appearance.largeTitleTextAttributes = [.font: rounded(.largeTitle, weight: .bold), .foregroundColor: titleUIColor]
        appearance.titleTextAttributes = [.font: rounded(.headline, weight: .semibold), .foregroundColor: titleUIColor]
    }
}

extension View {
    /// The calm Reassured background behind lists, forms, and scroll views.
    func calmBackground() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Theme.canvas.ignoresSafeArea())
    }
}
