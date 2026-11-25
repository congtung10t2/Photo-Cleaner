import SwiftUI

struct LibraryScannerView: View {
    @ObservedObject var viewModel: ScanViewModel

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.phase {
                case .idle:
                    StartScanView(viewModel: viewModel)
                case .scanning(let progress, let message):
                    ScanProgressView(progress: progress, message: message)
                case .done:
                    ResultsView(viewModel: viewModel)
                }
            }
            .navigationTitle("PhotoCleaner")
            .toolbar {
                if case .done = viewModel.phase {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Rescan") {
                            Task { await viewModel.startScan() }
                        }
                    }
                }
            }
        }
    }
}
