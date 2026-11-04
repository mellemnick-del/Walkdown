import UIKit

/// Builds the audit report as a polished US Letter PDF: a branded cover with the score,
/// an executive summary with a score-by-area chart, findings with evidence photos, the
/// remediation plan, every control result, and an evidence index.
enum ReportBuilder {
    static let disclaimer = "This report records the assessor's observations and the information provided on the date shown. It is not a certification, attestation, or legal opinion, and it does not guarantee compliance with any law, regulation, or standard. Readiness-level checklists summarize their source standards and do not replace a formal assessment against the full text."

    static func makePDF(for audit: Audit, companyName: String, summary: String = "") throws -> URL {
        let data = makePDFData(for: audit, companyName: companyName, summary: summary)
        let safeName = audit.clientName.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }.joined(separator: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Reassured-\(safeName.isEmpty ? "Audit" : safeName).pdf")
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }

    static func makePDFData(for audit: Audit, companyName: String, summary: String = "") -> Data {
        let writer = PDFWriter(header: audit.displayName, accent: Branding.currentUIColor)
        return writer.render { w in
            cover(audit, companyName: companyName, w)
            summarySection(audit, narrative: summary, w)
            findings(audit, w)
            remediation(audit, w)
            controls(audit, w)
            evidenceIndex(audit, w)
        }
    }

    private static let longDate: Date.FormatStyle = .dateTime.month(.wide).day().year()
    private static let shortDate: Date.FormatStyle = .dateTime.month(.abbreviated).day().year()

    // MARK: Cover

