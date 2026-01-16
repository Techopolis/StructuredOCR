import Foundation
import CoreGraphics

/// Analyzes the spatial layout of text blocks to identify structure.
public struct LayoutAnalyzer: Sendable {
    /// Threshold for considering blocks on the same line (as fraction of average height)
    public var lineThreshold: CGFloat

    /// Minimum gap width to consider as a column separator (as fraction of page width)
    public var columnGapThreshold: CGFloat

    /// Minimum number of aligned elements to consider a column
    public var minimumColumnElements: Int

    public init(
        lineThreshold: CGFloat = 0.5,
        columnGapThreshold: CGFloat = 0.03,
        minimumColumnElements: Int = 3
    ) {
        self.lineThreshold = lineThreshold
        self.columnGapThreshold = columnGapThreshold
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

    /// Detect columns by finding vertical gutters (whitespace gaps) in the document
    public func detectColumns(_ blocks: [TextBlock]) -> [Column] {
        guard blocks.count >= minimumColumnElements else { return [] }

        // Find vertical gutters by analyzing horizontal gaps across multiple lines
        let lines = groupIntoLines(blocks)
        guard lines.count >= 2 else { return [] }

        // Collect all horizontal gaps between blocks on each line
        var allGaps: [(start: CGFloat, end: CGFloat)] = []

        for line in lines where line.count > 1 {
            let sortedLine = line.sorted { $0.boundingBox.minX < $1.boundingBox.minX }
            for i in 0..<(sortedLine.count - 1) {
                let gapStart = sortedLine[i].boundingBox.maxX
                let gapEnd = sortedLine[i + 1].boundingBox.minX
                let gapWidth = gapEnd - gapStart

                if gapWidth >= columnGapThreshold {
                    allGaps.append((start: gapStart, end: gapEnd))
                }
            }
        }

        // Find consistent gutters (gaps that appear at similar x positions across lines)
        let gutters = findConsistentGutters(allGaps, minOccurrences: lines.count / 3)

        guard !gutters.isEmpty else { return [] }

        // Create columns based on gutters
        var columnBoundaries: [CGFloat] = [0.0]
        for gutter in gutters {
            let gutterCenter = (gutter.start + gutter.end) / 2
            columnBoundaries.append(gutterCenter)
        }
        columnBoundaries.append(1.0)

        var columns: [Column] = []

        for i in 0..<(columnBoundaries.count - 1) {
            let leftBound = columnBoundaries[i]
            let rightBound = columnBoundaries[i + 1]

            let columnBlocks = blocks.filter { block in
                let centerX = block.boundingBox.center.x
                return centerX >= leftBound && centerX < rightBound
            }

            guard columnBlocks.count >= minimumColumnElements else { continue }

            let boundingBox = combineBoundingBoxes(columnBlocks.map(\.boundingBox))

            columns.append(Column(
                boundingBox: boundingBox,
                textBlocks: columnBlocks,
                index: i
            ))
        }

        return columns.sorted { $0.boundingBox.minX < $1.boundingBox.minX }
    }

    /// Get text blocks in proper reading order (respecting columns)
    public func getReadingOrder(_ blocks: [TextBlock]) -> [TextBlock] {
        let columns = detectColumns(blocks)

        if columns.count > 1 {
            // Multi-column: read each column top to bottom, then move to next column
            var ordered: [TextBlock] = []
            for column in columns {
                let columnBlocks = column.textBlocks.sorted { $0.boundingBox.maxY > $1.boundingBox.maxY }
                ordered.append(contentsOf: columnBlocks)
            }
            return ordered
        } else {
            // Single column: standard top-to-bottom, left-to-right
            return blocks.sorted { block1, block2 in
                let avgHeight = (block1.boundingBox.height + block2.boundingBox.height) / 2
                // If on approximately the same line, sort left to right
                if abs(block1.boundingBox.maxY - block2.boundingBox.maxY) < avgHeight * lineThreshold {
                    return block1.boundingBox.minX < block2.boundingBox.minX
                }
                // Otherwise sort top to bottom
                return block1.boundingBox.maxY > block2.boundingBox.maxY
            }
        }
    }

    /// Find blocks that are vertically adjacent (potential paragraphs)
    public func findVerticallyAdjacentGroups(_ blocks: [TextBlock], maxGap: CGFloat = 0.02) -> [[TextBlock]] {
        guard !blocks.isEmpty else { return [] }

        // Use reading order for proper column handling
        let sorted = getReadingOrder(blocks)

        var groups: [[TextBlock]] = []
        var currentGroup: [TextBlock] = [sorted[0]]

        for block in sorted.dropFirst() {
            let lastBlock = currentGroup.last!
            let gap = lastBlock.boundingBox.minY - block.boundingBox.maxY

            // Check if vertically adjacent and horizontally overlapping (same column)
            if gap < maxGap && gap >= -0.01 &&
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

    private func findConsistentGutters(_ gaps: [(start: CGFloat, end: CGFloat)], minOccurrences: Int) -> [(start: CGFloat, end: CGFloat)] {
        guard !gaps.isEmpty else { return [] }

        // Cluster gaps by their center position
        var gutterClusters: [[(start: CGFloat, end: CGFloat)]] = []

        for gap in gaps {
            let gapCenter = (gap.start + gap.end) / 2
            var foundCluster = false

            for i in 0..<gutterClusters.count {
                let clusterCenter = gutterClusters[i].map { ($0.start + $0.end) / 2 }.reduce(0, +) / CGFloat(gutterClusters[i].count)

                if abs(gapCenter - clusterCenter) < 0.05 {
                    gutterClusters[i].append(gap)
                    foundCluster = true
                    break
                }
            }

            if !foundCluster {
                gutterClusters.append([gap])
            }
        }

        // Return gutters that appear consistently
        return gutterClusters
            .filter { $0.count >= max(minOccurrences, 2) }
            .map { cluster in
                let avgStart = cluster.map(\.start).reduce(0, +) / CGFloat(cluster.count)
                let avgEnd = cluster.map(\.end).reduce(0, +) / CGFloat(cluster.count)
                return (start: avgStart, end: avgEnd)
            }
            .sorted { $0.start < $1.start }
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
