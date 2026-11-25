import Foundation

struct ResultBuilder {
    private let duplicateDistanceThreshold = 4

    func build(analyses: [AssetAnalysis], scannedAssetCount: Int, startedAt: Date) -> ScanResult {
        var seenIDs = Set<String>()
        let unique = analyses.filter { seenIDs.insert($0.descriptor.id).inserted }
        let assetsByID = Dictionary(uniqueKeysWithValues: unique.map { ($0.descriptor.id, $0.descriptor) })

        var photoHashes: [HashEntry] = []
        var junkIDs: [String] = []
        var shortVideoIDs: [String] = []
        var videoKeys: [String: [String]] = [:]

        for analysis in unique {
            if let hash = analysis.photoHash {
                photoHashes.append(HashEntry(id: analysis.descriptor.id, hash: hash))
            }
            if analysis.isJunk {
                junkIDs.append(analysis.descriptor.id)
            }
            if analysis.isShortVideo {
                shortVideoIDs.append(analysis.descriptor.id)
            }
            if let key = analysis.videoKey {
                videoKeys[key, default: []].append(analysis.descriptor.id)
            }
        }

        var groups: [IssueGroup] = []

        let duplicateSets = SimilarityGrouping.groups(entries: photoHashes, maxDistance: duplicateDistanceThreshold)
        for (index, ids) in duplicateSets.enumerated() {
            let items = ids.compactMap { assetsByID[$0] }.sorted(by: ResultBuilder.qualitySort)
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
            let items = ids.compactMap { assetsByID[$0] }.sorted(by: ResultBuilder.qualitySort)
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
            scannedAssetCount: scannedAssetCount,
            startedAt: startedAt,
            finishedAt: Date()
        )
    }

    private static func qualitySort(_ lhs: AssetDescriptor, _ rhs: AssetDescriptor) -> Bool {
        if lhs.pixelCount != rhs.pixelCount { return lhs.pixelCount > rhs.pixelCount }
        return (lhs.creationDate ?? .distantPast) < (rhs.creationDate ?? .distantPast)
    }
}
