import Foundation
import CoreGraphics
import PDFKit

/// Processes PDF documents for OCR.
public struct PDFProcessor: Sendable {
    /// DPI for rendering PDF pages to images
    public var renderDPI: CGFloat

    public init(renderDPI: CGFloat = 300) {
        self.renderDPI = renderDPI
    }

    /// Extract pages from a PDF as CGImages.
    public func extractPages(from url: URL) throws -> [CGImage] {
        guard let document = PDFDocument(url: url) else {
            throw PDFProcessorError.failedToOpenPDF
        }
        return try extractPages(from: document)
    }

    /// Extract pages from PDF data.
    public func extractPages(from data: Data) throws -> [CGImage] {
        guard let document = PDFDocument(data: data) else {
            throw PDFProcessorError.failedToOpenPDF
        }
        return try extractPages(from: document)
    }

    /// Extract pages from a PDFDocument.
    public func extractPages(from document: PDFDocument) throws -> [CGImage] {
        var images: [CGImage] = []

        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }
            if let image = renderPage(page) {
                images.append(image)
            }
        }

        guard !images.isEmpty else {
            throw PDFProcessorError.noPages
        }

        return images
    }

    /// Get page count without extracting.
    public func pageCount(url: URL) -> Int? {
        PDFDocument(url: url)?.pageCount
    }

    private func renderPage(_ page: PDFPage) -> CGImage? {
        let pageRect = page.bounds(for: .mediaBox)
        let scale = renderDPI / 72.0

        let width = Int(pageRect.width * scale)
        let height = Int(pageRect.height * scale)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }

        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        context.scaleBy(x: scale, y: scale)
        page.draw(with: .mediaBox, to: context)

        return context.makeImage()
    }
}

public enum PDFProcessorError: Error, Sendable {
    case failedToOpenPDF
    case noPages
    case pageOutOfRange
}
