import Foundation

/// A detected text column in the document.
public struct Column: Sendable, Hashable, Identifiable {
    public let id: UUID
    /// The bounding box of the column
    public let boundingBox: BoundingBox
    /// The text blocks within this column
    public let textBlocks: [TextBlock]
    /// Column index (0 = leftmost)
    public let index: Int

    public init(
        id: UUID = UUID(),
        boundingBox: BoundingBox,
        textBlocks: [TextBlock],
        index: Int
    ) {
        self.id = id
        self.boundingBox = boundingBox
        self.textBlocks = textBlocks
        self.index = index
    }

    /// The combined text of all blocks in this column
    public var text: String {
        textBlocks
            .sorted { $0.boundingBox.maxY > $1.boundingBox.maxY }
            .map(\.text)
            .joined(separator: "\n")
    }
}
