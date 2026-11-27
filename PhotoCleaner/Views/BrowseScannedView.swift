import SwiftUI

struct BrowseScannedView: View {
    @ObservedObject var viewModel: ScanViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var isDeleting = false

    private var items: [AssetDescriptor] { viewModel.lastBatchAssets }

    private var currentItem: AssetDescriptor? {
        items.indices.contains(index) ? items[index] : nil
    }

    private var isScanningNext: Bool {
        if case .scanning = viewModel.phase { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Group {
                if isScanningNext, case .scanning(let progress, let message) = viewModel.phase {
                    ScanProgressView(progress: progress, message: message)
                } else if let item = currentItem {
                    reviewView(for: item)
                } else {
                    finishedView
                }
            }
            .navigationTitle(isScanningNext ? "Scanning…" : (currentItem == nil ? "All Done" : "Browse \(index + 1) of \(items.count)"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .alert("Couldn't Delete", isPresented: deleteErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }

    private func reviewView(for item: AssetDescriptor) -> some View {
        VStack(spacing: 12) {
            FullScreenAssetView(asset: item.asset)
                .id(item.id)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)

            if viewModel.flaggedIDs.contains(item.id) {
                Label("Flagged", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.orange.opacity(0.9), in: Capsule())
                    .foregroundStyle(.white)
            }

            HStack(spacing: 48) {
                Button {
                    move(-1)
                } label: {
                    Label("Previous", systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 22, weight: .bold))
                        .frame(width: 64, height: 56)
                }
                .buttonStyle(.bordered)
                .disabled(index == 0 || isDeleting)

                decisionButton(title: "Remove", systemImage: "xmark", tint: .red) {
                    Task { await removeCurrent() }
                }
                .disabled(isDeleting)

                Button {
                    move(1)
                } label: {
                    Label("Next", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 22, weight: .bold))
                        .frame(width: 64, height: 56)
                }
                .buttonStyle(.bordered)
                .disabled(index >= items.count - 1 || isDeleting)
            }
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private func decisionButton(
        title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .bold))
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .frame(width: 92, height: 82)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
    }

    private var finishedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Batch reviewed")
                .font(.title2.bold())

            Text(viewModel.hasMoreBatches
                 ? "Remove what you don't want, then scan the next batch."
                 : "Every scanned picture in this batch has been reviewed.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if viewModel.hasMoreBatches {
                Button {
                    Task { await scanNextBatch() }
                } label: {
                    Label("Scan & Browse next \(viewModel.browseBatchSize)", systemImage: "photo.stack")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isDeleting)
                .padding(.horizontal, 40)
            }

            Button("Done") { dismiss() }
        }
        .padding()
    }

    private func move(_ offset: Int) {
        let newIndex = index + offset
        guard items.indices.contains(newIndex) else { return }
        index = newIndex
    }

    private func removeCurrent() async {
        guard let item = currentItem, !isDeleting else { return }
        isDeleting = true
        await viewModel.delete(ids: [item.id])
        isDeleting = false
        guard viewModel.alertMessage == nil else { return }
        clampIndex()
    }

    private func clampIndex() {
        if items.isEmpty {
            index = 0
        } else {
            index = min(index, items.count - 1)
        }
    }

    private func scanNextBatch() async {
        guard !isDeleting else { return }
        await viewModel.scanNextBatchAndBrowse()
        index = 0
    }

    private var deleteErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.alertMessage != nil },
            set: { if !$0 { viewModel.alertMessage = nil } }
        )
    }
}
