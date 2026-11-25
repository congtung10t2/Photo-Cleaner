import Foundation

struct IssueGroup: Identifiable {
    let id: String
    let category: ScanCategory
    let title: String
    let reason: String
    var assets: [AssetDescriptor]
    var keepID: String?

    var isDuplicateGroup: Bool {
        category == .duplicatePhotos || category == .duplicateVideos
    }
}

struct ScanResult {
    let groups: [IssueGroup]
    let scannedAssetCount: Int
    let startedAt: Date
    let finishedAt: Date

    func groups(for category: ScanCategory) -> [IssueGroup] {
        groups.filter { $0.category == category }
    }

    func count(for category: ScanCategory) -> Int {
        groups(for: category).reduce(0) { $0 + $1.assets.count }
    }
}
