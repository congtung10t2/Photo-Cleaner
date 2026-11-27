import SwiftUI

struct StartScanView: View {
    @ObservedObject var viewModel: ScanViewModel
    @State private var showingRestartConfirmation = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: "photo.stack")
                .font(.system(size: 72))
                .foregroundStyle(.tint)

            Text("Find what's worth deleting")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 14) {
                ForEach(ScanCategory.issueTypes) { category in
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.title)
                                .font(.subheadline.weight(.semibold))
                            Text(category.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: category.symbolName)
                            .foregroundStyle(.tint)
                    }
                }
            }
            .frame(maxWidth: 420, alignment: .leading)

            ScanScopeSelector(viewModel: viewModel)

            if viewModel.scannedHistoryCount > 0 {
                Text("\(viewModel.scannedHistoryCount) items already scanned. Only new items will be checked.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await viewModel.startScan() }
            } label: {
                Label("Scan \(viewModel.activeScope.label)", systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 8) {
                Text("Scan & Browse")
                    .font(.headline)

                Picker("Batch size", selection: $viewModel.browseBatchSize) {
                    Text("10").tag(10)
                    Text("20").tag(20)
                }
                .pickerStyle(.segmented)

                Button {
                    Task { await viewModel.startScanAndBrowse(batchSize: viewModel.browseBatchSize) }
                } label: {
                    Label("Scan & Browse \(viewModel.browseBatchSize)", systemImage: "photo.stack")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Text("Scans a small batch and opens every picture so you can remove anything while reviewing, then scan the next batch.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 40)

            Button {
                showingRestartConfirmation = true
            } label: {
                Label("Restart scanning", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Text("Analysis happens entirely on this device.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .confirmationDialog("Restart scanning?", isPresented: $showingRestartConfirmation, titleVisibility: .visible) {
            Button("Restart", role: .destructive) {
                Task { await viewModel.restartScanning() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Previously scanned items will be checked again.")
        }
    }
}
