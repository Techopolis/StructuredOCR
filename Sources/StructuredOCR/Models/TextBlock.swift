import Foundation

/// A recognized text block with its bounding box and confidence score.
public struct TextBlock: Sendable, Hashable, Identifiable {
    public let id: UUID
    /// The recognized text content
    public let text: String
    /// The bounding box of this text block
    public let boundingBox: BoundingBox
    /// Recognition confidence (0-1)
    public let confidence: Float

    public init(
        id: UUID = UUID(),
        text: String,
        boundingBox: BoundingBox,
        confidence: Float
    ) {
        self.id = id
        self.text = text
        self.boundingBox = boundingBox
        self.confidence = confidence
    }

    /// The height of this text block (can indicate font size)
    public var height: CGFloat {
        boundingBox.height
    }

    /// Check if this text block appears to be a single word
    public var isSingleWord: Bool {
        !text.contains(" ")
    }

    /// Check if this text block is empty or whitespace only
    public var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
