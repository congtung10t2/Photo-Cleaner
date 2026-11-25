import Foundation

enum ScanCategory: String, CaseIterable, Identifiable {
    case duplicatePhotos
    case junkPhotos
    case shortVideos
    case duplicateVideos

    var id: String { rawValue }

    var title: String {
        switch self {
        case .duplicatePhotos: "Duplicate Photos"
        case .junkPhotos: "Photos Without a Subject"
        case .shortVideos: "Very Short Videos"
        case .duplicateVideos: "Duplicate Videos"
        }
    }

    var symbolName: String {
        switch self {
        case .duplicatePhotos: "square.on.square"
        case .junkPhotos: "rectangle.slash"
        case .shortVideos: "video.slash"
        case .duplicateVideos: "video.badge.ellipsis"
        }
    }

    var detail: String {
        switch self {
        case .duplicatePhotos: "Near-identical shots grouped by perceptual hash."
        case .junkPhotos: "Blank or textureless frames with no detected subject."
        case .shortVideos: "Clips one second long or shorter."
        case .duplicateVideos: "Clips with matching thumbnail, size and duration."
        }
    }
}
