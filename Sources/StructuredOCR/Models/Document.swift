import Foundation
import CoreGraphics

/// A structured document containing all detected elements.
public struct StructuredDocument: Sendable, Hashable, Identifiable {
    public let id: UUID
    /// The size of the original image/document
    public let size: CGSize
    /// All raw text blocks detected
    public let textBlocks: [TextBlock]
    /// Detected headings
    public let headings: [Heading]
    /// Detected paragraphs
    public let paragraphs: [Paragraph]
    /// Detected tables
    public let tables: [Table]
    /// Detected links
    public let links: [Link]
    /// Detected lists
    public let lists: [List]
    /// Detected columns (if multi-column layout)
    public let columns: [Column]

    public init(
        id: UUID = UUID(),
        size: CGSize,
        textBlocks: [TextBlock],
        headings: [Heading] = [],
        paragraphs: [Paragraph] = [],
        tables: [Table] = [],
        links: [Link] = [],
        lists: [List] = [],
        columns: [Column] = []
    ) {
        self.id = id
        self.size = size
        self.textBlocks = textBlocks
        self.headings = headings
        self.paragraphs = paragraphs
        self.tables = tables
        self.links = links
        self.lists = lists
        self.columns = columns
    }

    /// Get all text in reading order (respecting columns)
    public var fullText: String {
        if isMultiColumn {
            // Multi-column: read each column top to bottom, then move to next column
            var allText: [String] = []
            for column in columns.sorted(by: { $0.boundingBox.minX < $1.boundingBox.minX }) {
                let columnBlocks = column.textBlocks.sorted { $0.boundingBox.maxY > $1.boundingBox.maxY }
                allText.append(columnBlocks.map(\.text).joined(separator: " "))
            }
            return allText.joined(separator: "\n\n")
        } else {
            // Single column: standard reading order
            return textBlocks
                .sorted { block1, block2 in
                    let avgHeight = (block1.boundingBox.height + block2.boundingBox.height) / 2
                    // If on approximately the same line, sort left to right
                    if abs(block1.boundingBox.maxY - block2.boundingBox.maxY) < avgHeight * 0.5 {
                        return block1.boundingBox.minX < block2.boundingBox.minX
                    }
                    // Otherwise sort top to bottom
                    return block1.boundingBox.maxY > block2.boundingBox.maxY
                }
                .map(\.text)
                .joined(separator: " ")
        }
    }

    /// Check if the document has a multi-column layout
    public var isMultiColumn: Bool {
        columns.count > 1
    }

    /// Check if the document contains any tables
    public var hasTables: Bool {
        !tables.isEmpty
    }

    /// Check if the document contains any lists
    public var hasLists: Bool {
        !lists.isEmpty
    }

    /// Get all elements in reading order as a heterogeneous collection (respects columns)
    public var elements: [DocumentElement] {
        var result: [DocumentElement] = []

        for heading in headings {
            result.append(.heading(heading))
        }
        for paragraph in paragraphs {
            result.append(.paragraph(paragraph))
        }
        for table in tables {
            result.append(.table(table))
        }
        for list in lists {
            result.append(.list(list))
        }

        if isMultiColumn {
            // Sort by column first, then by vertical position within column
            return result.sorted { e1, e2 in
                let col1 = columnIndex(for: e1.boundingBox)
                let col2 = columnIndex(for: e2.boundingBox)

                if col1 != col2 {
                    return col1 < col2
                }
                return e1.boundingBox.maxY > e2.boundingBox.maxY
            }
        } else {
            // Single column: sort by vertical position, then horizontal
            return result.sorted { e1, e2 in
                let avgHeight = (e1.boundingBox.height + e2.boundingBox.height) / 2
                if abs(e1.boundingBox.maxY - e2.boundingBox.maxY) < avgHeight * 0.5 {
                    return e1.boundingBox.minX < e2.boundingBox.minX
                }
                return e1.boundingBox.maxY > e2.boundingBox.maxY
            }
        }
    }

    /// Determine which column an element belongs to
    private func columnIndex(for box: BoundingBox) -> Int {
        let centerX = box.center.x
        for (index, column) in columns.enumerated() {
            if centerX >= column.boundingBox.minX && centerX <= column.boundingBox.maxX {
                return index
            }
        }
        // Default to finding closest column
        return columns.enumerated().min(by: { abs($0.element.boundingBox.center.x - centerX) < abs($1.element.boundingBox.center.x - centerX) })?.offset ?? 0
    }
}

/// A document element that can be one of several types.
public enum DocumentElement: Sendable, Hashable {
    case heading(Heading)
    case paragraph(Paragraph)
    case table(Table)
    case list(List)
    case textBlock(TextBlock)

    public var boundingBox: BoundingBox {
        switch self {
        case .heading(let h): return h.boundingBox
        case .paragraph(let p): return p.boundingBox
        case .table(let t): return t.boundingBox
        case .list(let l): return l.boundingBox
        case .textBlock(let b): return b.boundingBox
        }
    }

    public var text: String {
        switch self {
        case .heading(let h): return h.text
        case .paragraph(let p): return p.text
        case .table(let t): return t.textGrid.map { $0.joined(separator: "\t") }.joined(separator: "\n")
        case .list(let l): return l.items.map(\.text).joined(separator: "\n")
        case .textBlock(let b): return b.text
        }
    }
}
