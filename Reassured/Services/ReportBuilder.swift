import UIKit

/// Builds the audit report as a US Letter PDF.
enum ReportBuilder {
    static func makePDF(for audit: Audit, companyName: String, summary: String = "") throws -> URL {
        let writer = PDFWriter(footer: "\(audit.displayName)  |  Confidential", accent: Branding.currentUIColor)
        let data = writer.render { w in
            cover(audit, companyName: companyName, w)
            summarySection(audit, narrative: summary, w)
            findings(audit, w)
            controls(audit, w)
            evidenceIndex(audit, w)
        }
        let safeName = audit.clientName.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }.joined(separator: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Reassured-\(safeName.isEmpty ? "Audit" : safeName).pdf")
        try data.write(to: url, options: .atomic)
        return url
    }

    private static let dateFormat: Date.FormatStyle = .dateTime.month(.wide).day().year()

    private static func cover(_ audit: Audit, companyName: String, _ w: PDFWriter) {
        if let logo = Branding.loadLogo() {
            w.space(40)
            w.image(logo, maxHeight: 70)
            w.space(30)
        } else {
            w.space(120)
        }
        w.text(audit.kind.reportTitle, font: .systemFont(ofSize: 30, weight: .bold), color: w.accent)
        w.text(audit.displayName, font: .systemFont(ofSize: 20, weight: .medium), color: .darkGray, after: 24)
        var lines: [(String, String)] = [
            ("Date", audit.date.formatted(dateFormat)),
            ("Checklist", audit.checklistName),
        ]
        if !audit.location.isEmpty { lines.append(("Location", audit.location)) }
        if !audit.auditorName.isEmpty { lines.append(("Auditor", audit.auditorName)) }
        if !companyName.isEmpty { lines.append(("Prepared by", companyName)) }
        for (label, value) in lines {
            w.labeled(label, value)
        }
        if !audit.scopeNotes.isEmpty {
            w.space(16)
            w.heading("Scope")
            w.body(audit.scopeNotes)
        }
        w.space(24)
        w.subheading("About This Report")
        w.body(disclaimer, color: .gray)
    }

    static let disclaimer = "This report records the assessor's observations and the information provided on the date shown. It is not a certification, attestation, or legal opinion, and it does not guarantee compliance with any law, regulation, or standard. Readiness-level checklists summarize their source standards and do not replace a formal assessment against the full text."

    private static func summarySection(_ audit: Audit, narrative: String, _ w: PDFWriter) {
        w.newPage()
        w.title("Executive Summary")
        if !narrative.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            w.body(narrative)
            w.space(6)
        }
        if let score = audit.score {
            w.text("Overall score: \(Int((score * 100).rounded()))%", font: .systemFont(ofSize: 18, weight: .semibold))
        } else {
            w.text("Overall score: not enough results", font: .systemFont(ofSize: 18, weight: .semibold))
        }
        w.body("Pass counts fully, Partial counts half, and N/A or unanswered controls are left out.", color: .gray)
        w.space(8)

        w.heading("Control Results")
        w.labeled("Total controls", "\(audit.totalCount)")
        for status in [ControlStatus.pass, .partial, .fail, .notApplicable, .notStarted] {
            w.labeled(status.label, "\(audit.count(status))")
        }
        w.space(8)

        w.heading("Findings")
        let findings = audit.findings ?? []
        if findings.isEmpty {
            w.body("No findings recorded.")
        } else {
            for severity in Severity.allCases {
                w.labeled(severity.label, "\(findings.filter { $0.severity == severity }.count)")
            }
        }
        w.space(8)

