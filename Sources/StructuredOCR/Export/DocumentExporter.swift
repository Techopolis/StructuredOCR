import Foundation

/// Exports structured documents to various formats.
public struct DocumentExporter: Sendable {

    public init() {}

    // MARK: - JSON

    /// Export document to JSON string.
    public func exportJSON(_ document: StructuredDocument, prettyPrinted: Bool = true) throws -> String {
        let encoder = JSONEncoder()
        if prettyPrinted {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        let data = try encoder.encode(document)
        guard let string = String(data: data, encoding: .utf8) else {
            throw ExportError.encodingFailed
        }
        return string
    }

    /// Export document to JSON data.
    public func exportJSONData(_ document: StructuredDocument) throws -> Data {
        try JSONEncoder().encode(document)
    }

    // MARK: - Markdown

    /// Export document to Markdown format.
    public func exportMarkdown(_ document: StructuredDocument) -> String {
        var lines: [String] = []

        for element in document.elements {
            switch element {
            case .heading(let heading):
                let prefix = String(repeating: "#", count: heading.level)
                lines.append("\(prefix) \(heading.text)")
                lines.append("")

            case .paragraph(let paragraph):
                lines.append(paragraph.text)
                lines.append("")

            case .table(let table):
                lines.append(exportTableMarkdown(table))
                lines.append("")

            case .list(let list):
                lines.append(exportListMarkdown(list))
                lines.append("")

            case .textBlock(let block):
                lines.append(block.text)
            }
        }

        // Add links as references at the end
        if !document.links.isEmpty {
            lines.append("---")
            lines.append("")
            lines.append("**Links:**")
            for link in document.links {
                lines.append("- [\(link.text)](\(link.url))")
            }
        }

        return lines.joined(separator: "\n")
    }

    private func exportTableMarkdown(_ table: Table) -> String {
        guard !table.rows.isEmpty else { return "" }

        var lines: [String] = []

        for (index, row) in table.rows.enumerated() {
            let cells = row.cells.map { $0.text.replacingOccurrences(of: "|", with: "\\|") }
            lines.append("| " + cells.joined(separator: " | ") + " |")

            // Add header separator after first row
            if index == 0 {
                let separator = row.cells.map { _ in "---" }
                lines.append("| " + separator.joined(separator: " | ") + " |")
            }
        }

        return lines.joined(separator: "\n")
    }

    private func exportListMarkdown(_ list: List) -> String {
        var lines: [String] = []

        for (index, item) in list.items.enumerated() {
            let indent = String(repeating: "  ", count: item.level)
            let marker: String

            switch list.type {
            case .ordered:
                marker = "\(index + 1)."
            case .unordered:
                marker = "-"
            case .checkbox:
                marker = "- [ ]"
            case .unknown:
                marker = "-"
            }

            lines.append("\(indent)\(marker) \(item.text)")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - HTML

    /// Export document to HTML format.
    public func exportHTML(_ document: StructuredDocument, includeStyles: Bool = true) -> String {
        var html = ""

        if includeStyles {
            html += """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <style>
                    body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
                    table { border-collapse: collapse; width: 100%; margin: 1em 0; }
                    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
                    th { background-color: #f5f5f5; }
                    ul, ol { margin: 1em 0; }
                    a { color: #007aff; }
                </style>
            </head>
            <body>

            """
        }

        for element in document.elements {
            switch element {
            case .heading(let heading):
                html += "<h\(heading.level)>\(escapeHTML(heading.text))</h\(heading.level)>\n"

            case .paragraph(let paragraph):
                html += "<p>\(escapeHTML(paragraph.text))</p>\n"

            case .table(let table):
                html += exportTableHTML(table)

            case .list(let list):
                html += exportListHTML(list)

            case .textBlock(let block):
                html += "<p>\(escapeHTML(block.text))</p>\n"
            }
        }

        if includeStyles {
            html += """

            </body>
            </html>
            """
        }

        return html
    }

    private func exportTableHTML(_ table: Table) -> String {
        var html = "<table>\n"

        for row in table.rows {
            html += "  <tr>\n"
            let tag = row.isHeader ? "th" : "td"
            for cell in row.cells {
                html += "    <\(tag)>\(escapeHTML(cell.text))</\(tag)>\n"
            }
            html += "  </tr>\n"
        }

        html += "</table>\n"
        return html
    }

    private func exportListHTML(_ list: List) -> String {
        let tag = list.type == .ordered ? "ol" : "ul"
        var html = "<\(tag)>\n"

        for item in list.items {
            html += "  <li>\(escapeHTML(item.text))</li>\n"
        }

        html += "</\(tag)>\n"
        return html
    }

    private func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    // MARK: - Plain Text

    /// Export document to plain text.
    public func exportPlainText(_ document: StructuredDocument) -> String {
        var lines: [String] = []

        for element in document.elements {
            switch element {
            case .heading(let heading):
                lines.append(heading.text.uppercased())
                lines.append(String(repeating: "=", count: heading.text.count))
                lines.append("")

            case .paragraph(let paragraph):
                lines.append(paragraph.text)
                lines.append("")

            case .table(let table):
                for row in table.rows {
                    let cells = row.cells.map { $0.text }
                    lines.append(cells.joined(separator: "\t"))
                }
                lines.append("")

            case .list(let list):
                for item in list.items {
                    lines.append("  • \(item.text)")
                }
                lines.append("")

            case .textBlock(let block):
                lines.append(block.text)
            }
        }

        return lines.joined(separator: "\n")
    }
}

public enum ExportError: Error, Sendable {
    case encodingFailed
}
