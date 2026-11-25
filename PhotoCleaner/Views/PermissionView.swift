import SwiftUI

struct PermissionView: View {
    let isDenied: Bool
    let action: () async -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: isDenied ? "lock.photos" : "photo.stack")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text(isDenied ? "Photo Access Is Off" : "Clean Up Your Library")
                .font(.title.bold())

            Text(isDenied
                 ? "Enable photo library access in Settings so PhotoCleaner can find duplicates, empty shots and short clips."
                 : "PhotoCleaner scans on your device for duplicate photos, photos with no clear subject, duplicate videos and clips one second or shorter.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button {
                Task { await action() }
            } label: {
                Text(isDenied ? "Open Settings" : "Allow Photo Access")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
        }
        .padding()
    }
}
