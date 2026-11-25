import XCTest
@testable import PhotoCleaner

final class VideoRulesTests: XCTestCase {
    func testShortClipThresholdIncludesZeroAndOneSecond() {
        XCTAssertTrue(VideoRules.isShortClip(duration: 0))
        XCTAssertTrue(VideoRules.isShortClip(duration: 0.5))
        XCTAssertTrue(VideoRules.isShortClip(duration: 1.0))
        XCTAssertFalse(VideoRules.isShortClip(duration: 1.01))
        XCTAssertFalse(VideoRules.isShortClip(duration: .nan))
    }

    func testDuplicateKeyCombinesHashAndMetadata() {
        let key = VideoRules.duplicateKey(width: 1920, height: 1080, duration: 2.0, hash: 0x1f)

        XCTAssertEqual(key, "1f-1920x1080-20")
        XCTAssertNil(VideoRules.duplicateKey(width: 1, height: 1, duration: 1, hash: nil))
    }
}
