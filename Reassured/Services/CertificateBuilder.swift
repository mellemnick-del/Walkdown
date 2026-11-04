import UIKit

/// A printable Certificate of Completion for a finished audit (US Letter, landscape).
/// It recognizes that an assessment was completed. It never claims the organization is compliant.
enum CertificateBuilder {
    struct Options {
        var includeScore = true
        var signerName = ""
        var signerTitle = ""
    }

    static let disclaimer = "This certificate recognizes the completion of an assessment on the date shown. It is not a certification of compliance with any law, regulation, or standard."

    /// A short, readable ID derived from the audit, for referencing the certificate.
    static func certificateID(for audit: Audit) -> String {
        "RA-" + audit.id.uuidString.replacingOccurrences(of: "-", with: "").prefix(8).uppercased()
    }

    static func makePDF(for audit: Audit, companyName: String, options: Options) throws -> URL {
        let data = makePDFData(for: audit, companyName: companyName, options: options)
        let safe = audit.clientName.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }.joined(separator: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Certificate-\(safe.isEmpty ? "Audit" : safe).pdf")
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }

    static func makePDFData(for audit: Audit, companyName: String, options: Options) -> Data {
        let page = CGRect(x: 0, y: 0, width: 792, height: 612)
        let accent = Branding.currentUIColor
        let navy = Palette.hex(0x0F2C5C)
        let gold = Palette.hex(0xC9A34B)
        let goldLight = Palette.hex(0xFFE7A8)
        let cream = Palette.hex(0xFDFAF3)

        return UIGraphicsPDFRenderer(bounds: page).pdfData { ctx in
            ctx.beginPage()

            // Paper and a double border.
            cream.setFill()
            UIRectFill(page)
            stroke(page.insetBy(dx: 22, dy: 22), color: navy, width: 2.5, radius: 6)
            stroke(page.insetBy(dx: 32, dy: 32), color: gold, width: 1, radius: 4)
            cornerFlourishes(in: page.insetBy(dx: 32, dy: 32), color: gold)

            // Logo at the top, or the Reassured mark.
            let center = page.midX
            if let logo = Branding.loadLogo() {
                let maxSize = CGSize(width: 160, height: 56)
                let scale = min(maxSize.width / logo.size.width, maxSize.height / logo.size.height, 1)
                let size = CGSize(width: logo.size.width * scale, height: logo.size.height * scale)
                logo.draw(in: CGRect(x: center - size.width / 2, y: 58, width: size.width, height: size.height))
            } else {
                drawMark(center: CGPoint(x: center, y: 84), width: 58, sun: goldLight, cradle: navy)
            }

            var y: CGFloat = 132
            y = centered("CERTIFICATE OF COMPLETION", y: y, font: .systemFont(ofSize: 13, weight: .bold), color: gold, kern: 4) + 18
            y = centered("This recognizes that", y: y, font: .serif(14, weight: .regular), color: Palette.muted) + 8
            y = centered(audit.displayName, y: y, font: .serif(38, weight: .semibold), color: navy, width: 620) + 6

            // A short accent rule under the name.
            accent.setFill()
            UIBezierPath(roundedRect: CGRect(x: center - 60, y: y + 4, width: 120, height: 2.5), cornerRadius: 1.25).fill()
            y += 22

            let kind = audit.kind == .onSite ? "an on-site audit" : "a self-assessment"
            y = centered("has completed \(kind) against", y: y, font: .serif(15, weight: .regular), color: Palette.ink) + 4
            y = centered(audit.checklistName, y: y, font: .serif(20, weight: .semibold), color: navy, width: 620) + 6
            var line = "on \(audit.date.formatted(.dateTime.month(.wide).day().year()))"
            if options.includeScore, let score = audit.score {
                line += ", with an overall score of \(Int((score * 100).rounded()))%"
            }
            _ = centered(line + ".", y: y, font: .serif(15, weight: .regular), color: Palette.ink)

            // Signature lines and the seal.
            let baseline: CGFloat = 486
            signature(x: 96, width: 220, baseline: baseline,
                      name: options.signerName.isEmpty ? audit.auditorName : options.signerName,
                      caption: [options.signerTitle, companyName].filter { !$0.isEmpty }.joined(separator: ", ").ifEmpty("Assessor"),
                      ink: navy)
            signature(x: page.width - 96 - 220, width: 220, baseline: baseline,
                      name: Date.now.formatted(.dateTime.month(.wide).day().year()),
                      caption: "Date issued", ink: navy)
            seal(center: CGPoint(x: center, y: baseline - 20), radius: 50, gold: gold, goldLight: goldLight, navy: navy)

            // Footer: certificate ID and the plain-language disclaimer.
            let footerY: CGFloat = page.height - 62
            _ = centered("Certificate ID \(certificateID(for: audit))  |  Prepared with Reassured", y: footerY,
                         font: .monospacedSystemFont(ofSize: 7.5, weight: .medium), color: Palette.muted)
            _ = centered(disclaimer, y: footerY + 12, font: .systemFont(ofSize: 7.5), color: Palette.muted, width: 600)
        }
    }

    // MARK: Drawing helpers

