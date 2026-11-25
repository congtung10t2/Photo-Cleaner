import Photos
import SwiftUI
import UIKit

struct FullScreenAssetView: View {
    let asset: PHAsset
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .overlay(alignment: .bottom) {
            if asset.mediaType == .video {
                Label("Video · \(String(format: "%.1f", asset.duration))s", systemImage: "video.fill")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.65), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(.bottom, 16)
            }
        }
        .task {
            let size = CGSize(width: 1600, height: 1600)
            image = await PhotoLibraryService.shared.image(for: asset, targetSize: size)
        }
    }
}
