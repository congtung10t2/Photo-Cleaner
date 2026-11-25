import XCTest
@testable import PhotoCleaner

final class BatchPlannerTests: XCTestCase {
    func testFirstBatch() {
        XCTAssertEqual(BatchPlanner.nextRange(totalCount: 250, offset: 0, scope: .batch(100)), 0..<100)
    }

    func testContinuesFromOffset() {
        XCTAssertEqual(BatchPlanner.nextRange(totalCount: 250, offset: 100, scope: .batch(100)), 100..<200)
    }

    func testFinalBatchStopsAtTotal() {
        XCTAssertEqual(BatchPlanner.nextRange(totalCount: 250, offset: 200, scope: .batch(100)), 200..<250)
        XCTAssertNil(BatchPlanner.nextRange(totalCount: 250, offset: 250, scope: .batch(100)))
    }

    func testFullLibraryScansEverythingRemaining() {
        XCTAssertEqual(BatchPlanner.nextRange(totalCount: 250, offset: 40, scope: .full), 40..<250)
    }

    func testInvalidBatchSizeFallsBackToOne() {
        XCTAssertEqual(BatchPlanner.nextRange(totalCount: 10, offset: 0, scope: .batch(0)), 0..<1)
    }
}
