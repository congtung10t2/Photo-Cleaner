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
    static func groups(entries: [HashEntry], maxDistance: Int) -> [[String]] {
        let count = entries.count
        guard count > 1 else { return [] }

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

        for i in 0..<count {
            for j in (i + 1)..<count {
                if Fingerprint.hammingDistance(entries[i].hash, entries[j].hash) <= maxDistance {
                    union(i, j)
                }
            }
        }

        var buckets: [Int: [String]] = [:]
        for index in 0..<count {
            buckets[root(index), default: []].append(entries[index].id)
        }

        return buckets.values
            .filter { $0.count > 1 }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.first ?? "" < rhs.first ?? ""
            }
    }
}
