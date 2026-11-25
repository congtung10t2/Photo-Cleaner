import SwiftData
import SwiftUI

@main
struct PhotoCleanerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: ScannedAsset.self)
    }
}