    @discardableResult
    private static func centered(_ string: String, y: CGFloat, font: UIFont, color: UIColor,
                                 width: CGFloat = 700, kern: CGFloat = 0) -> CGFloat {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let text = NSAttributedString(string: string, attributes: [
            .font: font, .foregroundColor: color, .kern: kern, .paragraphStyle: style,
        ])
        let height = ceil(text.boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                                            options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height)
        text.draw(with: CGRect(x: (792 - width) / 2, y: y, width: width, height: height),
                  options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return y + height
    }

    private static func stroke(_ rect: CGRect, color: UIColor, width: CGFloat, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        path.lineWidth = width
        color.setStroke()
        path.stroke()
    }

    /// Small diamond accents at each corner of the inner border.
    private static func cornerFlourishes(in rect: CGRect, color: UIColor) {
        color.setFill()
        for corner in [CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY),
                       CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.maxX, y: rect.maxY)] {
            let diamond = UIBezierPath()
            diamond.move(to: CGPoint(x: corner.x, y: corner.y - 6))
            diamond.addLine(to: CGPoint(x: corner.x + 6, y: corner.y))
            diamond.addLine(to: CGPoint(x: corner.x, y: corner.y + 6))
            diamond.addLine(to: CGPoint(x: corner.x - 6, y: corner.y))
            diamond.close()
            diamond.fill()
        }
    }

    /// The Reassured mark: a sun held by a cradle, scaled to `width`.
    private static func drawMark(center: CGPoint, width: CGFloat, sun: UIColor, cradle: UIColor) {
        let unit = width / 644
        let origin = CGPoint(x: center.x - width / 2, y: center.y - 580 * unit / 2)
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + (x - 190) * unit, y: origin.y + (y - 290) * unit)
        }
        sun.setFill()
        let sunCenter = point(512, 500)
        UIBezierPath(arcCenter: sunCenter, radius: 170 * unit, startAngle: 0, endAngle: .pi * 2, clockwise: true).fill()
        let path = UIBezierPath()
        path.move(to: point(230, 470))
        path.addCurve(to: point(512, 830), controlPoint1: point(230, 730), controlPoint2: point(380, 830))
        path.addCurve(to: point(794, 470), controlPoint1: point(644, 830), controlPoint2: point(794, 730))
        path.lineWidth = 76 * unit
        path.lineCapStyle = .round
        cradle.setStroke()
        path.stroke()
    }

    private static func signature(x: CGFloat, width: CGFloat, baseline: CGFloat, name: String, caption: String, ink: UIColor) {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let nameText = NSAttributedString(string: name, attributes: [
            .font: UIFont.serif(14, weight: .semibold), .foregroundColor: ink, .paragraphStyle: style,
        ])
        nameText.draw(with: CGRect(x: x, y: baseline - 22, width: width, height: 20),
                      options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil)
        ink.withAlphaComponent(0.6).setFill()
        UIRectFill(CGRect(x: x, y: baseline, width: width, height: 0.8))
        NSAttributedString(string: caption, attributes: [
            .font: UIFont.systemFont(ofSize: 9), .foregroundColor: Palette.muted, .paragraphStyle: style,
        ]).draw(with: CGRect(x: x, y: baseline + 6, width: width, height: 14),
                options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil)
    }

    /// A gold seal with the mark and "ASSESSMENT COMPLETE" around it.
    private static func seal(center: CGPoint, radius: CGFloat, gold: UIColor, goldLight: UIColor, navy: UIColor) {
        // Scalloped edge.
        let edge = UIBezierPath()
        let points = 36
        for index in 0...(points * 2) {
            let angle = CGFloat(index) / CGFloat(points * 2) * .pi * 2
            let r = index.isMultiple(of: 2) ? radius : radius * 0.93
            let point = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
            index == 0 ? edge.move(to: point) : edge.addLine(to: point)
        }
        edge.close()
        gold.setFill()
        edge.fill()
        navy.setFill()
        UIBezierPath(arcCenter: center, radius: radius * 0.8, startAngle: 0, endAngle: .pi * 2, clockwise: true).fill()
        gold.setStroke()
        let ring = UIBezierPath(arcCenter: center, radius: radius * 0.72, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        ring.lineWidth = 0.8
        ring.stroke()
        drawMark(center: CGPoint(x: center.x, y: center.y - 2), width: radius * 0.62, sun: goldLight, cradle: .white)

        // Text around the top of the seal.
        let label = Array("ASSESSMENT COMPLETE")
        let font = UIFont.systemFont(ofSize: 6.6, weight: .bold)
        let arcRadius = radius * 0.6
        let spread: CGFloat = .pi * 0.95
        for (index, character) in label.enumerated() {
            let angle = -CGFloat.pi / 2 - spread / 2 + spread * CGFloat(index) / CGFloat(label.count - 1)
            let point = CGPoint(x: center.x + cos(angle) * arcRadius, y: center.y + sin(angle) * arcRadius)
            guard let cg = UIGraphicsGetCurrentContext() else { continue }
            cg.saveGState()
            cg.translateBy(x: point.x, y: point.y)
            cg.rotate(by: angle + .pi / 2)
            let glyph = NSAttributedString(string: String(character), attributes: [.font: font, .foregroundColor: goldLight])
            let size = glyph.size()
            glyph.draw(at: CGPoint(x: -size.width / 2, y: -size.height / 2))
            cg.restoreGState()
        }
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String { isEmpty ? fallback : self }
}
