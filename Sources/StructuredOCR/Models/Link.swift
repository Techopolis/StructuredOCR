import Foundation

/// A detected link (URL or email) in the document.
public struct Link: Sendable, Hashable, Identifiable {
    public let id: UUID
    /// The displayed text
    public let text: String
    /// The detected URL or email address
    public let url: String
    /// The type of link
    public let type: LinkType
    /// The bounding box of the link text
    public let boundingBox: BoundingBox
    /// The underlying text block
    public let textBlock: TextBlock

    public init(
        id: UUID = UUID(),
        text: String,
        url: String,
        type: LinkType,
        boundingBox: BoundingBox,
        textBlock: TextBlock
    ) {
        self.id = id
        self.text = text
        self.url = url
        self.type = type
        self.boundingBox = boundingBox
        self.textBlock = textBlock
    }
}

/// The type of detected link.
public enum LinkType: String, Sendable, Hashable {
    /// A web URL (http/https)
    case url
    /// An email address
    case email
    /// A phone number
    case phone
    /// A file path
    case file
    /// Unknown link type
    case unknown
}
