import Photos
import SwiftUI

@MainActor
final class ScanViewModel: ObservableObject {
    enum Phase {
        case idle
        case scanning(progress: Double, message: String)
        case done(ScanResult)
    }

    @Published private(set) var authorization: PHAuthorizationStatus = .notDetermined
    @Published private(set) var phase: Phase = .idle
    @Published var selectedCategory: ScanCategory = .duplicatePhotos
    @Published private(set) var selectedIDs: Set<String> = []
    @Published var alertMessage: String?

    private let library = PhotoLibraryService.shared
    private let scanService = ScanService()

    var canAccessLibrary: Bool {
        authorization == .authorized || authorization == .limited
    }

    var currentGroups: [IssueGroup] {
        guard case .done(let result) = phase else { return [] }
        return result.groups(for: selectedCategory)
    }

    var scannedCount: Int {
        guard case .done(let result) = phase else { return 0 }
        return result.scannedAssetCount
    }

    func checkAuthorization() async {
        authorization = library.currentAuthorization()
    }

    func requestAuthorization() async {
        authorization = await library.requestAuthorization()
    }

    func startScan() async {
        guard canAccessLibrary else { return }

        selectedIDs.removeAll()
        phase = .scanning(progress: 0, message: "Preparing your library…")

        let result = await scanService.scan { [weak self] progress, message in
            Task { @MainActor [weak self] in
                self?.phase = .scanning(progress: progress, message: message)
            }
        }

        phase = .done(result)

        if !result.groups.contains(where: { $0.category == selectedCategory }),
           let available = ScanCategory.allCases.first(where: { category in
            result.groups.contains { $0.category == category }
           }) {
            selectedCategory = available
        }
    }

    func isSelected(_ id: String) -> Bool {
        selectedIDs.contains(id)
    }

    func toggle(_ id: String) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    func toggleAll(in group: IssueGroup) {
        let ids = group.assets.map(\.id)
        if ids.allSatisfy({ selectedIDs.contains($0) }) {
            ids.forEach { selectedIDs.remove($0) }
        } else {
            ids.forEach { selectedIDs.insert($0) }
        }
    }

    func deleteSelected() async {
        guard case .done(let result) = phase else { return }

        let toDelete = currentGroups.flatMap(\.assets).filter { selectedIDs.contains($0.id) }
        guard !toDelete.isEmpty else { return }

        do {
            try await DeletionService.delete(toDelete)

            let deletedIDs = Set(toDelete.map(\.id))
            let remainingGroups = result.groups.compactMap { group -> IssueGroup? in
                var updated = group
                updated.assets.removeAll { deletedIDs.contains($0.id) }
                guard !updated.assets.isEmpty else { return nil }
                if let keepID = group.keepID, deletedIDs.contains(keepID) {
                    updated.keepID = updated.assets.first?.id
                }
                return updated
            }

            phase = .done(
                ScanResult(
                    groups: remainingGroups,
                    scannedAssetCount: max(0, result.scannedAssetCount - deletedIDs.count),
                    startedAt: result.startedAt,
                    finishedAt: Date()
                )
            )
            selectedIDs.removeAll()
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}
