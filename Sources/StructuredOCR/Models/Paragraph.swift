import Foundation

/// A paragraph of text composed of multiple text blocks.
public struct Paragraph: Sendable, Hashable, Identifiable {
    public let id: UUID
    /// The combined text of the paragraph
    public let text: String
    /// The bounding box encompassing all text blocks
    public let boundingBox: BoundingBox
    /// The text blocks that make up this paragraph
    public let textBlocks: [TextBlock]

    public init(
        id: UUID = UUID(),
        text: String,
        boundingBox: BoundingBox,
        textBlocks: [TextBlock]
    ) {
        self.id = id
        self.text = text
        self.boundingBox = boundingBox
        self.textBlocks = textBlocks
    }

    /// Create a paragraph from a collection of text blocks
    public init(id: UUID = UUID(), textBlocks: [TextBlock]) {
        self.id = id
        self.textBlocks = textBlocks
        self.text = textBlocks.map(\.text).joined(separator: " ")

        if let first = textBlocks.first {
            var combined = first.boundingBox
            for block in textBlocks.dropFirst() {
                combined = combined.union(block.boundingBox)
            }
            self.boundingBox = combined
        } else {
            self.boundingBox = BoundingBox(x: 0, y: 0, width: 0, height: 0)
        }
    }
}
