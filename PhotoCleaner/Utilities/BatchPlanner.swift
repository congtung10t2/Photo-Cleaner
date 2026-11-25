import Foundation

enum BatchPlanner {
    static func nextRange(totalCount: Int, offset: Int, scope: ScanScope) -> Range<Int>? {
        guard totalCount > 0, offset >= 0, offset < totalCount else { return nil }

        let end: Int
        switch scope {
        case .full:
            end = totalCount
        case .batch(let count):
            end = min(totalCount, offset + max(1, count))
        }

        guard end > offset else { return nil }
        return offset..<end
    }
}
