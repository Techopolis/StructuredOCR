import Foundation

/// A detected heading in the document.
public struct Heading: Sendable, Hashable, Identifiable {
    public let id: UUID
    /// The heading text
    public let text: String
    /// The bounding box of the heading
    public let boundingBox: BoundingBox
    /// The heading level (1 = largest/most important)
    public let level: Int
    /// The underlying text blocks that make up this heading
    public let textBlocks: [TextBlock]

    public init(
        id: UUID = UUID(),
        text: String,
        boundingBox: BoundingBox,
        level: Int,
        textBlocks: [TextBlock]
    ) {
        self.id = id
        self.text = text
        self.boundingBox = boundingBox
        self.level = level
        self.textBlocks = textBlocks
    }
}

/// Heading level based on relative size
public enum HeadingLevel: Int, Sendable {
    case h1 = 1
    case h2 = 2
    case h3 = 3
    case h4 = 4
    case h5 = 5
    case h6 = 6
}
