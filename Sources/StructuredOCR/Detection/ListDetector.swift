import Foundation
import CoreGraphics

/// Detects lists (bulleted, numbered, checkboxes) in text.
public struct ListDetector: Sendable {
    private static let bulletMarkers = CharacterSet(charactersIn: "•◦▪▸▹►‣⁃-–—*")
    private static let numberedPattern = #"^(\d+[.)\]]|\([a-z]\)|[a-z][.)]|[ivxIVX]+[.)])\s+"#
    private static let checkboxPattern = #"^(\[[ x✓✔]\]|☐|☑|☒)\s+"#

    public var minimumItems: Int

    public init(minimumItems: Int = 2) {
        self.minimumItems = minimumItems
    }

    public func detect(blocks: [TextBlock]) -> [List] {
        var lists: [List] = []
        var currentItems: [ListItem] = []
        var currentType: ListType?

        let sorted = blocks.sorted { $0.boundingBox.maxY > $1.boundingBox.maxY }

        for block in sorted {
            if let (marker, type) = detectListMarker(in: block.text) {
                if currentType == nil {
                    currentType = type
                } else if currentType != type && currentItems.count >= minimumItems {
                    lists.append(buildList(items: currentItems, type: currentType!))
                    currentItems = []
                    currentType = type
                }

                let text = removeMarker(from: block.text)
                currentItems.append(ListItem(
                    text: text,
                    marker: marker,
                    level: 0,
                    boundingBox: block.boundingBox,
                    textBlocks: [block]
                ))
            } else if currentItems.count >= minimumItems, let type = currentType {
                lists.append(buildList(items: currentItems, type: type))
                currentItems = []
                currentType = nil
            }
        }

        if currentItems.count >= minimumItems, let type = currentType {
            lists.append(buildList(items: currentItems, type: type))
        }

        return lists
    }

    private func detectListMarker(in text: String) -> (String, ListType)? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let firstChar = trimmed.first else { return nil }

        if Self.bulletMarkers.contains(firstChar.unicodeScalars.first!) {
            return (String(firstChar), .unordered)
        }

        if let regex = try? NSRegularExpression(pattern: Self.numberedPattern),
           let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
           let range = Range(match.range(at: 1), in: trimmed) {
            return (String(trimmed[range]), .ordered)
        }

        if let regex = try? NSRegularExpression(pattern: Self.checkboxPattern),
           let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
           let range = Range(match.range(at: 1), in: trimmed) {
            return (String(trimmed[range]), .checkbox)
        }

        return nil
    }

    private func removeMarker(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespaces)

        if let firstChar = trimmed.first,
           Self.bulletMarkers.contains(firstChar.unicodeScalars.first!) {
            return String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
        }

        for pattern in [Self.numberedPattern, Self.checkboxPattern] {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) {
                let endIndex = trimmed.index(trimmed.startIndex, offsetBy: match.range.upperBound)
                return String(trimmed[endIndex...])
            }
        }

        return text
    }

    private func buildList(items: [ListItem], type: ListType) -> List {
        let bounds = items.map(\.boundingBox).reduce(items[0].boundingBox) { $0.union($1) }
        return List(items: items, type: type, boundingBox: bounds)
    }
}
