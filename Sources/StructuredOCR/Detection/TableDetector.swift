import Foundation
import CoreGraphics

/// Detects tables by finding grid-like patterns of text blocks.
public struct TableDetector: Sendable {
    /// Minimum number of rows to consider a table
    public var minimumRows: Int

    /// Minimum number of columns to consider a table
    public var minimumColumns: Int

    /// Tolerance for alignment detection
    public var alignmentTolerance: CGFloat

    public init(
        minimumRows: Int = 2,
        minimumColumns: Int = 2,
        alignmentTolerance: CGFloat = 0.02
    ) {
        self.minimumRows = minimumRows
        self.minimumColumns = minimumColumns
        self.alignmentTolerance = alignmentTolerance
    }

    /// Detect tables from text blocks
    public func detect(blocks: [TextBlock], lines: [[TextBlock]]) -> [Table] {
        guard lines.count >= minimumRows else { return [] }

        // Find potential table regions
        let tableRegions = findTableRegions(lines: lines)

        return tableRegions.compactMap { region in
            buildTable(from: region)
        }
    }

    private func findTableRegions(lines: [[TextBlock]]) -> [[[TextBlock]]] {
        var regions: [[[TextBlock]]] = []
        var currentRegion: [[TextBlock]] = []
        var expectedColumnCount: Int?

        for line in lines {
            guard line.count >= minimumColumns else {
                if currentRegion.count >= minimumRows {
                    regions.append(currentRegion)
                }
                currentRegion = []
                expectedColumnCount = nil
                continue
            }

            if let expected = expectedColumnCount {
                // Check if this line has similar column count
                if abs(line.count - expected) <= 1 && hasAlignedColumns(currentRegion.last ?? [], line) {
                    currentRegion.append(line)
                } else {
                    if currentRegion.count >= minimumRows {
                        regions.append(currentRegion)
                    }
                    currentRegion = [line]
                    expectedColumnCount = line.count
                }
            } else {
                currentRegion = [line]
                expectedColumnCount = line.count
            }
        }

        if currentRegion.count >= minimumRows {
            regions.append(currentRegion)
        }

        return regions
    }

    private func hasAlignedColumns(_ line1: [TextBlock], _ line2: [TextBlock]) -> Bool {
        guard !line1.isEmpty, !line2.isEmpty else { return false }

        // Check if x positions are roughly aligned
        let minCount = min(line1.count, line2.count)
        var alignedCount = 0

        for i in 0..<minCount {
            let x1 = line1[i].boundingBox.minX
            let x2 = line2[i].boundingBox.minX

            if abs(x1 - x2) < alignmentTolerance {
                alignedCount += 1
            }
        }

        return CGFloat(alignedCount) / CGFloat(minCount) > 0.5
    }

    private func buildTable(from rows: [[TextBlock]]) -> Table? {
        guard !rows.isEmpty else { return nil }

        let columnCount = rows.map(\.count).max() ?? 0

        // Determine column x-positions
        let columnPositions = calculateColumnPositions(rows: rows, columnCount: columnCount)

        var tableRows: [TableRow] = []
        var allBlocks: [BoundingBox] = []

        for (rowIndex, rowBlocks) in rows.enumerated() {
            let cells = buildCells(
                from: rowBlocks,
                columnPositions: columnPositions,
                rowIndex: rowIndex
            )

            let rowBounds = rowBlocks.map(\.boundingBox).reduce(rowBlocks[0].boundingBox) { $0.union($1) }
            allBlocks.append(rowBounds)

            let isHeader = rowIndex == 0 && looksLikeHeader(rowBlocks, comparedTo: rows)

            tableRows.append(TableRow(
                cells: cells,
                boundingBox: rowBounds,
                isHeader: isHeader
            ))
        }

        let tableBounds = allBlocks.reduce(allBlocks[0]) { $0.union($1) }

        return Table(
            boundingBox: tableBounds,
            rows: tableRows,
            columnCount: columnCount
        )
    }

    private func calculateColumnPositions(rows: [[TextBlock]], columnCount: Int) -> [CGFloat] {
        var positions: [CGFloat] = Array(repeating: 0, count: columnCount)
        var counts: [Int] = Array(repeating: 0, count: columnCount)

        for row in rows {
            for (index, block) in row.enumerated() where index < columnCount {
                positions[index] += block.boundingBox.minX
                counts[index] += 1
            }
        }

        return positions.enumerated().map { index, sum in
            counts[index] > 0 ? sum / CGFloat(counts[index]) : 0
        }
    }

    private func buildCells(
        from blocks: [TextBlock],
        columnPositions: [CGFloat],
        rowIndex: Int
    ) -> [TableCell] {
        var cells: [TableCell] = []

        for (colIndex, block) in blocks.enumerated() {
            let cell = TableCell(
                text: block.text,
                boundingBox: block.boundingBox,
                textBlocks: [block],
                column: colIndex,
                row: rowIndex
            )
            cells.append(cell)
        }

        return cells
    }

    private func looksLikeHeader(_ firstRow: [TextBlock], comparedTo allRows: [[TextBlock]]) -> Bool {
        guard allRows.count > 1 else { return false }

        // Check if first row has larger text
        let firstRowAvgHeight = firstRow.map(\.boundingBox.height).reduce(0, +) / CGFloat(firstRow.count)

        let otherRowsHeights = allRows.dropFirst().flatMap { $0.map(\.boundingBox.height) }
        guard !otherRowsHeights.isEmpty else { return false }

        let otherAvgHeight = otherRowsHeights.reduce(0, +) / CGFloat(otherRowsHeights.count)

        return firstRowAvgHeight > otherAvgHeight * 1.1
    }
}