    private static func cover(_ audit: Audit, companyName: String, _ w: PDFWriter) {
        w.newPage(chrome: false)
        let page = w.pageRect

        // Brand band across the top, in the organization's color.
        let band = CGRect(x: 0, y: 0, width: page.width, height: 250)
        w.gradient(band, from: w.accent, to: w.accent.mixed(with: .black, amount: 0.35))
        var textTop: CGFloat = 70
        if let logo = Branding.loadLogo() {
            let maxSize = CGSize(width: 150, height: 54)
            let scale = min(maxSize.width / logo.size.width, maxSize.height / logo.size.height, 1)
            let size = CGSize(width: logo.size.width * scale, height: logo.size.height * scale)
            let card = CGRect(x: w.margin, y: 36, width: size.width + 20, height: size.height + 16)
            w.fill(card, color: .white, radius: 10)
            logo.draw(in: CGRect(x: card.minX + 10, y: card.minY + 8, width: size.width, height: size.height))
            textTop = card.maxY + 22
        }
        w.text(audit.kind.reportTitle.uppercased(), at: CGPoint(x: w.margin, y: textTop),
               font: .systemFont(ofSize: 11, weight: .bold), color: UIColor.white.withAlphaComponent(0.8), kern: 1.4)
        w.text(audit.displayName, at: CGPoint(x: w.margin, y: textTop + 20), width: page.width - w.margin * 2,
               font: .serif(28, weight: .semibold), color: .white)
        w.text(audit.checklistName, at: CGPoint(x: w.margin, y: textTop + 62),
               font: .systemFont(ofSize: 13, weight: .medium), color: UIColor.white.withAlphaComponent(0.85))

        // Score ring and headline numbers.
        let top = band.maxY + 40
        let ringCenter = CGPoint(x: w.margin + 62, y: top + 62)
        w.ring(center: ringCenter, radius: 56, lineWidth: 12, progress: audit.score ?? 0,
               color: audit.score.map(Palette.score) ?? Palette.gray)
        w.text(audit.score.map { "\(Int(($0 * 100).rounded()))%" } ?? "n/a",
               centeredAt: CGPoint(x: ringCenter.x, y: ringCenter.y - 6), font: .serif(26, weight: .bold), color: Palette.ink)
        w.text("overall score", centeredAt: CGPoint(x: ringCenter.x, y: ringCenter.y + 18),
               font: .systemFont(ofSize: 9, weight: .medium), color: Palette.muted)

        let stats: [(String, String)] = [
            ("\(audit.answeredCount) of \(audit.totalCount)", "controls reviewed"),
            ("\((audit.findings ?? []).count)", "findings"),
            ("\(audit.openTasks.count)", "open remediation tasks"),
        ]
        var statY = top + 8
        for (value, label) in stats {
            w.text(value, at: CGPoint(x: w.margin + 160, y: statY), font: .serif(20, weight: .semibold), color: Palette.ink)
            w.text(label, at: CGPoint(x: w.margin + 160, y: statY + 25), font: .systemFont(ofSize: 10), color: Palette.muted)
            statY += 42
        }

        // Details.
        w.y = top + 160
        w.divider()
        var details: [(String, String)] = [("Date", audit.date.formatted(longDate)), ("Assessment", audit.kind.label)]
        if !audit.siteName.isEmpty { details.append(("Site", audit.siteName)) }
        if !audit.location.isEmpty { details.append(("Location", audit.location)) }
        if !audit.auditorName.isEmpty { details.append((audit.kind == .onSite ? "Auditor" : "Completed by", audit.auditorName)) }
        if !companyName.isEmpty { details.append(("Prepared by", companyName)) }
        for (label, value) in details { w.detailRow(label, value) }
        if !audit.scopeNotes.isEmpty {
            w.space(10)
            w.label("Scope")
            w.paragraph(audit.scopeNotes)
        }

        // Disclaimer at the bottom of the cover.
        let note = NSAttributedString(string: disclaimer, attributes: [
            .font: UIFont.systemFont(ofSize: 8), .foregroundColor: Palette.muted,
        ])
        let height = w.measure(note, width: w.contentWidth)
        note.draw(with: CGRect(x: w.margin, y: page.height - w.margin - height, width: w.contentWidth, height: height),
                  options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
    }

    // MARK: Executive summary

    private static func summarySection(_ audit: Audit, narrative: String, _ w: PDFWriter) {
        w.newPage()
        w.title("Executive Summary")
        if !narrative.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            w.paragraph(narrative, size: 11.5)
            w.space(8)
        }

        w.label("Results")
        var chips: [(String, UIColor)] = []
        for status in [ControlStatus.pass, .partial, .fail, .notApplicable, .notStarted] {
            let count = audit.count(status)
            if count > 0 { chips.append(("\(status.label) \(count)", Palette.status(status))) }
        }
        w.chips(chips)
        w.space(14)

        let areas = areaScores(audit)
        if !areas.isEmpty {
            w.label("Score by Area")
            for area in areas { w.bar(label: area.name, value: area.score) }
            w.space(12)
        }

        let findings = audit.findings ?? []
        w.label("Findings by Severity")
        if findings.isEmpty {
            w.paragraph("No findings recorded.", color: Palette.muted)
        } else {
            w.chips(Severity.allCases.compactMap { severity in
                let count = findings.filter { $0.severity == severity }.count
                return count > 0 ? ("\(severity.label) \(count)", Palette.severity(severity)) : nil
            })
        }
    }

    private static func areaScores(_ audit: Audit) -> [(name: String, score: Double)] {
        var names: [String] = []
        for control in audit.sortedControls where !names.contains(control.groupName) { names.append(control.groupName) }
        return names.compactMap { name in
            ComplianceScore.score(for: audit.sortedControls.filter { $0.groupName == name }).map { (name, $0) }
        }
    }

    // MARK: Findings

