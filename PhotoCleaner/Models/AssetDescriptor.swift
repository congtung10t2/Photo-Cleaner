import Photos

struct AssetDescriptor: Identifiable, Hashable {
    let asset: PHAsset

    var id: String { asset.localIdentifier }
    var isVideo: Bool { asset.mediaType == .video }
    var creationDate: Date? { asset.creationDate }
    var duration: TimeInterval { asset.duration }
    var pixelCount: Int { asset.pixelWidth * asset.pixelHeight }

    static func == (lhs: AssetDescriptor, rhs: AssetDescriptor) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
