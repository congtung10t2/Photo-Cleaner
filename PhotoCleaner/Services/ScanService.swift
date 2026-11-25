import Foundation

struct ScanService {
    private let library = PhotoLibraryService.shared
    private let duplicateDistanceThreshold = 4

    func scan(progress: @escaping (Double, String) -> Void) async -> ScanResult {
        let startedAt = Date()
        let assets = library.fetchAssets()
        let descriptors = assets.map { AssetDescriptor(asset: $0) }
        let assetsByID = Dictionary(uniqueKeysWithValues: descriptors.map { ($0.id, $0) })

        var photoHashes: [HashEntry] = []
        var junkIDs: [String] = []
        var shortVideoIDs: [String] = []
        var videoKeys: [String: [String]] = [:]

        let total = max(1, assets.count)

        for (index, asset) in assets.enumerated() {
            let descriptor = descriptors[index]

            if asset.mediaType == .video {
                if VideoRules.isShortClip(duration: asset.duration) {
                    shortVideoIDs.append(descriptor.id)
                }
                if let hash = await VideoAnalysisService.thumbnailHash(for: asset),
                   let key = VideoRules.duplicateKey(
                    width: asset.pixelWidth,
                    height: asset.pixelHeight,
                    duration: asset.duration,
                    hash: hash
                   ) {
                    videoKeys[key, default: []].append(descriptor.id)
                }
            } else if let image = await library.image(for: asset, targetSize: CGSize(width: 640, height: 640)) {
                let analysis = ImageAnalysisService.analyze(image)

                if let hash = analysis.hash {
                    photoHashes.append(HashEntry(id: descriptor.id, hash: hash))
                }

                if let cgImage = ImageAnalysisService.normalizedCGImage(from: image) {
                    let vision = JunkDetectionService.detect(cgImage: cgImage)
                    let signals = JunkRules.Signals(
                        topClassificationConfidence: vision.topClassificationConfidence,
                        contourCount: vision.contourCount,
                        luminanceStdDev: analysis.luminanceStandardDeviation,
                        meanLuminance: analysis.luminanceMean
                    )
                    if JunkRules.isJunk(signals) {
                        junkIDs.append(descriptor.id)
                    }
                }
            }

            if index % 4 == 0 || index == assets.count - 1 {
                let fraction = Double(index + 1) / Double(total)
                progress(fraction, "\(index + 1) of \(assets.count)")
            }
        }

        var groups: [IssueGroup] = []

        let duplicateSets = SimilarityGrouping.groups(entries: photoHashes, maxDistance: duplicateDistanceThreshold)
        for (index, ids) in duplicateSets.enumerated() {
            let items = ids.compactMap { assetsByID[$0] }.sorted(by: ScanService.qualitySort)
            guard items.count > 1 else { continue }
            groups.append(
                IssueGroup(
                    id: "duplicate-photos-\(index)",
                    category: .duplicatePhotos,
                    title: "Set \(index + 1)",
                    reason: "\(items.count) near-identical photos",
                    assets: items,
                    keepID: items.first?.id
                )
            )
        }

        if !junkIDs.isEmpty {
            groups.append(
                IssueGroup(
                    id: "junk-photos",
                    category: .junkPhotos,
                    title: "No detectable subject",
                    reason: "Blank, very dark or textureless frames",
                    assets: junkIDs.compactMap { assetsByID[$0] },
                    keepID: nil
                )
            )
        }

        if !shortVideoIDs.isEmpty {
            groups.append(
                IssueGroup(
                    id: "short-videos",
                    category: .shortVideos,
                    title: "Clips of one second or less",
                    reason: "Videos at or below \(Int(VideoRules.shortClipThreshold))s are usually accidental bursts",
                    assets: shortVideoIDs.compactMap { assetsByID[$0] },
                    keepID: nil
                )
            )
        }

        let duplicateVideoSets = videoKeys.values
            .filter { $0.count > 1 }
            .sorted { $0.count > $1.count }

        for (index, ids) in duplicateVideoSets.enumerated() {
            let items = ids.compactMap { assetsByID[$0] }.sorted(by: ScanService.qualitySort)
            guard items.count > 1 else { continue }
            groups.append(
                IssueGroup(
                    id: "duplicate-videos-\(index)",
                    category: .duplicateVideos,
                    title: "Set \(index + 1)",
                    reason: "\(items.count) clips with the same thumbnail, size and duration",
                    assets: items,
                    keepID: items.first?.id
                )
            )
        }

        return ScanResult(
            groups: groups,
            scannedAssetCount: assets.count,
            startedAt: startedAt,
            finishedAt: Date()
        )
    }

    private static func qualitySort(_ lhs: AssetDescriptor, _ rhs: AssetDescriptor) -> Bool {
        if lhs.pixelCount != rhs.pixelCount { return lhs.pixelCount > rhs.pixelCount }
        return (lhs.creationDate ?? .distantPast) < (rhs.creationDate ?? .distantPast)
    }
}
