#if DEBUG
import SwiftUI

/// Debug-only sampler for choosing the app's headline font. Open with -demo -screen fonts.
struct FontPreviewView: View {
    private struct Option: Identifiable {
        let id: String
        let note: String
        let title: Font
        let headline: Font
        let number: Font
    }

    private let options: [Option] = [
        Option(id: "1. SF Rounded (current)", note: "Friendly and soft, Apple's rounded system font",
               title: .system(size: 30, weight: .bold, design: .rounded),
               headline: .system(.headline, design: .rounded),
               number: .system(size: 34, weight: .bold, design: .rounded)),
        Option(id: "2. New York serif", note: "Apple's built-in editorial serif. Warm, literary, calm",
               title: .system(size: 30, weight: .semibold, design: .serif),
               headline: .system(.headline, design: .serif),
               number: .system(size: 34, weight: .semibold, design: .serif)),
        Option(id: "3. Serif headlines, rounded details", note: "New York for big moments, SF Rounded for everything else",
               title: .system(size: 30, weight: .semibold, design: .serif),
               headline: .system(.headline, design: .rounded),
               number: .system(size: 34, weight: .bold, design: .rounded)),
        Option(id: "4. SF Pro (standard)", note: "The default iPhone font. Clean, neutral",
               title: .system(size: 30, weight: .bold),
               headline: .headline,
               number: .system(size: 34, weight: .bold)),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Font options")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                ForEach(options) { option in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(option.id).font(.caption.bold()).foregroundStyle(Theme.teal)
                        Text("Good evening, Nick").font(option.title).foregroundStyle(Theme.navy)
                        HStack(alignment: .firstTextBaseline, spacing: 14) {
                            Text("77%").font(option.number).foregroundStyle(Theme.calmAmber)
                            Text("Know where you stand.").font(option.headline)
                        }
                        Text(option.note).font(.footnote).foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            .padding()
        }
        .calmBackground()
    }
}
#endif
