import Foundation

enum Fingerprint {
    static func hammingDistance(_ lhs: UInt64, _ rhs: UInt64) -> Int {
        (lhs ^ rhs).nonzeroBitCount
    }
}

struct HashEntry {
    let id: String
    let hash: UInt64
}

enum SimilarityGrouping {
    private struct BlockKey: Hashable {
        let block: Int
        let value: UInt64
    }

    static func groups(entries: [HashEntry], maxDistance: Int) -> [[String]] {
        let count = entries.count
        guard count > 1, maxDistance >= 0 else { return [] }

        var parent = Array(0..<count)
        var size = Array(repeating: 1, count: count)

        func root(_ index: Int) -> Int {
            var current = index
            while parent[current] != current {
                parent[current] = parent[parent[current]]
                current = parent[current]
            }
            return current
        }

        func union(_ a: Int, _ b: Int) {
            let rootA = root(a)
            let rootB = root(b)
            guard rootA != rootB else { return }
            if size[rootA] < size[rootB] {
                parent[rootA] = rootB
                size[rootB] += size[rootA]
            } else {
                parent[rootB] = rootA
                size[rootA] += size[rootB]
            }
        }

        func compare(_ a: Int, _ b: Int) {
            if Fingerprint.hammingDistance(entries[a].hash, entries[b].hash) <= maxDistance {
                union(a, b)
            }
        }

        if maxDistance < 64 {
            let blockCount = maxDistance + 1
            let baseWidth = 64 / blockCount
            let remainder = 64 % blockCount
            var buckets: [BlockKey: [Int]] = [:]
            var shift = 0

            for block in 0..<blockCount {
                let width = baseWidth + (block < remainder ? 1 : 0)
                let mask: UInt64 = width >= 64 ? UInt64.max : (1 << width) - 1

                for index in 0..<count {
                    let key = BlockKey(block: block, value: (entries[index].hash >> shift) & mask)
                    buckets[key, default: []].append(index)
                }
                shift += width
            }

            for indices in buckets.values where indices.count > 1 {
                for i in 0..<indices.count {
                    for j in (i + 1)..<indices.count {
                        compare(indices[i], indices[j])
                    }
                }
            }
        } else {
            for i in 0..<count {
                for j in (i + 1)..<count {
                    compare(i, j)
                }
            }
        }

        var groupedIDs: [Int: [String]] = [:]
        for index in 0..<count {
            groupedIDs[root(index), default: []].append(entries[index].id)
        }

        return groupedIDs.values
            .filter { $0.count > 1 }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.first ?? "" < rhs.first ?? ""
            }
    }
}