    private static func findings(_ audit: Audit, _ w: PDFWriter) {
        let findings = audit.sortedFindings
        guard !findings.isEmpty else { return }
        w.newPage()
        w.title("Findings")
        for (index, finding) in findings.enumerated() {
            w.keepTogether(110)
            let start = w.y
            let color = Palette.severity(finding.severity)
            w.indent(14) {
                w.pillLine(finding.severity.label.uppercased(), color: color,
                           trailing: finding.control.map { "\($0.controlID)  \($0.title)" })
                w.text("\(index + 1). \(finding.title)", font: .serif(15, weight: .semibold), color: Palette.ink, after: 6)
                if !finding.detail.isEmpty {
                    w.label("What we found")
                    w.paragraph(finding.detail)
                }
                if !finding.recommendation.isEmpty {
                    w.label("Recommendation")
                    w.paragraph(finding.recommendation)
                }
                if let evidence = finding.control?.sortedEvidence, !evidence.isEmpty {
                    w.label("Evidence")
                    w.photoGrid(evidence.prefix(4).compactMap { UIImage(data: $0.imageData) })
                }
            }
            // Severity bar down the left edge of the finding (on the page where it started).
            if w.y > start {
                w.fill(CGRect(x: w.margin, y: start, width: 4, height: w.y - start - 6), color: color, radius: 2)
            }
            w.space(16)
        }
    }

    // MARK: Remediation plan

    private static func remediation(_ audit: Audit, _ w: PDFWriter) {
        let tasks = audit.openTasks
        guard !tasks.isEmpty else { return }
        w.newPage()
        w.title("Remediation Plan")
        w.paragraph("Open tasks, most urgent first.", color: Palette.muted)
        w.space(4)
        let columns: [CGFloat] = [76, w.contentWidth - 76 - 100 - 80, 100, 80]
        w.tableHeader(["Priority", "Task", "Owner", "Due"], widths: columns)
        for (index, task) in tasks.enumerated() {
            w.tableRow(widths: columns, striped: index.isMultiple(of: 2), cells: [
                .pill(task.priority.label, Palette.severity(task.priority)),
                .text(task.title, bold: true, sub: task.control.map { $0.controlID }),
                .text(task.owner.isEmpty ? "Unassigned" : task.owner, bold: false, sub: nil),
                .text(task.dueDate.map { $0.formatted(shortDate) } ?? "No date", bold: false,
                      sub: task.isOverdue ? "Overdue" : nil),
            ])
        }
    }

    // MARK: Control results

    private static func controls(_ audit: Audit, _ w: PDFWriter) {
        w.newPage()
        w.title("Control Results")
        let columns: [CGFloat] = [78, w.contentWidth - 78 - 92, 92]
        var currentGroup = ""
        var row = 0
        for control in audit.sortedControls {
            if control.groupName != currentGroup {
                currentGroup = control.groupName
                w.keepTogether(70)
                w.space(8)
                let score = ComplianceScore.score(for: audit.sortedControls.filter { $0.groupName == currentGroup })
                w.pillLine(score.map { "\(Int(($0 * 100).rounded()))%" } ?? "Not scored",
                           color: score.map(Palette.score) ?? Palette.gray, leading: currentGroup)
                w.tableHeader(["Control", "Requirement", "Result"], widths: columns)
                row = 0
            }
            var notes = control.notes
            let onFile = (control.lockerItems ?? []).map(\.title).filter { !$0.isEmpty }
            if !onFile.isEmpty {
                notes += (notes.isEmpty ? "" : "\n") + "Evidence on file: " + onFile.joined(separator: "; ")
            }
            w.tableRow(widths: columns, striped: row.isMultiple(of: 2), cells: [
                .mono(control.controlID),
                .text(control.title, bold: true, sub: notes.isEmpty ? nil : notes),
                .pill(control.status.label, Palette.status(control.status)),
            ])
            row += 1
        }
    }

    // MARK: Evidence index

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
        let columns: [CGFloat] = [w.contentWidth - 90 - 110, 90, 110]
        w.tableHeader(["Document", "Type", "Expires"], widths: columns)
        let sorted = items.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        for (index, item) in sorted.enumerated() {
            let ids = (item.controls ?? []).filter { $0.audit?.id == audit.id }.map(\.controlID)
            let expiry: PDFWriter.Cell
            if let date = item.expiresAt {
                expiry = item.isExpired ? .pill("Expired", Palette.coral) : .text(date.formatted(shortDate), bold: false, sub: nil)
            } else {
                expiry = .text("No expiry", bold: false, sub: nil)
            }
            w.tableRow(widths: columns, striped: index.isMultiple(of: 2), cells: [
                .text(item.title.isEmpty ? item.fileName : item.title, bold: true,
                      sub: ids.isEmpty ? nil : "Supports " + ids.joined(separator: ", ")),
                .text(item.kind.label, bold: false, sub: nil),
                expiry,
            ])
        }
    }
}

