import XCTest
@testable import PhotoCleaner

final class FingerprintTests: XCTestCase {
    func testHammingDistanceCountsDifferingBits() {
        XCTAssertEqual(Fingerprint.hammingDistance(0b0000, 0b0000), 0)
        XCTAssertEqual(Fingerprint.hammingDistance(0b0000, 0b1111), 4)
        XCTAssertEqual(Fingerprint.hammingDistance(0b1010, 0b0011), 2)
    }

    func testGroupsNearIdenticalHashesAndKeepsSingletonsOut() {
        let entries = [
            HashEntry(id: "a", hash: 0b0000),
            HashEntry(id: "b", hash: 0b0001),
            HashEntry(id: "c", hash: 0b1111),
            HashEntry(id: "d", hash: 0b1110)
        ]

        let groups = SimilarityGrouping.groups(entries: entries, maxDistance: 1)

        XCTAssertEqual(groups.count, 2)
        XCTAssertTrue(groups.contains { Set($0) == Set(["a", "b"]) })
        XCTAssertTrue(groups.contains { Set($0) == Set(["c", "d"]) })
    }

    func testGroupsHashesWithFourDifferencesAcrossBlocks() {
        let fourDifferences: UInt64 = (1 << 0) | (1 << 13) | (1 << 26) | (1 << 39)
        let entries = [
            HashEntry(id: "a", hash: 0),
            HashEntry(id: "b", hash: fourDifferences),
            HashEntry(id: "c", hash: UInt64.max)
        ]

        let groups = SimilarityGrouping.groups(entries: entries, maxDistance: 4)

        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(Set(groups[0]), Set(["a", "b"]))
    }

    func testGroupsLargestSetFirst() {
        let entries = [
            HashEntry(id: "a", hash: 0),
            HashEntry(id: "b", hash: 1),
            HashEntry(id: "c", hash: 2),
            HashEntry(id: "d", hash: 100)
        ]

        let groups = SimilarityGrouping.groups(entries: entries, maxDistance: 2)

        XCTAssertEqual(groups.first?.count, 3)
    }
}
