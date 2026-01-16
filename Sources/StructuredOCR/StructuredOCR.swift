import Foundation
import CoreGraphics
import Vision

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

/// Main entry point for structured OCR processing.
/// Uses Apple's RecognizeDocumentsRequest (iOS 26+/macOS 26+) for proper document structure
/// detection including paragraphs, tables, lists, and reading order.
/// Falls back to VNRecognizeTextRequest with custom analysis for older OS versions.
public actor StructuredOCR {
    private let textRecognizer: TextRecognizer
    private let layoutAnalyzer: LayoutAnalyzer
    private let headingDetector: HeadingDetector
    private let tableDetector: TableDetector
    private let linkDetector: LinkDetector
    private let listDetector: ListDetector
    private let pdfProcessor: PDFProcessor
    private let languages: [String]

    public init(
        languages: [String] = ["en-US"],
        recognitionLevel: TextRecognizer.RecognitionLevel = .accurate,
        pdfDPI: CGFloat = 300
    ) {
        self.languages = languages
        self.textRecognizer = TextRecognizer(
            languages: languages,
            recognitionLevel: recognitionLevel
        )
        self.layoutAnalyzer = LayoutAnalyzer()
        self.headingDetector = HeadingDetector()
        self.tableDetector = TableDetector()
        self.linkDetector = LinkDetector()
        self.listDetector = ListDetector()
        self.pdfProcessor = PDFProcessor(renderDPI: pdfDPI)
    }

    /// Process an image and return a structured document.
    /// Uses RecognizeDocumentsRequest on iOS 26+/macOS 26+ for best results.
    public func process(image: CGImage) async throws -> StructuredDocument {
        if #available(macOS 26.0, iOS 26.0, tvOS 26.0, visionOS 26.0, *) {
            return try await processWithDocumentsRequest(image: image)
        } else {
            return try await processWithLegacyAPI(image: image)
        }
    }

    // MARK: - iOS 26+ Document Recognition

    @available(macOS 26.0, iOS 26.0, tvOS 26.0, visionOS 26.0, *)
    private func processWithDocumentsRequest(image: CGImage) async throws -> StructuredDocument {
        let request = RecognizeDocumentsRequest()

        let observations = try await request.perform(on: image)

        guard let observation = observations.first else {
            // No document detected, fall back to legacy
            return try await processWithLegacyAPI(image: image)
        }

        let doc = observation.document

        // Extract text blocks from lines for compatibility
        var textBlocks: [TextBlock] = []
        var yPosition: CGFloat = 1.0
        for line in doc.text.lines {
            let block = TextBlock(
                text: line.transcript,
                boundingBox: BoundingBox(x: 0, y: yPosition, width: 1, height: 0.02),
                confidence: 1.0
            )
            textBlocks.append(block)
            yPosition -= 0.025
        }

        // Extract paragraphs - proper reading order from Apple's API
        // doc.text gives us text in different views: transcript, lines, words
        var paragraphs: [Paragraph] = []

        // Group lines into paragraphs based on the document structure
        // The lines are already in proper reading order from Apple's API
        var currentParagraphLines: [String] = []
        for line in doc.text.lines {
            let lineText = line.transcript
            if lineText.isEmpty && !currentParagraphLines.isEmpty {
                // Empty line indicates paragraph break
                let paragraphText = currentParagraphLines.joined(separator: " ")
                let block = TextBlock(
                    text: paragraphText,
                    boundingBox: BoundingBox(x: 0, y: yPosition, width: 1, height: 0.02),
                    confidence: 1.0
                )
                paragraphs.append(Paragraph(textBlocks: [block]))
                currentParagraphLines = []
                yPosition -= 0.03
            } else if !lineText.isEmpty {
                currentParagraphLines.append(lineText)
            }
        }
        // Add final paragraph
        if !currentParagraphLines.isEmpty {
            let paragraphText = currentParagraphLines.joined(separator: " ")
            let block = TextBlock(
                text: paragraphText,
                boundingBox: BoundingBox(x: 0, y: yPosition, width: 1, height: 0.02),
                confidence: 1.0
            )
            paragraphs.append(Paragraph(textBlocks: [block]))
            yPosition -= 0.03
        }

        // Extract tables with proper structure
        var tables: [Table] = []
        for visionTable in doc.tables {
            var tableRows: [TableRow] = []
            var rowIndex = 0

            for row in visionTable.rows {
                var cells: [TableCell] = []
                var colIndex = 0

                for cell in row {
                    let cellText = cell.content.text.transcript
                    let cellBlock = TextBlock(
                        text: cellText,
                        boundingBox: BoundingBox(x: CGFloat(colIndex) * 0.2, y: yPosition, width: 0.2, height: 0.02),
                        confidence: 1.0
                    )
                    cells.append(TableCell(
                        text: cellText,
                        boundingBox: cellBlock.boundingBox,
                        textBlocks: [cellBlock],
                        column: colIndex,
                        row: rowIndex
                    ))
                    colIndex += 1
                }

                if !cells.isEmpty {
                    tableRows.append(TableRow(
                        cells: cells,
                        boundingBox: BoundingBox(x: 0, y: yPosition, width: 1, height: 0.02),
                        isHeader: rowIndex == 0
                    ))
                }
                rowIndex += 1
                yPosition -= 0.025
            }

            if !tableRows.isEmpty {
                let columnCount = tableRows.first?.cells.count ?? 0
                tables.append(Table(
                    boundingBox: BoundingBox(x: 0, y: yPosition + 0.1, width: 1, height: CGFloat(tableRows.count) * 0.025),
                    rows: tableRows,
                    columnCount: columnCount
                ))
            }
        }

        // Extract lists
        var lists: [List] = []
        for visionList in doc.lists {
            var items: [ListItem] = []

            for item in visionList.items {
                let itemText = item.content.text.transcript
                let itemBlock = TextBlock(
                    text: itemText,
                    boundingBox: BoundingBox(x: 0.05, y: yPosition, width: 0.95, height: 0.02),
                    confidence: 1.0
                )
                items.append(ListItem(
                    text: itemText,
                    marker: "•",
                    level: 0,
                    boundingBox: itemBlock.boundingBox,
                    textBlocks: [itemBlock]
                ))
                yPosition -= 0.025
            }

            if !items.isEmpty {
                lists.append(List(
                    items: items,
                    type: .unordered,
                    boundingBox: BoundingBox(x: 0, y: yPosition + 0.1, width: 1, height: CGFloat(items.count) * 0.025)
                ))
            }
        }

        // Detect headings by analyzing text sizes (still use legacy for this)
        let legacyBlocks = try await textRecognizer.recognize(image: image)
        let heightStats = layoutAnalyzer.calculateHeightStatistics(legacyBlocks)
        let headings = headingDetector.detect(blocks: legacyBlocks, statistics: heightStats)

        // Detect links
        let links = linkDetector.detect(blocks: textBlocks.isEmpty ? legacyBlocks : textBlocks)

        // Use legacy blocks if we didn't get any from the new API
        let finalTextBlocks = textBlocks.isEmpty ? legacyBlocks : textBlocks

        return StructuredDocument(
            size: CGSize(width: image.width, height: image.height),
            textBlocks: finalTextBlocks,
            headings: headings,
            paragraphs: paragraphs,
            tables: tables,
            links: links,
            lists: lists,
            columns: [] // New API handles reading order automatically
        )
    }

    // MARK: - Legacy API (iOS 13+)

    private func processWithLegacyAPI(image: CGImage) async throws -> StructuredDocument {
        let textBlocks = try await textRecognizer.recognize(image: image)

        let lines = layoutAnalyzer.groupIntoLines(textBlocks)
        let columns = layoutAnalyzer.detectColumns(textBlocks)
        let heightStats = layoutAnalyzer.calculateHeightStatistics(textBlocks)

        let headings = headingDetector.detect(blocks: textBlocks, statistics: heightStats)
        let tables = tableDetector.detect(blocks: textBlocks, lines: lines)
        let links = linkDetector.detect(blocks: textBlocks)
        let lists = listDetector.detect(blocks: textBlocks)

        let usedBlocks = collectUsedBlocks(headings: headings, tables: tables, lists: lists)
        let remainingBlocks = textBlocks.filter { !usedBlocks.contains($0.id) }
        let paragraphs = buildParagraphs(from: remainingBlocks)

        return StructuredDocument(
            size: CGSize(width: image.width, height: image.height),
            textBlocks: textBlocks,
            headings: headings,
            paragraphs: paragraphs,
            tables: tables,
            links: links,
            lists: lists,
            columns: columns
        )
    }

    /// Process image data and return a structured document.
    public func process(data: Data) async throws -> StructuredDocument {
        guard let image = createCGImage(from: data) else {
            throw StructuredOCRError.invalidImageData
        }
        return try await process(image: image)
    }

    /// Process an image from a file URL.
    public func process(url: URL) async throws -> StructuredDocument {
        let data = try Data(contentsOf: url)
        return try await process(data: data)
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    /// Process an NSImage (macOS).
    public func process(nsImage: NSImage) async throws -> StructuredDocument {
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw StructuredOCRError.invalidImageData
        }
        return try await process(image: cgImage)
    }
    #endif

    #if canImport(UIKit)
    /// Process a UIImage (iOS/tvOS/visionOS).
    public func process(uiImage: UIImage) async throws -> StructuredDocument {
        guard let cgImage = uiImage.cgImage else {
            throw StructuredOCRError.invalidImageData
        }
        return try await process(image: cgImage)
    }
    #endif

    // MARK: - PDF Processing

    /// Process a PDF file and return a multi-page document.
    public func processPDF(url: URL) async throws -> MultiPageDocument {
        let images = try pdfProcessor.extractPages(from: url)
        return try await processPDF(images: images)
    }

    /// Process PDF data and return a multi-page document.
    public func processPDF(data: Data) async throws -> MultiPageDocument {
        let images = try pdfProcessor.extractPages(from: data)
        return try await processPDF(images: images)
    }

    /// Process multiple images as pages.
    public func processPDF(images: [CGImage]) async throws -> MultiPageDocument {
        var pages: [StructuredDocument] = []

        for image in images {
            let page = try await process(image: image)
            pages.append(page)
        }

        return MultiPageDocument(pages: pages)
    }

    /// Process a single page from a PDF.
    public func processPDFPage(url: URL, pageIndex: Int) async throws -> StructuredDocument {
        let images = try pdfProcessor.extractPages(from: url)
        guard pageIndex >= 0, pageIndex < images.count else {
            throw StructuredOCRError.pageOutOfRange(pageIndex, total: images.count)
        }
        return try await process(image: images[pageIndex])
    }

    // MARK: - Private Helpers

    private func collectUsedBlocks(
        headings: [Heading],
        tables: [Table],
        lists: [List]
    ) -> Set<UUID> {
        var used = Set<UUID>()

        for heading in headings {
            for block in heading.textBlocks {
                used.insert(block.id)
            }
        }

        for table in tables {
            for row in table.rows {
                for cell in row.cells {
                    for block in cell.textBlocks {
                        used.insert(block.id)
                    }
                }
            }
        }

        for list in lists {
            for item in list.items {
                for block in item.textBlocks {
                    used.insert(block.id)
                }
            }
        }

        return used
    }

    private func buildParagraphs(from blocks: [TextBlock]) -> [Paragraph] {
        let groups = layoutAnalyzer.findVerticallyAdjacentGroups(blocks)
        return groups.map { Paragraph(textBlocks: $0) }
    }

    private func createCGImage(from data: Data) -> CGImage? {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        guard let nsImage = NSImage(data: data),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        return cgImage
        #elseif canImport(UIKit)
        guard let uiImage = UIImage(data: data),
              let cgImage = uiImage.cgImage else {
            return nil
        }
        return cgImage
        #else
        return nil
        #endif
    }
}

/// Errors that can occur during structured OCR processing.
public enum StructuredOCRError: Error, Sendable {
    case invalidImageData
    case processingFailed(String)
    case pageOutOfRange(Int, total: Int)
    case pdfProcessingFailed(String)
}
