import Photos

struct ScanService {
    private let library = PhotoLibraryService.shared

    func scan(assets: [PHAsset], progress: @escaping (Double, String) -> Void) async -> [AssetAnalysis] {
        let total = max(1, assets.count)
        var analyses: [AssetAnalysis] = []
        analyses.reserveCapacity(assets.count)

        for (index, asset) in assets.enumerated() {
            let descriptor = AssetDescriptor(asset: asset)

            var photoHash: UInt64?
            var junkScore: Double?
            var videoHash: UInt64?
            var videoKey: String?

            if asset.mediaType == .video {
                videoHash = await VideoAnalysisService.thumbnailHash(for: asset)
                videoKey = VideoRules.duplicateKey(
                    width: asset.pixelWidth,
                    height: asset.pixelHeight,
                    duration: asset.duration,
                    hash: videoHash
                )
            } else if let image = await library.image(for: asset, targetSize: CGSize(width: 640, height: 640)) {
                let analysis = ImageAnalysisService.analyze(image)
                photoHash = analysis.hash

                if let cgImage = ImageAnalysisService.normalizedCGImage(from: image) {
                    let vision = JunkDetectionService.detect(cgImage: cgImage)
                    let signals = JunkRules.Signals(
                        topClassificationConfidence: vision.topClassificationConfidence,
                        contourCount: vision.contourCount,
                        luminanceStdDev: analysis.luminanceStandardDeviation,
                        meanLuminance: analysis.luminanceMean
                    )
                    junkScore = JunkRules.score(signals)
                }
            }

            analyses.append(
                AssetAnalysis(
                    descriptor: descriptor,
                    photoHash: photoHash,
                    junkScore: junkScore,
                    videoHash: videoHash,
                    videoKey: videoKey
                )
            )

            if index % 4 == 0 || index == assets.count - 1 {
                let fraction = Double(index + 1) / Double(total)
                progress(fraction, "\(index + 1) of \(assets.count)")
            }
        }

        return analyses
    }
}
