import UIKit
import UniformTypeIdentifiers

/// Turns files, photos, and scans into data ready for the Evidence Locker.
enum EvidenceImporter {
    struct Imported {
        let data: Data
        let fileName: String
        let contentType: UTType
        let suggestedTitle: String
    }

    static func file(at url: URL) throws -> Imported {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        let type = UTType(filenameExtension: url.pathExtension) ?? .data
        return Imported(data: data, fileName: url.lastPathComponent, contentType: type,
                        suggestedTitle: url.deletingPathExtension().lastPathComponent)
    }

    static func photo(_ data: Data) -> Imported? {
        guard let jpeg = ImageTools.jpegData(from: data) else { return nil }
        let stamp = Date.now.formatted(.iso8601.year().month().day())
        return Imported(data: jpeg, fileName: "Photo-\(stamp).jpg", contentType: .jpeg, suggestedTitle: "Photo \(stamp)")
    }

    /// Combines scanned pages into a single PDF.
    static func scan(_ pages: [UIImage]) -> Imported? {
        guard !pages.isEmpty else { return nil }
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let data = UIGraphicsPDFRenderer(bounds: pageRect).pdfData { context in
            for page in pages {
                context.beginPage()
                let scale = min(pageRect.width / page.size.width, pageRect.height / page.size.height)
                let size = CGSize(width: page.size.width * scale, height: page.size.height * scale)
                let origin = CGPoint(x: (pageRect.width - size.width) / 2, y: (pageRect.height - size.height) / 2)
                page.draw(in: CGRect(origin: origin, size: size))
            }
        }
        let stamp = Date.now.formatted(.iso8601.year().month().day())
        return Imported(data: data, fileName: "Scan-\(stamp).pdf", contentType: .pdf, suggestedTitle: "Scanned document")
    }
}
