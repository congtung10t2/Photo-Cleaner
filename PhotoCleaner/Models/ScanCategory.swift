import Foundation

enum ScanCategory: String, CaseIterable, Identifiable {
    case allIssues
    case duplicatePhotos
    case junkPhotos
    case shortVideos
    case duplicateVideos

    var id: String { rawValue }

    static var issueTypes: [ScanCategory] {
        allCases.filter { $0 != .allIssues }
    }

    var title: String {
        switch self {
        case .allIssues: "All Issues"
        case .duplicatePhotos: "Duplicate Photos"
        case .junkPhotos: "Photos Without a Subject"
        case .shortVideos: "Very Short Videos"
        case .duplicateVideos: "Duplicate Videos"
        }
    }

    var symbolName: String {
        switch self {
        case .allIssues: "exclamationmark.triangle"
        case .duplicatePhotos: "square.on.square"
        case .junkPhotos: "rectangle.slash"
        case .shortVideos: "video.slash"
        case .duplicateVideos: "video.badge.ellipsis"
        }
    }

    var detail: String {
        switch self {
        case .allIssues: "Every flagged photo and video in one place, grouped by issue type."
        case .duplicatePhotos: "Near-identical shots grouped by perceptual hash."
        case .junkPhotos: "Blank or textureless frames with no detected subject."
        case .shortVideos: "Clips one second long or shorter."
        case .duplicateVideos: "Clips with matching thumbnail, size and duration."
        }
    }

    var emptyStateTitle: String {
        switch self {
        case .allIssues: "No issues found"
        default: "No \(title.lowercased()) found"
        }
    }
}
