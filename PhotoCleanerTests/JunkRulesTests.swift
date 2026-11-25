import XCTest
@testable import PhotoCleaner

final class JunkRulesTests: XCTestCase {
    private func signals(
        confidence: Float = 0.9,
        contours: Int = 20,
        stdDev: Double = 45,
        mean: Double = 120
    ) -> JunkRules.Signals {
        JunkRules.Signals(
            topClassificationConfidence: confidence,
            contourCount: contours,
            luminanceStdDev: stdDev,
            meanLuminance: mean
        )
    }

    func testClearPhotoIsNotJunk() {
        XCTAssertFalse(JunkRules.isJunk(signals()))
    }

    func testFlatLowConfidenceFrameIsJunk() {
        let result = signals(confidence: 0.05, contours: 0, stdDev: 2, mean: 250)

        XCTAssertGreaterThanOrEqual(JunkRules.score(result), JunkRules.junkThreshold)
        XCTAssertTrue(JunkRules.isJunk(result))
    }

    func testScoreStaysWithinBounds() {
        let minimum = signals(confidence: 0, contours: 0, stdDev: 0, mean: 0)
        let maximum = signals(confidence: 1, contours: 100, stdDev: 255, mean: 255)

        XCTAssertLessThanOrEqual(JunkRules.score(minimum), 1)
        XCTAssertGreaterThanOrEqual(JunkRules.score(minimum), 0)
        XCTAssertLessThanOrEqual(JunkRules.score(maximum), 1)
    }
}