        w.heading("Score by Area")
        let grouped = Dictionary(grouping: audit.sortedControls, by: \.groupName)
        var seen = Set<String>()
        for control in audit.sortedControls where !seen.contains(control.groupName) {
            seen.insert(control.groupName)
            let score = ComplianceScore.score(for: grouped[control.groupName] ?? [])
            w.labeled(control.groupName, score.map { "\(Int(($0 * 100).rounded()))%" } ?? "n/a")
        }
    }

    private static func findings(_ audit: Audit, _ w: PDFWriter) {
        let findings = audit.sortedFindings
        guard !findings.isEmpty else { return }
        w.newPage()
        w.title("Findings")
        for (index, finding) in findings.enumerated() {
            w.keepTogether(90)
            w.text("\(index + 1). \(finding.title)", font: .systemFont(ofSize: 15, weight: .semibold), after: 2)
            var meta = "Severity: \(finding.severity.label)"
            if let control = finding.control { meta += "   |   Control: \(control.controlID) \(control.title)" }
            w.text(meta, font: .systemFont(ofSize: 10, weight: .semibold), color: finding.severity.uiColor)
            if !finding.detail.isEmpty {
                w.subheading("Details")
                w.body(finding.detail)
            }
            if !finding.recommendation.isEmpty {
                w.subheading("Recommendation")
                w.body(finding.recommendation)
            }
            if let evidence = finding.control?.sortedEvidence, !evidence.isEmpty {
                w.subheading("Evidence")
                for item in evidence.prefix(4) {
                    if let image = UIImage(data: item.imageData) { w.image(image) }
                    if !item.caption.isEmpty { w.body(item.caption, color: .darkGray) }
                }
            }
            w.divider()
        }
    }

    private static func controls(_ audit: Audit, _ w: PDFWriter) {
        w.newPage()
        w.title("Control Results")
        var currentGroup = ""
        for control in audit.sortedControls {
            if control.groupName != currentGroup {
                currentGroup = control.groupName
                w.keepTogether(60)
                w.space(6)
                w.heading(currentGroup)
            }
            w.keepTogether(36)
            w.text("[\(control.status.label)]  \(control.controlID)  \(control.title)",
                   font: .systemFont(ofSize: 11, weight: .medium), color: statusColor(control.status), after: 2)
            if !control.notes.isEmpty {
                w.body(control.notes, color: .darkGray)
            }
            let onFile = (control.lockerItems ?? []).map(\.title).filter { !$0.isEmpty }
            if !onFile.isEmpty {
                w.text("Evidence on file: \(onFile.joined(separator: "; "))", font: .italicSystemFont(ofSize: 10), color: .darkGray, after: 4)
            }
            if control.notes.isEmpty && onFile.isEmpty {
                w.space(4)
            }
        }
    }

    /// Every locker document referenced by the audit, with type and expiration.
    private static func evidenceIndex(_ audit: Audit, _ w: PDFWriter) {
        var seen = Set<UUID>()
        var items: [LockerItem] = []
        for control in audit.sortedControls {
            for item in control.lockerItems ?? [] where !seen.contains(item.id) {
                seen.insert(item.id)
                items.append(item)
            }
        }
        guard !items.isEmpty else { return }
        w.newPage()
        w.title("Evidence Index")
        for item in items.sorted(by: { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }) {
            w.keepTogether(40)
            w.text(item.title.isEmpty ? item.fileName : item.title, font: .systemFont(ofSize: 12, weight: .semibold), after: 2)
            var meta = "\(item.kind.label)  |  \(item.fileName)"
            if let expiry = item.expiryText { meta += "  |  \(expiry)" }
            w.text(meta, font: .systemFont(ofSize: 10), color: item.isExpired ? .systemRed : .darkGray, after: 2)
            let ids = (item.controls ?? []).filter { $0.audit?.id == audit.id }.map(\.controlID)
            if !ids.isEmpty {
                w.text("Supports: \(ids.joined(separator: ", "))", font: .systemFont(ofSize: 10), color: .darkGray, after: 8)
            }
        }
    }

    private static func statusColor(_ status: ControlStatus) -> UIColor {
        switch status {
        case .pass: .systemGreen
        case .partial: .systemOrange
        case .fail: .systemRed
        case .notApplicable, .notStarted: .darkGray
        }
    }
}

/// A tiny top-to-bottom layout helper over UIGraphicsPDFRenderer.
final class PDFWriter {
    private let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
    private let margin: CGFloat = 54
    private let footer: String
    let accent: UIColor
    private var context: UIGraphicsPDFRendererContext?
    private var y: CGFloat = 0
    private var pageNumber = 0

    init(footer: String, accent: UIColor = .black) {
        self.footer = footer
        self.accent = accent
    }

    private var contentWidth: CGFloat { pageRect.width - margin * 2 }
    private var bottom: CGFloat { pageRect.height - margin }

    func render(_ draw: (PDFWriter) -> Void) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { ctx in
            context = ctx
            newPage()
            draw(self)
        }
    }

    func newPage() {
        context?.beginPage()
        pageNumber += 1
        y = margin
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 8), .foregroundColor: UIColor.gray]
        let text = NSAttributedString(string: "\(footer)  |  Page \(pageNumber)", attributes: attrs)
        text.draw(at: CGPoint(x: margin, y: pageRect.height - margin / 2 - 8))
    }

    /// Starts a new page if less than `height` points are left.
    func keepTogether(_ height: CGFloat) {
        if y + height > bottom { newPage() }
    }

    func space(_ height: CGFloat) { y += height }

    func title(_ string: String) { text(string, font: .systemFont(ofSize: 22, weight: .bold), color: accent, after: 14) }
    func heading(_ string: String) { text(string, font: .systemFont(ofSize: 14, weight: .semibold), after: 6) }
    func subheading(_ string: String) {
        text(string.uppercased(), font: .systemFont(ofSize: 9, weight: .semibold), color: .gray, after: 2)
    }

    func body(_ string: String, color: UIColor = .black) {
        // Draw paragraph by paragraph so long notes can flow across pages.
        for paragraph in string.components(separatedBy: .newlines) where !paragraph.isEmpty {
            text(paragraph, font: .systemFont(ofSize: 11), color: color, after: 4)
        }
        y += 4
    }

    func labeled(_ label: String, _ value: String) {
        let attributed = NSMutableAttributedString(
            string: "\(label): ",
            attributes: [.font: UIFont.systemFont(ofSize: 11, weight: .semibold), .foregroundColor: UIColor.darkGray])
        attributed.append(NSAttributedString(
            string: value, attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.black]))
        draw(attributed, after: 4)
    }

    func text(_ string: String, font: UIFont, color: UIColor = .black, after: CGFloat = 6) {
        draw(NSAttributedString(string: string, attributes: [.font: font, .foregroundColor: color]), after: after)
    }

    func image(_ image: UIImage, maxHeight: CGFloat = 240) {
        guard image.size.width > 0, image.size.height > 0 else { return }
        let scale = min(contentWidth * 0.6 / image.size.width, maxHeight / image.size.height, 1)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        keepTogether(size.height + 8)
        image.draw(in: CGRect(x: margin, y: y, width: size.width, height: size.height))
        y += size.height + 8
    }

    func divider() {
        keepTogether(20)
        y += 6
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
        UIColor.lightGray.setStroke()
        path.lineWidth = 0.5
        path.stroke()
        y += 14
    }

    private func draw(_ string: NSAttributedString, after: CGFloat) {
        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let height = ceil(string.boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                                              options: options, context: nil).height)
        keepTogether(height)
        string.draw(with: CGRect(x: margin, y: y, width: contentWidth, height: height), options: options, context: nil)
        y += height + after
    }
}
