import Foundation

enum VideoRules {
    static let shortClipThreshold: TimeInterval = 1.0

    static func isShortClip(duration: TimeInterval) -> Bool {
        duration.isFinite && duration >= 0 && duration <= shortClipThreshold
    }

    static func duplicateKey(width: Int, height: Int, duration: TimeInterval, hash: UInt64?) -> String? {
        guard let hash else { return nil }
        let tenths = Int((duration * 10).rounded())
        return String(format: "%llx-%dx%d-%d", hash, width, height, tenths)
    }
}
