import Photos
import SwiftUI
import UIKit

struct AssetThumbnailView: View {
    let asset: PHAsset
    let side: CGFloat

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.2)
                ProgressView()
                    .controlSize(.small)
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .task {
            let size = CGSize(width: side * 2, height: side * 2)
            image = await PhotoLibraryService.shared.image(for: asset, targetSize: size)
        }
    }
}