// MARK: - Palette

/// Print-friendly versions of the app's calm colors.
enum Palette {
    static func hex(_ value: UInt32) -> UIColor {
        UIColor(red: CGFloat((value >> 16) & 0xFF) / 255, green: CGFloat((value >> 8) & 0xFF) / 255,
                blue: CGFloat(value & 0xFF) / 255, alpha: 1)
    }

    static let ink = hex(0x1B2433)
    static let muted = hex(0x6B7280)
    static let line = hex(0xE5E7EB)
    static let stripe = hex(0xF6F8FA)
    static let green = hex(0x2FA67A)
    static let amber = hex(0xD9922E)
    static let coral = hex(0xD9534F)
    static let plum = hex(0x8A5FBF)
    static let blue = hex(0x2F7FA6)
    static let gray = hex(0x9CA3AF)

    static func status(_ status: ControlStatus) -> UIColor {
        switch status {
        case .pass: green
        case .partial: amber
        case .fail: coral
        case .notApplicable, .notStarted: gray
        }
    }

    static func severity(_ severity: Severity) -> UIColor {
        switch severity {
        case .critical: plum
        case .high: coral
        case .medium: amber
        case .low: blue
        }
    }

    static func score(_ value: Double) -> UIColor {
        value >= 0.8 ? green : value >= 0.5 ? amber : coral
    }
}

extension UIFont {
    /// New York, Apple's serif, to match the app's headlines.
    static func serif(_ size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.serif) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}

extension UIColor {
    func mixed(with other: UIColor, amount: CGFloat) -> UIColor {
        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(red: r1 + (r2 - r1) * amount, green: g1 + (g2 - g1) * amount,
                       blue: b1 + (b2 - b1) * amount, alpha: a1 + (a2 - a1) * amount)
    }
}

// MARK: - Layout

/// A small top-to-bottom layout engine over UIGraphicsPDFRenderer.
final class PDFWriter {
    enum Cell {
        case text(String, bold: Bool, sub: String?)
        case mono(String)
        case pill(String, UIColor)
    }

    let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
    let margin: CGFloat = 48
    let accent: UIColor
    var y: CGFloat = 0

