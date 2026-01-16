import Foundation
import CoreGraphics

/// A normalized bounding box representing the location of an element in a document.
/// Coordinates are normalized (0-1) relative to the document dimensions.
public struct BoundingBox: Sendable, Hashable {
    /// The normalized x coordinate of the left edge (0-1)
    public let x: CGFloat
    /// The normalized y coordinate of the bottom edge (0-1)
    public let y: CGFloat
    /// The normalized width (0-1)
    public let width: CGFloat
    /// The normalized height (0-1)
    public let height: CGFloat

    public init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public init(cgRect: CGRect) {
        self.x = cgRect.origin.x
        self.y = cgRect.origin.y
        self.width = cgRect.width
        self.height = cgRect.height
    }

    /// The center point of the bounding box
    public var center: CGPoint {
        CGPoint(x: x + width / 2, y: y + height / 2)
    }

    /// The minimum x coordinate (left edge)
    public var minX: CGFloat { x }

    /// The maximum x coordinate (right edge)
    public var maxX: CGFloat { x + width }

    /// The minimum y coordinate (bottom edge)
    public var minY: CGFloat { y }

    /// The maximum y coordinate (top edge)
    public var maxY: CGFloat { y + height }

    /// Convert to CGRect
    public var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }

    /// Check if this bounding box overlaps with another
    public func intersects(_ other: BoundingBox) -> Bool {
        cgRect.intersects(other.cgRect)
    }

    /// Calculate the union of this bounding box with another
    public func union(_ other: BoundingBox) -> BoundingBox {
        BoundingBox(cgRect: cgRect.union(other.cgRect))
    }

    /// Calculate vertical distance to another bounding box
    public func verticalDistance(to other: BoundingBox) -> CGFloat {
        if maxY < other.minY {
            return other.minY - maxY
        } else if other.maxY < minY {
            return minY - other.maxY
        }
        return 0
    }

    /// Calculate horizontal distance to another bounding box
    public func horizontalDistance(to other: BoundingBox) -> CGFloat {
        if maxX < other.minX {
            return other.minX - maxX
        } else if other.maxX < minX {
            return minX - other.maxX
        }
        return 0
    }

    /// Check if this box is horizontally aligned with another (overlapping x ranges)
    public func isHorizontallyAligned(with other: BoundingBox, tolerance: CGFloat = 0.01) -> Bool {
        let overlap = min(maxX, other.maxX) - max(minX, other.minX)
        let minWidth = min(width, other.width)
        return overlap > minWidth * (1 - tolerance)
    }

    /// Check if this box is vertically aligned with another (overlapping y ranges)
    public func isVerticallyAligned(with other: BoundingBox, tolerance: CGFloat = 0.01) -> Bool {
        let overlap = min(maxY, other.maxY) - max(minY, other.minY)
        let minHeight = min(height, other.height)
        return overlap > minHeight * (1 - tolerance)
    }
}
