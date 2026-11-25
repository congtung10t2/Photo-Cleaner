import XCTest
@testable import PhotoCleaner

final class ScanResultFilteringTests: XCTestCase {
    private func makeGroup(id: String, category: ScanCategory) -> IssueGroup {
        IssueGroup(
            id: id,
            category: category,
            title: id,
            reason: "test",
            assets: [],
            keepID: nil
        )
    }

    func testAllIssuesReturnsEveryGroup() {
        let groups = [
            makeGroup(id: "duplicates", category: .duplicatePhotos),
            makeGroup(id: "junk", category: .junkPhotos),
            makeGroup(id: "short", category: .shortVideos)
        ]
        let result = ScanResult(
            groups: groups,
            scannedAssetCount: 0,
            startedAt: Date(),
            finishedAt: Date()
        )

        XCTAssertEqual(result.groups(for: .allIssues).map(\.id), groups.map(\.id))
    }

    func testSpecificCategoriesStillFilterGroups() {
        let groups = [
            makeGroup(id: "duplicates", category: .duplicatePhotos),
            makeGroup(id: "junk", category: .junkPhotos)
        ]
        let result = ScanResult(
            groups: groups,
            scannedAssetCount: 0,
            startedAt: Date(),
            finishedAt: Date()
        )

        XCTAssertEqual(result.groups(for: .junkPhotos).map(\.id), ["junk"])
        XCTAssertTrue(result.groups(for: .duplicateVideos).isEmpty)
    }

    func testIssueTypesExcludeAggregateCategory() {
        XCTAssertFalse(ScanCategory.issueTypes.contains(.allIssues))
        XCTAssertEqual(ScanCategory.issueTypes.count, ScanCategory.allCases.count - 1)
    }
}
