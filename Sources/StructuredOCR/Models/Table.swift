import Foundation

/// A detected table in the document.
public struct Table: Sendable, Hashable, Identifiable {
    public let id: UUID
    /// The bounding box of the entire table
    public let boundingBox: BoundingBox
    /// The rows of the table
    public let rows: [TableRow]
    /// Number of columns detected
    public let columnCount: Int

    public init(
        id: UUID = UUID(),
        boundingBox: BoundingBox,
        rows: [TableRow],
        columnCount: Int
    ) {
        self.id = id
        self.boundingBox = boundingBox
        self.rows = rows
        self.columnCount = columnCount
    }

    /// Number of rows in the table
    public var rowCount: Int {
        rows.count
    }

    /// Get a specific cell by row and column index
    public func cell(row: Int, column: Int) -> TableCell? {
        guard row >= 0, row < rows.count else { return nil }
        let rowData = rows[row]
        guard column >= 0, column < rowData.cells.count else { return nil }
        return rowData.cells[column]
    }

    /// Get all text from the table as a 2D array
    public var textGrid: [[String]] {
        rows.map { row in
            row.cells.map(\.text)
        }
    }
}

/// A row in a table.
public struct TableRow: Sendable, Hashable, Identifiable {
    public let id: UUID
    /// The cells in this row
    public let cells: [TableCell]
    /// The bounding box of the row
    public let boundingBox: BoundingBox
    /// Whether this appears to be a header row
    public let isHeader: Bool

    public init(
        id: UUID = UUID(),
        cells: [TableCell],
        boundingBox: BoundingBox,
        isHeader: Bool = false
    ) {
        self.id = id
        self.cells = cells
        self.boundingBox = boundingBox
        self.isHeader = isHeader
    }
}

/// A cell in a table.
public struct TableCell: Sendable, Hashable, Identifiable {
    public let id: UUID
    /// The text content of the cell
    public let text: String
    /// The bounding box of the cell
    public let boundingBox: BoundingBox
    /// The underlying text blocks
    public let textBlocks: [TextBlock]
    /// Column index
    public let column: Int
    /// Row index
    public let row: Int

    public init(
        id: UUID = UUID(),
        text: String,
        boundingBox: BoundingBox,
        textBlocks: [TextBlock],
        column: Int,
        row: Int
    ) {
        self.id = id
        self.text = text
        self.boundingBox = boundingBox
        self.textBlocks = textBlocks
        self.column = column
        self.row = row
    }
}
