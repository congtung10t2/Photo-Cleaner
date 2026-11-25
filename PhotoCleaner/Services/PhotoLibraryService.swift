import Photos
import UIKit

final class PhotoLibraryService {
    static let shared = PhotoLibraryService()

    private init() {}

    func currentAuthorization() -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status)
            }
        }
    }

    func fetchAssets() -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.includeHiddenAssets = false

        let fetchResult = PHAsset.fetchAssets(with: options)
        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            if asset.mediaType == .image || asset.mediaType == .video {
                assets.append(asset)
            }
        }
        return assets
    }

    func image(for asset: PHAsset, targetSize: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            options.isNetworkAccessAllowed = true

            let lock = NSLock()
            var resumed = false

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                lock.lock()
                guard !resumed else {
                    lock.unlock()
                    return
                }
                resumed = true
                lock.unlock()
                continuation.resume(returning: image)
            }
        }
    }
}
