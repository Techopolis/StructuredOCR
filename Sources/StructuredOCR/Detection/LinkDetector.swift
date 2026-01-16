import Foundation

/// Detects URLs, emails, phone numbers, and other links in text.
public struct LinkDetector: Sendable {
    /// Regex patterns for different link types
    private static let patterns: [(LinkType, String)] = [
        (.url, #"https?://[^\s<>\"{}|\\^`\[\]]+"#),
        (.url, #"www\.[^\s<>\"{}|\\^`\[\]]+"#),
        (.email, #"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"#),
        (.phone, #"(\+\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}"#),
        (.file, #"(file://|/)[^\s<>\"{}|\\^`\[\]]+"#)
    ]

    public init() {}

    /// Detect links in text blocks
    public func detect(blocks: [TextBlock]) -> [Link] {
        var links: [Link] = []

        for block in blocks {
            let detected = detectInText(block.text, textBlock: block)
            links.append(contentsOf: detected)
        }

        return links
    }

    private func detectInText(_ text: String, textBlock: TextBlock) -> [Link] {
        var links: [Link] = []

        for (linkType, pattern) in Self.patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                continue
            }

            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: range)

            for match in matches {
                guard let matchRange = Range(match.range, in: text) else { continue }

                let matchedText = String(text[matchRange])
                let url = normalizeURL(matchedText, type: linkType)

                let link = Link(
                    text: matchedText,
                    url: url,
                    type: linkType,
                    boundingBox: textBlock.boundingBox,
                    textBlock: textBlock
                )

                links.append(link)
            }
        }

        return links
    }

    private func normalizeURL(_ text: String, type: LinkType) -> String {
        switch type {
        case .url:
            if text.lowercased().hasPrefix("www.") {
                return "https://\(text)"
            }
            return text
        case .email:
            return "mailto:\(text)"
        case .phone:
            let digits = text.filter(\.isNumber)
            return "tel:\(digits)"
        case .file:
            return text
        case .unknown:
            return text
        }
    }
}
