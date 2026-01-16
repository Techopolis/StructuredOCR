import Foundation

/// A list detected in the document.
public struct List: Sendable, Hashable, Identifiable {
    public let id: UUID
    /// The items in the list
    public let items: [ListItem]
    /// The type of list
    public let type: ListType
    /// The bounding box encompassing all list items
    public let boundingBox: BoundingBox

    public init(
        id: UUID = UUID(),
        items: [ListItem],
        type: ListType,
        boundingBox: BoundingBox
    ) {
        self.id = id
        self.items = items
        self.type = type
        self.boundingBox = boundingBox
    }
}

/// A single item in a list.
public struct ListItem: Sendable, Hashable, Identifiable {
    public let id: UUID
    /// The text content of the list item
    public let text: String
    /// The bullet or number marker
    public let marker: String?
    /// The indentation level (0 = top level)
    public let level: Int
    /// The bounding box of this item
    public let boundingBox: BoundingBox
    /// The underlying text blocks
    public let textBlocks: [TextBlock]

    public init(
        id: UUID = UUID(),
        text: String,
        marker: String?,
        level: Int,
        boundingBox: BoundingBox,
        textBlocks: [TextBlock]
    ) {
        self.id = id
        self.text = text
        self.marker = marker
        self.level = level
        self.boundingBox = boundingBox
        self.textBlocks = textBlocks
    }
}

/// The type of list.
public enum ListType: String, Sendable, Hashable {
    /// Unordered list with bullets
    case unordered
    /// Ordered list with numbers
    case ordered
    /// List with checkboxes
    case checkbox
    /// Unknown list type
    case unknown
}
