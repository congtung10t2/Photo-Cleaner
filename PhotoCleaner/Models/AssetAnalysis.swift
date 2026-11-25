import Photos

struct AssetAnalysis {
    let descriptor: AssetDescriptor
    let photoHash: UInt64?
    let junkScore: Double?
    let videoHash: UInt64?
    let videoKey: String?

    var isJunk: Bool {
        guard let junkScore else { return false }
        return junkScore >= JunkRules.junkThreshold
    }

    var isShortVideo: Bool {
        descriptor.isVideo && VideoRules.isShortClip(duration: descriptor.duration)
    }
}
