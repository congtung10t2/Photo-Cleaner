import Foundation

enum ScanScope: Equatable {
    case batch(Int)
    case full

    var label: String {
        switch self {
        case .batch(let count): "\(count) items"
        case .full: "Full library"
        }
    }
}

enum ScanScopeOption: String, CaseIterable, Identifiable {
    case hundred
    case custom
    case full

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hundred: "100 items"
        case .custom: "Custom amount"
        case .full: "Full library"
        }
    }
}
