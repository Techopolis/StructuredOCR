import Foundation
import CoreGraphics

/// Analyzes the spatial layout of text blocks to identify structure.
public struct LayoutAnalyzer: Sendable {
    /// Threshold for considering blocks on the same line (as fraction of average height)
    public var lineThreshold: CGFloat

    /// Threshold for considering blocks in the same column (as fraction of page width)
    public var columnThreshold: CGFloat

    /// Minimum number of aligned elements to consider a column
    public var minimumColumnElements: Int

    public init(
        lineThreshold: CGFloat = 0.5,
        columnThreshold: CGFloat = 0.1,
        minimumColumnElements: Int = 3
    ) {
        self.lineThreshold = lineThreshold
        self.columnThreshold = columnThreshold
        self.minimumColumnElements = minimumColumnElements
    }

    /// Group text blocks into lines (horizontally adjacent blocks at same y level)
    public func groupIntoLines(_ blocks: [TextBlock]) -> [[TextBlock]] {
        guard !blocks.isEmpty else { return [] }

        // Sort by y position (top to bottom in normalized coords means higher y first)
        let sorted = blocks.sorted { $0.boundingBox.maxY > $1.boundingBox.maxY }

        var lines: [[TextBlock]] = []
        var currentLine: [TextBlock] = []
        var currentY: CGFloat = sorted[0].boundingBox.center.y

        let avgHeight = sorted.map(\.boundingBox.height).reduce(0, +) / CGFloat(sorted.count)

        for block in sorted {
            let yDistance = abs(block.boundingBox.center.y - currentY)

            if yDistance < avgHeight * lineThreshold {
                currentLine.append(block)
            } else {
                if !currentLine.isEmpty {
                    // Sort line left to right
                    lines.append(currentLine.sorted { $0.boundingBox.minX < $1.boundingBox.minX })
                }
                currentLine = [block]
                currentY = block.boundingBox.center.y
            }
        }

        if !currentLine.isEmpty {
            lines.append(currentLine.sorted { $0.boundingBox.minX < $1.boundingBox.minX })
        }

        return lines
    }

    /// Detect columns in the document
    public func detectColumns(_ blocks: [TextBlock]) -> [Column] {
        guard blocks.count >= minimumColumnElements else { return [] }

        // Find distinct x-position clusters
        let xPositions = blocks.map { $0.boundingBox.minX }
        let clusters = clusterValues(xPositions, threshold: columnThreshold)

        guard clusters.count > 1 else { return [] }

        var columns: [Column] = []

        for (index, cluster) in clusters.enumerated() {
            let columnBlocks = blocks.filter { block in
                cluster.contains { abs($0 - block.boundingBox.minX) < columnThreshold }
            }

            guard columnBlocks.count >= minimumColumnElements else { continue }

            let boundingBox = combineBoundingBoxes(columnBlocks.map(\.boundingBox))

            columns.append(Column(
                boundingBox: boundingBox,
                textBlocks: columnBlocks,
                index: index
            ))
        }

        return columns.sorted { $0.boundingBox.minX < $1.boundingBox.minX }
    }

    /// Find blocks that are vertically adjacent (potential paragraphs)
    public func findVerticallyAdjacentGroups(_ blocks: [TextBlock], maxGap: CGFloat = 0.02) -> [[TextBlock]] {
        guard !blocks.isEmpty else { return [] }

        let sorted = blocks.sorted { $0.boundingBox.maxY > $1.boundingBox.maxY }

        var groups: [[TextBlock]] = []
        var currentGroup: [TextBlock] = [sorted[0]]

        for block in sorted.dropFirst() {
            let lastBlock = currentGroup.last!
            let gap = lastBlock.boundingBox.minY - block.boundingBox.maxY

            // Check if vertically adjacent and horizontally overlapping
            if gap < maxGap && gap >= 0 &&
               block.boundingBox.isHorizontallyAligned(with: lastBlock.boundingBox, tolerance: 0.3) {
                currentGroup.append(block)
            } else {
                if !currentGroup.isEmpty {
                    groups.append(currentGroup)
                }
                currentGroup = [block]
            }
        }

        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }

        return groups
    }

    /// Calculate statistics about text block heights (for heading detection)
    public func calculateHeightStatistics(_ blocks: [TextBlock]) -> HeightStatistics {
        guard !blocks.isEmpty else {
            return HeightStatistics(mean: 0, median: 0, standardDeviation: 0, min: 0, max: 0)
        }

        let heights = blocks.map(\.boundingBox.height).sorted()
        let count = CGFloat(heights.count)

        let mean = heights.reduce(0, +) / count
        let median = heights[heights.count / 2]
        let min = heights.first!
        let max = heights.last!

        let variance = heights.map { pow($0 - mean, 2) }.reduce(0, +) / count
        let standardDeviation = sqrt(variance)

        return HeightStatistics(
            mean: mean,
            median: median,
            standardDeviation: standardDeviation,
            min: min,
            max: max
        )
    }

    // MARK: - Private Helpers

    private func clusterValues(_ values: [CGFloat], threshold: CGFloat) -> [[CGFloat]] {
        guard !values.isEmpty else { return [] }

        let sorted = values.sorted()
        var clusters: [[CGFloat]] = [[sorted[0]]]

        for value in sorted.dropFirst() {
            if let lastCluster = clusters.last,
               let lastValue = lastCluster.last,
               abs(value - lastValue) < threshold {
                clusters[clusters.count - 1].append(value)
            } else {
                clusters.append([value])
            }
        }

        return clusters
    }

    private func combineBoundingBoxes(_ boxes: [BoundingBox]) -> BoundingBox {
        guard let first = boxes.first else {
            return BoundingBox(x: 0, y: 0, width: 0, height: 0)
        }

        return boxes.dropFirst().reduce(first) { $0.union($1) }
    }
}

/// Statistics about text block heights in a document.
public struct HeightStatistics: Sendable {
    public let mean: CGFloat
    public let median: CGFloat
    public let standardDeviation: CGFloat
    public let min: CGFloat
    public let max: CGFloat

    /// Check if a height is significantly larger than average (potential heading)
    public func isSignificantlyLarger(_ height: CGFloat, threshold: CGFloat = 1.5) -> Bool {
        height > mean + (standardDeviation * threshold)
    }
}
