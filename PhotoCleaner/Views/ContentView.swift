import Photos
import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = ScanViewModel()

    var body: some View {
        Group {
            if viewModel.canAccessLibrary {
                LibraryScannerView(viewModel: viewModel)
            } else {
                PermissionView(
                    isDenied: viewModel.authorization == .denied || viewModel.authorization == .restricted,
                    action: { await handlePermissionAction() }
                )
            }
        }
        .task { await viewModel.checkAuthorization() }
        .alert("Couldn't Delete", isPresented: deleteErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }

    @MainActor
    private func handlePermissionAction() async {
        let denied = viewModel.authorization == .denied || viewModel.authorization == .restricted
        if denied {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            await UIApplication.shared.open(url)
        } else {
            await viewModel.requestAuthorization()
        }
    }

    private var deleteErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.alertMessage != nil },
            set: { if !$0 { viewModel.alertMessage = nil } }
        )
    }
}
