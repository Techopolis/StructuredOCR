import XCTest
@testable import StructuredOCR

final class StructuredOCRTests: XCTestCase {

    func testBoundingBoxCreation() {
        let box = BoundingBox(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
        XCTAssertEqual(box.x, 0.1)
        XCTAssertEqual(box.y, 0.2)
        XCTAssertEqual(box.width, 0.3)
        XCTAssertEqual(box.height, 0.4)
    }

    func testBoundingBoxCenter() {
        let box = BoundingBox(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        XCTAssertEqual(box.center.x, 0.5)
        XCTAssertEqual(box.center.y, 0.5)
    }

    func testBoundingBoxUnion() {
        let box1 = BoundingBox(x: 0.0, y: 0.0, width: 0.5, height: 0.5)
        let box2 = BoundingBox(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
        let union = box1.union(box2)
        XCTAssertEqual(union.x, 0.0)
        XCTAssertEqual(union.y, 0.0)
        XCTAssertEqual(union.width, 1.0)
        XCTAssertEqual(union.height, 1.0)
    }

    func testTextBlockCreation() {
        let box = BoundingBox(x: 0.1, y: 0.2, width: 0.3, height: 0.04)
        let block = TextBlock(text: "Hello World", boundingBox: box, confidence: 0.95)
        XCTAssertEqual(block.text, "Hello World")
        XCTAssertEqual(block.confidence, 0.95)
        XCTAssertFalse(block.isSingleWord)
    }

    func testTextBlockSingleWord() {
        let box = BoundingBox(x: 0.1, y: 0.2, width: 0.1, height: 0.04)
        let block = TextBlock(text: "Hello", boundingBox: box, confidence: 0.9)
        XCTAssertTrue(block.isSingleWord)
    }

    func testLinkDetectorURLs() {
        let detector = LinkDetector()
        let box = BoundingBox(x: 0.1, y: 0.2, width: 0.5, height: 0.04)

        let urlBlock = TextBlock(text: "Visit https://example.com for more", boundingBox: box, confidence: 0.9)
        let links = detector.detect(blocks: [urlBlock])
        XCTAssertFalse(links.isEmpty)
        XCTAssertEqual(links.first?.type, .url)
    }

    func testLinkDetectorEmails() {
        let detector = LinkDetector()
        let box = BoundingBox(x: 0.1, y: 0.2, width: 0.5, height: 0.04)

        let emailBlock = TextBlock(text: "Contact test@example.com", boundingBox: box, confidence: 0.9)
        let emailLinks = detector.detect(blocks: [emailBlock])
        XCTAssertFalse(emailLinks.isEmpty)
        XCTAssertEqual(emailLinks.first?.type, .email)
    }

    func testLayoutAnalyzerGroupIntoLines() {
        let analyzer = LayoutAnalyzer()

        // Create blocks on same line
        let block1 = TextBlock(text: "Hello", boundingBox: BoundingBox(x: 0.1, y: 0.5, width: 0.1, height: 0.04), confidence: 0.9)
        let block2 = TextBlock(text: "World", boundingBox: BoundingBox(x: 0.25, y: 0.5, width: 0.1, height: 0.04), confidence: 0.9)

        // Create block on different line
        let block3 = TextBlock(text: "Test", boundingBox: BoundingBox(x: 0.1, y: 0.3, width: 0.1, height: 0.04), confidence: 0.9)

        let lines = analyzer.groupIntoLines([block1, block2, block3])
        XCTAssertEqual(lines.count, 2)
    }

    func testHeadingDetection() {
        let detector = HeadingDetector(sizeThreshold: 1.2)

        // Multiple normal text blocks to establish baseline
        let normal1 = TextBlock(text: "Normal one", boundingBox: BoundingBox(x: 0.1, y: 0.4, width: 0.3, height: 0.02), confidence: 0.9)
        let normal2 = TextBlock(text: "Normal two", boundingBox: BoundingBox(x: 0.1, y: 0.3, width: 0.3, height: 0.02), confidence: 0.9)
        let normal3 = TextBlock(text: "Normal three", boundingBox: BoundingBox(x: 0.1, y: 0.2, width: 0.3, height: 0.02), confidence: 0.9)

        // Heading (3x taller than normal text)
        let headingBlock = TextBlock(text: "Title", boundingBox: BoundingBox(x: 0.1, y: 0.8, width: 0.2, height: 0.06), confidence: 0.9)

        let allBlocks = [normal1, normal2, normal3, headingBlock]
        let stats = LayoutAnalyzer().calculateHeightStatistics(allBlocks)
        let headings = detector.detect(blocks: allBlocks, statistics: stats)

        XCTAssertEqual(headings.count, 1)
        XCTAssertEqual(headings.first?.text, "Title")
    }
}
