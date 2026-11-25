import Foundation
import SwiftData

@Model
final class ScannedAsset {
    @Attribute(.unique) var id: String
    var scannedAt: Date

    init(id: String, scannedAt: Date = Date()) {
        self.id = id
        self.scannedAt = scannedAt
    }
}
