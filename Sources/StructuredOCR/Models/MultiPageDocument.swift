import Foundation
import CoreGraphics

/// A multi-page document containing structured content from each page.
public struct MultiPageDocument: Sendable, Hashable, Identifiable {
    public let id: UUID
    /// Individual page results
    public let pages: [StructuredDocument]
    /// Total page count
    public var pageCount: Int { pages.count }

    public init(id: UUID = UUID(), pages: [StructuredDocument]) {
        self.id = id
        self.pages = pages
    }

    /// Get all headings across all pages.
    public var allHeadings: [Heading] {
        pages.flatMap(\.headings)
    }

    /// Get all tables across all pages.
    public var allTables: [Table] {
        pages.flatMap(\.tables)
    }

    /// Get all links across all pages.
    public var allLinks: [Link] {
        pages.flatMap(\.links)
    }

    /// Get all lists across all pages.
    public var allLists: [List] {
        pages.flatMap(\.lists)
    }

    /// Get combined full text from all pages.
    public var fullText: String {
        pages.map(\.fullText).joined(separator: "\n\n---\n\n")
    }

    /// Get a specific page (0-indexed).
    public func page(_ index: Int) -> StructuredDocument? {
        guard index >= 0, index < pages.count else { return nil }
        return pages[index]
    }
}

extension MultiPageDocument: Codable {
    enum CodingKeys: String, CodingKey {
        case id, pages
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            pages: try container.decode([StructuredDocument].self, forKey: .pages)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(pages, forKey: .pages)
    }
}
