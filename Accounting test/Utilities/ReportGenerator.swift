//
//  ReportGenerator.swift
//  Accounting test
//
//  Created by gary turnbull on 2/10/26.
//

import Foundation
import CoreGraphics
import CoreText

struct ReportRow {
    let label: String
    let values: [Decimal]
    let isBold: Bool

    init(label: String, values: [Decimal], isBold: Bool = false) {
        self.label = label
        self.values = values
        self.isBold = isBold
    }
}

struct ReportSection {
    let title: String
    let rows: [ReportRow]
}

struct ReportData {
    let title: String
    let subtitle: String
    let columnHeaders: [String]
    let sections: [ReportSection]
}

struct ReportGenerator {

    static func generateCSV(from report: ReportData) -> String {
        var lines: [String] = []
        lines.append(report.title)
        lines.append(report.subtitle)
        lines.append("")

        let headers = (["Account"] + report.columnHeaders)
            .map { escapeCSV($0) }
            .joined(separator: ",")
        lines.append(headers)

        for section in report.sections {
            lines.append("")
            lines.append(escapeCSV(section.title))

            for row in section.rows {
                let values = row.values.map { formatDecimal($0) }
                let line = ([escapeCSV(row.label)] + values.map { escapeCSV($0) })
                    .joined(separator: ",")
                lines.append(line)
            }
        }

        return lines.joined(separator: "\n")
    }

    static func generatePDF(from report: ReportData) -> Data {
        let pageWidth: CGFloat = 612  // US Letter
        let pageHeight: CGFloat = 792
        let marginLeft: CGFloat = 50
        let marginRight: CGFloat = 50
        let marginTop: CGFloat = 50
        let marginBottom: CGFloat = 50
        let usableWidth = pageWidth - marginLeft - marginRight

        let data = NSMutableData()

        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer,
                                     mediaBox: nil,
                                     nil) else {
            return Data()
        }

        var pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        var cursorY: CGFloat = 0

        func beginPage() {
            context.beginPage(mediaBox: &pageRect)
            cursorY = pageHeight - marginTop
        }

        func endPage() {
            context.endPage()
        }

        func checkPageBreak(needed: CGFloat) {
            if cursorY - needed < marginBottom {
                endPage()
                beginPage()
            }
        }

        func makeFont(size: CGFloat, bold: Bool) -> CTFont {
            let fontName = bold ? "Helvetica-Bold" as CFString : "Helvetica" as CFString
            return CTFontCreateWithName(fontName, size, nil)
        }

        func drawTextLeft(_ text: String, x: CGFloat, y: CGFloat, fontSize: CGFloat, bold: Bool = false) {
            let font = makeFont(size: fontSize, bold: bold)
            let attributes: [String: Any] = [
                kCTFontAttributeName as String: font
            ]
            let attrString = CFAttributedStringCreate(nil, text as CFString, attributes as CFDictionary)!
            let line = CTLineCreateWithAttributedString(attrString)
            context.saveGState()
            context.textPosition = CGPoint(x: x, y: y - fontSize)
            CTLineDraw(line, context)
            context.restoreGState()
        }

        func drawTextRight(_ text: String, rightEdge: CGFloat, y: CGFloat, fontSize: CGFloat, bold: Bool = false) {
            let font = makeFont(size: fontSize, bold: bold)
            let attributes: [String: Any] = [
                kCTFontAttributeName as String: font
            ]
            let attrString = CFAttributedStringCreate(nil, text as CFString, attributes as CFDictionary)!
            let line = CTLineCreateWithAttributedString(attrString)
            let textWidth = CTLineGetTypographicBounds(line, nil, nil, nil)
            context.saveGState()
            context.textPosition = CGPoint(x: rightEdge - CGFloat(textWidth), y: y - fontSize)
            CTLineDraw(line, context)
            context.restoreGState()
        }

        func drawLine(y: CGFloat) {
            context.setStrokeColor(CGColor(gray: 0.7, alpha: 1.0))
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: marginLeft, y: y))
            context.addLine(to: CGPoint(x: pageWidth - marginRight, y: y))
            context.strokePath()
        }

        let columnCount = report.columnHeaders.count
        let labelWidth = usableWidth * 0.5
        let valueColumnWidth = (usableWidth - labelWidth) / CGFloat(max(columnCount, 1))

        beginPage()

        // Title
        drawTextLeft(report.title, x: marginLeft, y: cursorY, fontSize: 18, bold: true)
        cursorY -= 24

        // Subtitle
        drawTextLeft(report.subtitle, x: marginLeft, y: cursorY, fontSize: 11)
        cursorY -= 20

        drawLine(y: cursorY)
        cursorY -= 16

        // Column headers
        drawTextLeft("Account", x: marginLeft, y: cursorY, fontSize: 9, bold: true)
        for (i, header) in report.columnHeaders.enumerated() {
            let colRightEdge = marginLeft + labelWidth + CGFloat(i + 1) * valueColumnWidth
            drawTextRight(header, rightEdge: colRightEdge - 4, y: cursorY, fontSize: 9, bold: true)
        }
        cursorY -= 16

        drawLine(y: cursorY)
        cursorY -= 8

        // Sections
        for section in report.sections {
            checkPageBreak(needed: 30)

            if !section.title.isEmpty {
                drawTextLeft(section.title, x: marginLeft, y: cursorY, fontSize: 11, bold: true)
                cursorY -= 18
            }

            for row in section.rows {
                checkPageBreak(needed: 18)

                let fontSize: CGFloat = 10
                let indent: CGFloat = row.isBold ? 0 : 10
                drawTextLeft(row.label, x: marginLeft + indent, y: cursorY, fontSize: fontSize, bold: row.isBold)

                for (i, value) in row.values.enumerated() {
                    let colRightEdge = marginLeft + labelWidth + CGFloat(i + 1) * valueColumnWidth
                    let formatted = formatDecimal(value)
                    drawTextRight(formatted, rightEdge: colRightEdge - 4, y: cursorY, fontSize: fontSize, bold: row.isBold)
                }
                cursorY -= 16

                if row.isBold {
                    drawLine(y: cursorY + 4)
                    cursorY -= 4
                }
            }

            cursorY -= 8
        }

        endPage()
        context.closePDF()

        return data as Data
    }

    private static func formatDecimal(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }

    private static func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
