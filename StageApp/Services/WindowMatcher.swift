import Foundation

struct WindowMatch: Equatable, Sendable {
    var capturedIndex: Int
    var liveIndex: Int
}

enum WindowMatcher {
    static func match(capturedTitles: [String], liveTitles: [String]) -> [WindowMatch] {
        var pairs: [WindowMatch] = []
        var usedCaptured = Set<Int>()
        var usedLive = Set<Int>()

        let capturedKeys = capturedTitles.map(normalize)
        let liveKeys = liveTitles.map(normalize)
        var liveBuckets: [String: [Int]] = [:]
        for (index, key) in liveKeys.enumerated() where !key.isEmpty {
            liveBuckets[key, default: []].append(index)
        }

        for (index, key) in capturedKeys.enumerated() where !key.isEmpty {
            guard let bucket = liveBuckets[key], bucket.count == 1, capturedKeys.filter({ $0 == key }).count == 1 else { continue }
            let liveIndex = bucket[0]
            pairs.append(WindowMatch(capturedIndex: index, liveIndex: liveIndex))
            usedCaptured.insert(index)
            usedLive.insert(liveIndex)
        }

        var remainingCaptured = capturedTitles.indices.filter { !usedCaptured.contains($0) }
        var remainingLive = liveTitles.indices.filter { !usedLive.contains($0) }
        while !remainingCaptured.isEmpty && !remainingLive.isEmpty {
            var best: (captured: Int, live: Int, score: Double)?
            for captured in remainingCaptured {
                for live in remainingLive {
                    let score = similarity(capturedTitles[captured], liveTitles[live])
                    if score >= 0.55, best == nil || score > best!.score {
                        best = (captured, live, score)
                    }
                }
            }
            guard let best else { break }
            pairs.append(WindowMatch(capturedIndex: best.captured, liveIndex: best.live))
            remainingCaptured.removeAll { $0 == best.captured }
            remainingLive.removeAll { $0 == best.live }
        }

        return pairs.sorted { $0.capturedIndex < $1.capturedIndex }
    }

    private static func normalize(_ title: String) -> String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func similarity(_ lhs: String, _ rhs: String) -> Double {
        let left = Set(normalize(lhs).split(separator: " ").map(String.init))
        let right = Set(normalize(rhs).split(separator: " ").map(String.init))
        if left.isEmpty || right.isEmpty { return 0 }
        let overlap = Double(left.intersection(right).count)
        return overlap / Double(max(left.count, right.count))
    }
}
