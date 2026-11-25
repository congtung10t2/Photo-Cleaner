import AVFoundation
import Photos
import UIKit

enum VideoAnalysisService {
    static func thumbnailHash(for asset: PHAsset) async -> UInt64? {
        guard let image = await thumbnail(for: asset) else { return nil }
        return ImageAnalysisService.analyze(image).hash
    }

    static func thumbnail(for asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.deliveryMode = .fastFormat
            options.isNetworkAccessAllowed = true

            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                guard let avAsset else {
                    continuation.resume(returning: nil)
                    return
                }

                let generator = AVAssetImageGenerator(asset: avAsset)
                generator.appliesPreferredTrackTransform = true
                generator.maximumSize = CGSize(width: 320, height: 320)
                let seconds = min(0.5, max(0, asset.duration))
                let time = CMTime(seconds: seconds, preferredTimescale: 600)

                do {
                    let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                    continuation.resume(returning: UIImage(cgImage: cgImage))
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
