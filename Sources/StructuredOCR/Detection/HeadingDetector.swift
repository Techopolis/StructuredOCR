import Foundation
import CoreGraphics

/// Detects headings based on text size, position, and isolation.
public struct HeadingDetector: Sendable {
    /// Minimum size ratio compared to median to consider a heading
    public var sizeThreshold: CGFloat

    /// Maximum number of heading levels to detect
    public var maxLevels: Int

    public init(sizeThreshold: CGFloat = 1.2, maxLevels: Int = 6) {
        self.sizeThreshold = sizeThreshold
        self.maxLevels = maxLevels
    }

    /// Detect headings from text blocks
    public func detect(
        blocks: [TextBlock],
        statistics: HeightStatistics
    ) -> [Heading] {
        guard !blocks.isEmpty, statistics.mean > 0 else { return [] }

        // Find blocks significantly larger than average
        let potentialHeadings = blocks.filter { block in
            block.boundingBox.height > statistics.median * sizeThreshold
        }

        guard !potentialHeadings.isEmpty else { return [] }

        // Group by size to determine heading levels
        let heights = potentialHeadings.map(\.boundingBox.height).sorted(by: >)
        let uniqueHeights = findDistinctHeights(heights)

        var headings: [Heading] = []

        for block in potentialHeadings {
            let level = determineLevel(
                height: block.boundingBox.height,
                distinctHeights: uniqueHeights
            )

            let heading = Heading(
                text: block.text,
                boundingBox: block.boundingBox,
                level: level,
                textBlocks: [block]
            )

            headings.append(heading)
        }

        // Sort by position (top to bottom)
        return headings.sorted { $0.boundingBox.maxY > $1.boundingBox.maxY }
    }

    private func findDistinctHeights(_ heights: [CGFloat]) -> [CGFloat] {
        guard !heights.isEmpty else { return [] }

        var distinct: [CGFloat] = [heights[0]]
        let threshold: CGFloat = 0.01

        for height in heights.dropFirst() {
            if let last = distinct.last, abs(height - last) > threshold {
                distinct.append(height)
            }
        }

        return Array(distinct.prefix(maxLevels))
    }

    private func determineLevel(height: CGFloat, distinctHeights: [CGFloat]) -> Int {
        for (index, h) in distinctHeights.enumerated() {
            if abs(height - h) < 0.01 {
                return index + 1
            }
        }
        return distinctHeights.count
    }
}
