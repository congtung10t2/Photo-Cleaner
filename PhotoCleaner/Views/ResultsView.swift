import SwiftUI

struct ResultsView: View {
    @ObservedObject var viewModel: ScanViewModel
    @State private var showingDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("Issue type", selection: $viewModel.selectedCategory) {
                ForEach(ScanCategory.allCases) { category in
                    Text(category.title).tag(category)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)

            Text("Scanned \(viewModel.scannedCount) items")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 6)

            if viewModel.currentGroups.isEmpty {
                ContentUnavailableView(
                    "No \(viewModel.selectedCategory.title.lowercased()) found",
                    systemImage: "checkmark.circle",
                    description: Text(viewModel.selectedCategory.detail)
                )
            } else {
                List(viewModel.currentGroups) { group in
                    IssueGroupCard(viewModel: viewModel, group: group)
                }
                .listStyle(.plain)
            }

            if viewModel.selectedIDs.count > 0 {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete \(viewModel.selectedIDs.count) selected", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .confirmationDialog("Delete selected items?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete \(viewModel.selectedIDs.count) items", role: .destructive) {
                Task { await viewModel.deleteSelected() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("They move to Recently Deleted and can be recovered for 30 days.")
        }
    }
}
