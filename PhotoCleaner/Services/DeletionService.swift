import Photos

enum DeletionError: Error {
    case failed
}

enum DeletionService {
    static func delete(_ descriptors: [AssetDescriptor]) async throws {
        guard !descriptors.isEmpty else { return }

        try await withCheckedThrowingContinuation { continuation in
            let assets = descriptors.map(\.asset) as NSArray
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(assets)
            }, completionHandler: { succeeded, error in
                if succeeded {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? DeletionError.failed)
                }
            })
        }
    }
}
