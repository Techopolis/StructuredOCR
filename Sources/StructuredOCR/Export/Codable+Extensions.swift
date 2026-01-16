import Foundation
import CoreGraphics

// MARK: - Codable Conformance

extension BoundingBox: Codable {
    enum CodingKeys: String, CodingKey {
        case x, y, width, height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            x: try container.decode(CGFloat.self, forKey: .x),
            y: try container.decode(CGFloat.self, forKey: .y),
            width: try container.decode(CGFloat.self, forKey: .width),
            height: try container.decode(CGFloat.self, forKey: .height)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }
}

extension TextBlock: Codable {
    enum CodingKeys: String, CodingKey {
        case id, text, boundingBox, confidence
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            text: try container.decode(String.self, forKey: .text),
            boundingBox: try container.decode(BoundingBox.self, forKey: .boundingBox),
            confidence: try container.decode(Float.self, forKey: .confidence)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(boundingBox, forKey: .boundingBox)
        try container.encode(confidence, forKey: .confidence)
    }
}

extension Heading: Codable {
    enum CodingKeys: String, CodingKey {
        case id, text, boundingBox, level, textBlocks
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            text: try container.decode(String.self, forKey: .text),
            boundingBox: try container.decode(BoundingBox.self, forKey: .boundingBox),
            level: try container.decode(Int.self, forKey: .level),
            textBlocks: try container.decode([TextBlock].self, forKey: .textBlocks)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(boundingBox, forKey: .boundingBox)
        try container.encode(level, forKey: .level)
        try container.encode(textBlocks, forKey: .textBlocks)
    }
}

extension Paragraph: Codable {
    enum CodingKeys: String, CodingKey {
        case id, text, boundingBox, textBlocks
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            text: try container.decode(String.self, forKey: .text),
            boundingBox: try container.decode(BoundingBox.self, forKey: .boundingBox),
            textBlocks: try container.decode([TextBlock].self, forKey: .textBlocks)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(boundingBox, forKey: .boundingBox)
        try container.encode(textBlocks, forKey: .textBlocks)
    }
}

extension Link: Codable {
    enum CodingKeys: String, CodingKey {
        case id, text, url, type, boundingBox, textBlock
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            text: try container.decode(String.self, forKey: .text),
            url: try container.decode(String.self, forKey: .url),
            type: try container.decode(LinkType.self, forKey: .type),
            boundingBox: try container.decode(BoundingBox.self, forKey: .boundingBox),
            textBlock: try container.decode(TextBlock.self, forKey: .textBlock)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(url, forKey: .url)
        try container.encode(type, forKey: .type)
        try container.encode(boundingBox, forKey: .boundingBox)
        try container.encode(textBlock, forKey: .textBlock)
    }
}

extension LinkType: Codable {}

extension Table: Codable {
    enum CodingKeys: String, CodingKey {
        case id, boundingBox, rows, columnCount
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            boundingBox: try container.decode(BoundingBox.self, forKey: .boundingBox),
            rows: try container.decode([TableRow].self, forKey: .rows),
            columnCount: try container.decode(Int.self, forKey: .columnCount)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(boundingBox, forKey: .boundingBox)
        try container.encode(rows, forKey: .rows)
        try container.encode(columnCount, forKey: .columnCount)
    }
}

extension TableRow: Codable {
    enum CodingKeys: String, CodingKey {
        case id, cells, boundingBox, isHeader
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            cells: try container.decode([TableCell].self, forKey: .cells),
            boundingBox: try container.decode(BoundingBox.self, forKey: .boundingBox),
            isHeader: try container.decode(Bool.self, forKey: .isHeader)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(cells, forKey: .cells)
        try container.encode(boundingBox, forKey: .boundingBox)
        try container.encode(isHeader, forKey: .isHeader)
    }
}

extension TableCell: Codable {
    enum CodingKeys: String, CodingKey {
        case id, text, boundingBox, textBlocks, column, row
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            text: try container.decode(String.self, forKey: .text),
            boundingBox: try container.decode(BoundingBox.self, forKey: .boundingBox),
            textBlocks: try container.decode([TextBlock].self, forKey: .textBlocks),
            column: try container.decode(Int.self, forKey: .column),
            row: try container.decode(Int.self, forKey: .row)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(boundingBox, forKey: .boundingBox)
        try container.encode(textBlocks, forKey: .textBlocks)
        try container.encode(column, forKey: .column)
        try container.encode(row, forKey: .row)
    }
}

