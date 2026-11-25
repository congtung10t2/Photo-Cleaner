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

    @Published var selectedScopeOption: ScanScopeOption = .hundred
    @Published var customAmount = 100
    @Published var reviewBeforeDeleting = false

    private let library = PhotoLibraryService.shared
    private let scanService = ScanService()
    private let resultBuilder = ResultBuilder()

    private var allAssets: [PHAsset] = []
    private var scanOffset = 0
    private var analyses: [AssetAnalysis] = []
    private var scanStartedAt = Date()

    var activeScope: ScanScope {
        switch selectedScopeOption {
        case .hundred: return .batch(100)
        case .custom: return .batch(max(1, customAmount))
        case .full: return .full
        }
    }

    var hasMoreBatches: Bool {
        scanOffset < allAssets.count
    }

    var nextBatchSize: Int {
        guard let range = BatchPlanner.nextRange(
            totalCount: allAssets.count,
            offset: scanOffset,
            scope: activeScope
        ) else { return 0 }
        return range.count
    }

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
        analyses.removeAll()
        scanOffset = 0
        scanStartedAt = Date()
        allAssets = library.fetchAssets()

        phase = .scanning(progress: 0, message: "Preparing your library…")
        await scanNextRange(scope: activeScope)
    }

    func scanNextBatch() async {
        await scanNextRange(scope: activeScope)
    }

    func scanFullLibrary() async {
        selectedScopeOption = .full
        await scanNextRange(scope: .full)
    }

    private func scanNextRange(scope: ScanScope) async {
        guard let range = BatchPlanner.nextRange(
            totalCount: allAssets.count,
            offset: scanOffset,
            scope: scope
        ) else {
            publishResult()
            return
        }

        phase = .scanning(progress: 0, message: "Analyzing \(range.count) items…")

        let batch = Array(allAssets[range])
        let newAnalyses = await scanService.scan(assets: batch) { [weak self] progress, message in
            Task { @MainActor [weak self] in
                self?.phase = .scanning(progress: progress, message: message)
            }
        }

        analyses.append(contentsOf: newAnalyses)
        scanOffset = range.upperBound
        publishResult()
    }

    private func publishResult() {
        let result = resultBuilder.build(
            analyses: analyses,
            scannedAssetCount: analyses.count,
            startedAt: scanStartedAt
        )
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

    func clearSelection() {
        selectedIDs.removeAll()
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
        await delete(ids: selectedIDs)
    }

    func delete(ids: Set<String>) async {
        guard case .done(let result) = phase else { return }

        let toDelete = analyses.filter { ids.contains($0.descriptor.id) }.map(\.descriptor)
        guard !toDelete.isEmpty else { return }

        do {
            try await DeletionService.delete(toDelete)

            let deletedIDs = Set(toDelete.map(\.id))
            analyses.removeAll { deletedIDs.contains($0.descriptor.id) }

            let updatedResult = resultBuilder.build(
                analyses: analyses,
                scannedAssetCount: max(0, result.scannedAssetCount - deletedIDs.count),
                startedAt: result.startedAt
            )
            phase = .done(updatedResult)
            selectedIDs.subtract(deletedIDs)
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}
