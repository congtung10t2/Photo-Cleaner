import UIKit

struct ImageAnalysis {
    let hash: UInt64?
    let luminanceMean: Double
    let luminanceStandardDeviation: Double
}

enum ImageAnalysisService {
    static func analyze(_ image: UIImage) -> ImageAnalysis {
        guard let cgImage = normalizedCGImage(from: image) else {
            return ImageAnalysis(hash: nil, luminanceMean: 0, luminanceStandardDeviation: 0)
        }

        let hashPixels = pixels(from: cgImage, width: 9, height: 8)
        let statsPixels = pixels(from: cgImage, width: 32, height: 32)

        return ImageAnalysis(
            hash: hashPixels.flatMap { differenceHash(from: $0) },
            luminanceMean: meanLuminance(from: statsPixels),
            luminanceStandardDeviation: standardDeviation(from: statsPixels)
        )
    }

    static func normalizedCGImage(from image: UIImage) -> CGImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }.cgImage
    }

    private static func pixels(from cgImage: CGImage, width: Int, height: Int) -> [UInt8]? {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return nil }
        return Array(UnsafeBufferPointer(start: data.assumingMemoryBound(to: UInt8.self), count: width * height * 4))
    }

    private static func luminance(_ red: UInt8, _ green: UInt8, _ blue: UInt8) -> Double {
        0.299 * Double(red) + 0.587 * Double(green) + 0.114 * Double(blue)
    }

    private static func differenceHash(from pixels: [UInt8]) -> UInt64? {
        let width = 9
        let height = 8
        guard pixels.count >= width * height * 4 else { return nil }

        var result: UInt64 = 0
        for row in 0..<height {
            for column in 0..<(width - 1) {
                let index = (row * width + column) * 4
                let nextIndex = index + 4
                let current = luminance(pixels[index], pixels[index + 1], pixels[index + 2])
                let next = luminance(pixels[nextIndex], pixels[nextIndex + 1], pixels[nextIndex + 2])
                result = (result << 1) | (current > next ? 1 : 0)
            }
        }
        return result
    }

    private static func meanLuminance(from pixels: [UInt8]?) -> Double {
        guard let pixels, !pixels.isEmpty else { return 0 }
        let values = stride(from: 0, to: pixels.count, by: 4).map { offset in
            luminance(pixels[offset], pixels[offset + 1], pixels[offset + 2])
        }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func standardDeviation(from pixels: [UInt8]?) -> Double {
        guard let pixels, !pixels.isEmpty else { return 0 }
        let values = stride(from: 0, to: pixels.count, by: 4).map { offset in
            luminance(pixels[offset], pixels[offset + 1], pixels[offset + 2])
        }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0.0) { $0 + pow($1 - mean, 2) } / Double(values.count)
        return sqrt(variance)
    }
}
