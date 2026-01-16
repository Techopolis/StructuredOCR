import Foundation
import Vision
import CoreGraphics

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

/// Wraps Vision framework's text recognition capabilities.
public actor TextRecognizer {
    /// Recognition level - fast or accurate
    public enum RecognitionLevel: Sendable {
        case fast
        case accurate
    }

    /// Languages to recognize (ISO language codes)
    public var languages: [String]

    /// Recognition level
    public var recognitionLevel: RecognitionLevel

    /// Minimum confidence threshold for results
    public var minimumConfidence: Float

    public init(
        languages: [String] = ["en-US"],
        recognitionLevel: RecognitionLevel = .accurate,
        minimumConfidence: Float = 0.0
    ) {
        self.languages = languages
        self.recognitionLevel = recognitionLevel
        self.minimumConfidence = minimumConfidence
    }

    /// Recognize text in a CGImage
    public func recognize(image: CGImage) async throws -> [TextBlock] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let blocks = observations.compactMap { observation -> TextBlock? in
                    guard let candidate = observation.topCandidates(1).first else {
                        return nil
                    }

                    let confidence = candidate.confidence
                    guard confidence >= self.minimumConfidence else {
                        return nil
                    }

                    return TextBlock(
                        text: candidate.string,
                        boundingBox: BoundingBox(cgRect: observation.boundingBox),
                        confidence: confidence
                    )
                }

                continuation.resume(returning: blocks)
            }

            request.recognitionLevel = recognitionLevel == .accurate ? .accurate : .fast
            request.recognitionLanguages = languages
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: image, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Recognize text from image data
    public func recognize(data: Data) async throws -> [TextBlock] {
        guard let image = createCGImage(from: data) else {
            throw TextRecognitionError.invalidImageData
        }
        return try await recognize(image: image)
    }

    /// Recognize text from a file URL
    public func recognize(url: URL) async throws -> [TextBlock] {
        let data = try Data(contentsOf: url)
        return try await recognize(data: data)
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

/// Errors that can occur during text recognition.
public enum TextRecognitionError: Error, Sendable {
    case invalidImageData
    case recognitionFailed(String)
    case unsupportedPlatform
}
