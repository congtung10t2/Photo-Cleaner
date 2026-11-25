import SwiftUI

struct LibraryScannerView: View {
    @ObservedObject var viewModel: ScanViewModel
    @State private var showingRestartConfirmation = false

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
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Restart") { showingRestartConfirmation = true }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Scan New") {
                            Task { await viewModel.startScan() }
                        }
                    }
                }
            }
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
}