extension List: Codable {
    enum CodingKeys: String, CodingKey {
        case id, items, type, boundingBox
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            items: try container.decode([ListItem].self, forKey: .items),
            type: try container.decode(ListType.self, forKey: .type),
            boundingBox: try container.decode(BoundingBox.self, forKey: .boundingBox)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(items, forKey: .items)
        try container.encode(type, forKey: .type)
        try container.encode(boundingBox, forKey: .boundingBox)
    }
}

extension ListItem: Codable {
    enum CodingKeys: String, CodingKey {
        case id, text, marker, level, boundingBox, textBlocks
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            text: try container.decode(String.self, forKey: .text),
            marker: try container.decodeIfPresent(String.self, forKey: .marker),
            level: try container.decode(Int.self, forKey: .level),
            boundingBox: try container.decode(BoundingBox.self, forKey: .boundingBox),
            textBlocks: try container.decode([TextBlock].self, forKey: .textBlocks)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(marker, forKey: .marker)
        try container.encode(level, forKey: .level)
        try container.encode(boundingBox, forKey: .boundingBox)
        try container.encode(textBlocks, forKey: .textBlocks)
    }
}

extension ListType: Codable {}

extension Column: Codable {
    enum CodingKeys: String, CodingKey {
        case id, boundingBox, textBlocks, index
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            boundingBox: try container.decode(BoundingBox.self, forKey: .boundingBox),
            textBlocks: try container.decode([TextBlock].self, forKey: .textBlocks),
            index: try container.decode(Int.self, forKey: .index)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(boundingBox, forKey: .boundingBox)
        try container.encode(textBlocks, forKey: .textBlocks)
        try container.encode(index, forKey: .index)
    }
}

extension StructuredDocument: Codable {
    enum CodingKeys: String, CodingKey {
        case id, size, textBlocks, headings, paragraphs, tables, links, lists, columns
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let sizeArray = try container.decode([CGFloat].self, forKey: .size)
        let size = CGSize(width: sizeArray[0], height: sizeArray[1])

        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            size: size,
            textBlocks: try container.decode([TextBlock].self, forKey: .textBlocks),
            headings: try container.decode([Heading].self, forKey: .headings),
            paragraphs: try container.decode([Paragraph].self, forKey: .paragraphs),
            tables: try container.decode([Table].self, forKey: .tables),
            links: try container.decode([Link].self, forKey: .links),
            lists: try container.decode([List].self, forKey: .lists),
            columns: try container.decode([Column].self, forKey: .columns)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode([size.width, size.height], forKey: .size)
        try container.encode(textBlocks, forKey: .textBlocks)
        try container.encode(headings, forKey: .headings)
        try container.encode(paragraphs, forKey: .paragraphs)
        try container.encode(tables, forKey: .tables)
        try container.encode(links, forKey: .links)
        try container.encode(lists, forKey: .lists)
        try container.encode(columns, forKey: .columns)
    }
}

extension DocumentElement: Codable {
    enum CodingKeys: String, CodingKey {
        case type, heading, paragraph, table, list, textBlock
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "heading":
            self = .heading(try container.decode(Heading.self, forKey: .heading))
        case "paragraph":
            self = .paragraph(try container.decode(Paragraph.self, forKey: .paragraph))
        case "table":
            self = .table(try container.decode(Table.self, forKey: .table))
        case "list":
            self = .list(try container.decode(List.self, forKey: .list))
        case "textBlock":
            self = .textBlock(try container.decode(TextBlock.self, forKey: .textBlock))
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown type: \(type)")
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .heading(let h):
            try container.encode("heading", forKey: .type)
            try container.encode(h, forKey: .heading)
        case .paragraph(let p):
            try container.encode("paragraph", forKey: .type)
            try container.encode(p, forKey: .paragraph)
        case .table(let t):
            try container.encode("table", forKey: .type)
            try container.encode(t, forKey: .table)
        case .list(let l):
            try container.encode("list", forKey: .type)
            try container.encode(l, forKey: .list)
        case .textBlock(let b):
            try container.encode("textBlock", forKey: .type)
            try container.encode(b, forKey: .textBlock)
        }
    }
}
