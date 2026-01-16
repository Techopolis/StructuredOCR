import Foundation
import CoreGraphics

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

/// Main entry point for structured OCR processing.
public actor StructuredOCR {
    private let textRecognizer: TextRecognizer
    private let layoutAnalyzer: LayoutAnalyzer
    private let headingDetector: HeadingDetector
    private let tableDetector: TableDetector
    private let linkDetector: LinkDetector
    private let listDetector: ListDetector
    private let pdfProcessor: PDFProcessor

    public init(
        languages: [String] = ["en-US"],
        recognitionLevel: TextRecognizer.RecognitionLevel = .accurate,
        pdfDPI: CGFloat = 300
    ) {
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
    public func process(image: CGImage) async throws -> StructuredDocument {
        // Step 1: Recognize text
        let textBlocks = try await textRecognizer.recognize(image: image)

        // Step 2: Analyze layout
        let lines = layoutAnalyzer.groupIntoLines(textBlocks)
        let columns = layoutAnalyzer.detectColumns(textBlocks)
        let heightStats = layoutAnalyzer.calculateHeightStatistics(textBlocks)

        // Step 3: Detect structures
        let headings = headingDetector.detect(blocks: textBlocks, statistics: heightStats)
        let tables = tableDetector.detect(blocks: textBlocks, lines: lines)
        let links = linkDetector.detect(blocks: textBlocks)
        let lists = listDetector.detect(blocks: textBlocks)

        // Step 4: Build paragraphs from remaining blocks
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