    private let header: String
    private var context: UIGraphicsPDFRendererContext?
    private var pageNumber = 0
    private var leftInset: CGFloat = 0
    private let drawOptions: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]

    init(header: String, accent: UIColor) {
        self.header = header
        self.accent = accent
    }

    var contentWidth: CGFloat { pageRect.width - margin * 2 - leftInset }
    private var left: CGFloat { margin + leftInset }
    private var bottom: CGFloat { pageRect.height - margin - 14 }

    func render(_ draw: (PDFWriter) -> Void) -> Data {
        UIGraphicsPDFRenderer(bounds: pageRect).pdfData { ctx in
            context = ctx
            draw(self)
        }
    }

    /// Starts a page. `chrome` adds the running header and page footer.
    func newPage(chrome: Bool = true) {
        context?.beginPage()
        pageNumber += 1
        y = margin
        guard chrome else { return }
        let small: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 8, weight: .semibold), .foregroundColor: Palette.muted]
        NSAttributedString(string: "REASSURED", attributes: small.merging([.kern: 1.2]) { $1 })
            .draw(at: CGPoint(x: margin, y: margin - 22))
        let title = NSAttributedString(string: header, attributes: small)
        title.draw(at: CGPoint(x: pageRect.width - margin - title.size().width, y: margin - 22))
        fill(CGRect(x: margin, y: margin - 8, width: pageRect.width - margin * 2, height: 0.6), color: Palette.line)
        let footer = NSAttributedString(string: "Confidential  |  Page \(pageNumber)", attributes: small)
        footer.draw(at: CGPoint(x: pageRect.width - margin - footer.size().width, y: pageRect.height - margin + 4))
        y = margin + 6
    }

    func keepTogether(_ height: CGFloat) {
        if y + height > bottom { newPage() }
    }

    func space(_ height: CGFloat) { y += height }

    func indent(_ amount: CGFloat, _ body: () -> Void) {
        leftInset += amount
        body()
        leftInset -= amount
    }

    // MARK: Text

    func measure(_ string: NSAttributedString, width: CGFloat) -> CGFloat {
        ceil(string.boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: drawOptions, context: nil).height)
    }

    func text(_ string: String, font: UIFont, color: UIColor, after: CGFloat = 6) {
        let attributed = NSAttributedString(string: string, attributes: [.font: font, .foregroundColor: color])
        let height = measure(attributed, width: contentWidth)
        keepTogether(height)
        attributed.draw(with: CGRect(x: left, y: y, width: contentWidth, height: height), options: drawOptions, context: nil)
        y += height + after
    }

    /// Text at a fixed position, without moving the cursor.
    func text(_ string: String, at point: CGPoint, width: CGFloat? = nil, font: UIFont, color: UIColor, kern: CGFloat = 0) {
        let attributed = NSAttributedString(string: string, attributes: [.font: font, .foregroundColor: color, .kern: kern])
        let w = width ?? attributed.size().width + 2
        attributed.draw(with: CGRect(x: point.x, y: point.y, width: w, height: measure(attributed, width: w)),
                        options: drawOptions, context: nil)
    }

    func text(_ string: String, centeredAt point: CGPoint, font: UIFont, color: UIColor) {
        let attributed = NSAttributedString(string: string, attributes: [.font: font, .foregroundColor: color])
        let size = attributed.size()
        attributed.draw(at: CGPoint(x: point.x - size.width / 2, y: point.y - size.height / 2))
    }

    func title(_ string: String) {
        text(string, font: .serif(24, weight: .semibold), color: Palette.ink, after: 4)
        fill(CGRect(x: left, y: y + 2, width: 44, height: 3), color: accent, radius: 1.5)
        y += 18
    }

    func label(_ string: String) {
        text(string.uppercased(), font: .systemFont(ofSize: 8.5, weight: .bold), color: Palette.muted, after: 4)
    }

    /// Body text, paragraph by paragraph so long notes flow across pages.
    func paragraph(_ string: String, size: CGFloat = 10.5, color: UIColor = Palette.ink) {
        for line in string.components(separatedBy: .newlines) where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            text(line, font: .systemFont(ofSize: size), color: color, after: 5)
        }
        y += 4
    }

    func detailRow(_ label: String, _ value: String) {
        keepTogether(20)
        let labelText = NSAttributedString(string: label, attributes: [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: Palette.muted])
        let valueText = NSAttributedString(string: value, attributes: [.font: UIFont.systemFont(ofSize: 10.5), .foregroundColor: Palette.ink])
        labelText.draw(at: CGPoint(x: left, y: y))
        let valueWidth = contentWidth - 120
        let height = max(14, measure(valueText, width: valueWidth))
        valueText.draw(with: CGRect(x: left + 120, y: y, width: valueWidth, height: height), options: drawOptions, context: nil)
        y += height + 7
    }

    func divider() {
        keepTogether(16)
        fill(CGRect(x: left, y: y, width: contentWidth, height: 0.6), color: Palette.line)
        y += 14
    }

    // MARK: Shapes

    func fill(_ rect: CGRect, color: UIColor, radius: CGFloat = 0) {
        color.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: radius).fill()
    }

    func gradient(_ rect: CGRect, from start: UIColor, to end: UIColor) {
        guard let cg = UIGraphicsGetCurrentContext(),
              let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: [start.cgColor, end.cgColor] as CFArray, locations: [0, 1]) else { return }
        cg.saveGState()
        cg.clip(to: rect)
        cg.drawLinearGradient(gradient, start: CGPoint(x: rect.minX, y: rect.minY), end: CGPoint(x: rect.maxX, y: rect.maxY), options: [])
        cg.restoreGState()
    }

    func ring(center: CGPoint, radius: CGFloat, lineWidth: CGFloat, progress: Double, color: UIColor) {
        let track = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        track.lineWidth = lineWidth
        Palette.line.setStroke()
        track.stroke()
        guard progress > 0 else { return }
        let start = -CGFloat.pi / 2
        let arc = UIBezierPath(arcCenter: center, radius: radius, startAngle: start,
                               endAngle: start + CGFloat(min(progress, 1)) * .pi * 2, clockwise: true)
        arc.lineWidth = lineWidth
        arc.lineCapStyle = .round
        color.setStroke()
        arc.stroke()
    }

    /// Draws a rounded pill and returns its width.
    @discardableResult
    func pill(_ string: String, color: UIColor, at point: CGPoint) -> CGFloat {
        let attributed = NSAttributedString(string: string, attributes: [.font: UIFont.systemFont(ofSize: 8.5, weight: .bold), .foregroundColor: color])
        let size = attributed.size()
        let rect = CGRect(x: point.x, y: point.y, width: size.width + 14, height: size.height + 6)
        fill(rect, color: color.withAlphaComponent(0.14), radius: rect.height / 2)
        attributed.draw(at: CGPoint(x: rect.minX + 7, y: rect.minY + 3))
        return rect.width
    }

    /// A pill with optional bold text before it, or muted text after it.
    func pillLine(_ string: String, color: UIColor, leading: String? = nil, trailing: String? = nil) {
        keepTogether(26)
        var x = left
        if let leading {
            let attributed = NSAttributedString(string: leading, attributes: [.font: UIFont.serif(14, weight: .semibold), .foregroundColor: Palette.ink])
            attributed.draw(at: CGPoint(x: x, y: y))
            x += attributed.size().width + 10
        }
        let width = pill(string, color: color, at: CGPoint(x: x, y: y + 2))
        if let trailing {
            let attributed = NSAttributedString(string: trailing, attributes: [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: Palette.muted])
            attributed.draw(with: CGRect(x: x + width + 8, y: y + 4, width: contentWidth - width - 8, height: 14),
                            options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil)
        }
        y += 24
    }

    func chips(_ items: [(String, UIColor)]) {
        keepTogether(24)
        var x = left
        for (string, color) in items {
            let estimated = NSAttributedString(string: string, attributes: [.font: UIFont.systemFont(ofSize: 8.5, weight: .bold)]).size().width + 14
            if x + estimated > left + contentWidth {
                x = left
                y += 24
                keepTogether(24)
            }
            x += pill(string, color: color, at: CGPoint(x: x, y: y)) + 8
        }
        y += 24
    }

    /// One labeled horizontal bar, used for the score-by-area chart.
    func bar(label: String, value: Double) {
        keepTogether(22)
        let labelWidth: CGFloat = 200
        let valueWidth: CGFloat = 40
        let barWidth = contentWidth - labelWidth - valueWidth - 10
        let name = NSAttributedString(string: label, attributes: [.font: UIFont.systemFont(ofSize: 9.5), .foregroundColor: Palette.ink])
        name.draw(with: CGRect(x: left, y: y, width: labelWidth - 8, height: 14),
                  options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil)
        let track = CGRect(x: left + labelWidth, y: y + 3, width: barWidth, height: 8)
        fill(track, color: Palette.stripe, radius: 4)
        fill(CGRect(x: track.minX, y: track.minY, width: max(8, barWidth * CGFloat(min(value, 1))), height: 8),
             color: Palette.score(value), radius: 4)
        let percent = NSAttributedString(string: "\(Int((value * 100).rounded()))%",
                                         attributes: [.font: UIFont.systemFont(ofSize: 9.5, weight: .semibold), .foregroundColor: Palette.ink])
        percent.draw(at: CGPoint(x: track.maxX + 10, y: y))
        y += 20
    }

    /// Photos two per row, each scaled to fit.
    func photoGrid(_ images: [UIImage]) {
        let gap: CGFloat = 10
        let cellWidth = (contentWidth - gap) / 2
        var index = 0
        while index < images.count {
            let row = Array(images[index..<min(index + 2, images.count)])
            let heights = row.map { min(cellWidth * $0.size.height / max($0.size.width, 1), 190) }
            let rowHeight = heights.max() ?? 0
            keepTogether(rowHeight + gap)
            for (column, image) in row.enumerated() {
                let height = heights[column]
                let width = min(cellWidth, height * image.size.width / max(image.size.height, 1))
                let rect = CGRect(x: left + CGFloat(column) * (cellWidth + gap), y: y, width: width, height: height)
                UIGraphicsGetCurrentContext()?.saveGState()
                UIBezierPath(roundedRect: rect, cornerRadius: 6).addClip()
                image.draw(in: rect)
                UIGraphicsGetCurrentContext()?.restoreGState()
            }
            y += rowHeight + gap
            index += 2
        }
    }

    // MARK: Tables

    func tableHeader(_ titles: [String], widths: [CGFloat]) {
        keepTogether(40)
        fill(CGRect(x: left, y: y, width: contentWidth, height: 20), color: accent.withAlphaComponent(0.1), radius: 4)
        var x = left + 8
        for (title, width) in zip(titles, widths) {
            NSAttributedString(string: title.uppercased(), attributes: [
                .font: UIFont.systemFont(ofSize: 8, weight: .bold), .foregroundColor: Palette.muted, .kern: 0.6,
            ]).draw(at: CGPoint(x: x, y: y + 5))
            x += width
        }
        y += 24
    }

    func tableRow(widths: [CGFloat], striped: Bool, cells: [Cell]) {
        let padding: CGFloat = 6
        // Measure every cell first so the row background fits the tallest one.
        var heights: [CGFloat] = []
        for (cell, width) in zip(cells, widths) {
            let inner = width - 16
            switch cell {
            case let .text(main, bold, sub):
                var height = measure(Self.cellText(main, bold: bold), width: inner)
                if let sub { height += 2 + measure(Self.cellSub(sub), width: inner) }
                heights.append(height)
            case .mono, .pill:
                heights.append(16)
            }
        }
        let rowHeight = (heights.max() ?? 16) + padding * 2
        keepTogether(rowHeight)
        if striped { fill(CGRect(x: left, y: y, width: contentWidth, height: rowHeight), color: Palette.stripe, radius: 3) }
        var x = left + 8
        for (cell, width) in zip(cells, widths) {
            let inner = width - 16
            switch cell {
            case let .text(main, bold, sub):
                let mainText = Self.cellText(main, bold: bold)
                let mainHeight = measure(mainText, width: inner)
                mainText.draw(with: CGRect(x: x, y: y + padding, width: inner, height: mainHeight), options: drawOptions, context: nil)
                if let sub {
                    let subText = Self.cellSub(sub)
                    subText.draw(with: CGRect(x: x, y: y + padding + mainHeight + 2, width: inner, height: measure(subText, width: inner)),
                                 options: drawOptions, context: nil)
                }
            case let .mono(string):
                NSAttributedString(string: string, attributes: [
                    .font: UIFont.monospacedSystemFont(ofSize: 8.5, weight: .regular), .foregroundColor: Palette.muted,
                ]).draw(at: CGPoint(x: x, y: y + padding + 1))
            case let .pill(string, color):
                pill(string, color: color, at: CGPoint(x: x, y: y + padding - 1))
            }
            x += width
        }
        y += rowHeight + 2
    }

    private static func cellText(_ string: String, bold: Bool) -> NSAttributedString {
        NSAttributedString(string: string, attributes: [
            .font: UIFont.systemFont(ofSize: 9.5, weight: bold ? .semibold : .regular), .foregroundColor: Palette.ink,
        ])
    }

    private static func cellSub(_ string: String) -> NSAttributedString {
        NSAttributedString(string: string, attributes: [.font: UIFont.systemFont(ofSize: 8.5), .foregroundColor: Palette.muted])
    }
}
