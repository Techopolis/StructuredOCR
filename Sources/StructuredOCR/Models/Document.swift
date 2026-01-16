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

    /// Get all text in reading order
    public var fullText: String {
        textBlocks
            .sorted { block1, block2 in
                // Sort top to bottom, then left to right
                if abs(block1.boundingBox.maxY - block2.boundingBox.maxY) > 0.01 {
                    return block1.boundingBox.maxY > block2.boundingBox.maxY
                }
                return block1.boundingBox.minX < block2.boundingBox.minX
            }
            .map(\.text)
            .joined(separator: " ")
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

    /// Get all elements in reading order as a heterogeneous collection
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

        return result.sorted { e1, e2 in
            e1.boundingBox.maxY > e2.boundingBox.maxY
        }
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
