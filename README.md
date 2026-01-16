# StructuredOCR

A native Swift library for extracting structured data from images and PDFs using OCR.

## Why StructuredOCR?

When building apps that need to process documents, receipts, forms, or any text-containing images, raw OCR output is often just a jumbled mess of text blocks. You get the text, but you lose the structure—headings become indistinguishable from body text, tables turn into scattered words, and lists lose their hierarchy.

**StructuredOCR solves this.** It uses Apple's Vision framework under the hood but goes further by analyzing the spatial relationships between text blocks to reconstruct the document's logical structure. The result is clean, organized data you can actually work with.

## Features

- **Headings Detection** — Automatically identifies headings based on font size and positioning
- **Paragraph Grouping** — Groups related text blocks into coherent paragraphs
- **Table Recognition** — Detects tabular data and preserves row/column structure
- **List Detection** — Identifies bulleted and numbered lists with proper hierarchy
- **Link Extraction** — Finds URLs and email addresses within text
- **Multi-Column Support** — Handles documents with complex multi-column layouts
- **PDF Processing** — Process entire PDFs or individual pages
- **Reading Order** — Returns text in logical reading order, not just spatial order

## Requirements

- Swift 5.9+
- macOS 13.0+
- iOS 16.0+
- tvOS 16.0+
- visionOS 1.0+

## Installation

### Swift Package Manager

Add StructuredOCR to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Techopolis/StructuredOCR.git", from: "1.0.0")
]
```

Or add it through Xcode: **File → Add Package Dependencies** and enter the repository URL.

## Usage

### Basic Image Processing

```swift
import StructuredOCR

let ocr = StructuredOCR()

// Process from a file URL
let document = try await ocr.process(url: imageURL)

// Access the full text in reading order
print(document.fullText)

// Work with structured elements
for heading in document.headings {
    print("Heading (Level \(heading.level)): \(heading.text)")
}

for table in document.tables {
    for row in table.textGrid {
        print(row.joined(separator: " | "))
    }
}
```

### Platform-Specific Images

```swift
// macOS
let document = try await ocr.process(nsImage: myNSImage)

// iOS / tvOS / visionOS
let document = try await ocr.process(uiImage: myUIImage)
```

### PDF Processing

```swift
// Process entire PDF
let multiPageDoc = try await ocr.processPDF(url: pdfURL)

for (index, page) in multiPageDoc.pages.enumerated() {
    print("Page \(index + 1): \(page.headings.count) headings, \(page.tables.count) tables")
}

// Process a single page
let page = try await ocr.processPDFPage(url: pdfURL, pageIndex: 0)
```

### Configuration Options

```swift
let ocr = StructuredOCR(
    languages: ["en-US", "es-ES"],  // Recognition languages
    recognitionLevel: .accurate,    // .fast or .accurate
    pdfDPI: 300                     // PDF rendering resolution
)
```

### Accessing Document Structure

```swift
let document = try await ocr.process(url: imageURL)

// Check document properties
if document.isMultiColumn {
    print("Document has \(document.columns.count) columns")
}

// Iterate elements in reading order
for element in document.elements {
    switch element {
    case .heading(let h):
        print("Heading: \(h.text)")
    case .paragraph(let p):
        print("Paragraph: \(p.text)")
    case .table(let t):
        print("Table with \(t.rows.count) rows")
    case .list(let l):
        print("List with \(l.items.count) items")
    case .textBlock(let b):
        print("Text: \(b.text)")
    }
}
```

## Why MIT License?

StructuredOCR is released under the **MIT License** because we believe OCR functionality should be freely available to all developers building apps for the Apple ecosystem.

**For App Store developers**, MIT is the ideal choice:
- **No copyleft restrictions** — You can use this in commercial apps without open-sourcing your code
- **Full App Store compatibility** — Unlike GPL/LGPL, MIT has no conflicts with App Store distribution or DRM
- **Simple attribution** — Just include the license file in your source; no in-app attribution required
- **Maximum flexibility** — Modify, distribute, sublicense, or sell apps using this library freely

We want you to build great apps. The license should never be a barrier.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) for details.

---

Built by [Techopolis LLC](https://techopolis.dev)
