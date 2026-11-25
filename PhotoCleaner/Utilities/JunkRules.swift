import Foundation

enum JunkRules {
    struct Signals {
        let topClassificationConfidence: Float
        let contourCount: Int
        let luminanceStdDev: Double
        let meanLuminance: Double
    }

    static let junkThreshold = 0.55

    static func score(_ signals: Signals) -> Double {
        var score = 0.0

        let confidence = Double(signals.topClassificationConfidence)
        if confidence < 0.30 {
            score += (0.30 - confidence) / 0.30 * 0.45
        }

        if signals.contourCount < 4 {
            score += 0.25
        }

        if signals.luminanceStdDev < 14 {
            score += (14 - signals.luminanceStdDev) / 14 * 0.30
        }

        if signals.meanLuminance < 10 || signals.meanLuminance > 245 {
            score += 0.15
        }

        return min(1, max(0, score))
    }

    static func isJunk(_ signals: Signals) -> Bool {
        score(signals) >= junkThreshold
    }
}
