import SwiftUI

struct ResultsView: View {
    @ObservedObject var viewModel: ScanViewModel
    @State private var showingDeleteConfirmation = false
    @State private var showingReview = false
    @State private var showingSwipeReview = false
    @State private var swipeItems: [AssetDescriptor] = []

    private var selectedAssets: [AssetDescriptor] {
        var seen = Set<String>()
        return viewModel.currentGroups.flatMap(\.assets).filter { item in
            guard viewModel.isSelected(item.id), seen.insert(item.id).inserted else { return false }
            return true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Issue type", selection: $viewModel.selectedCategory) {
                ForEach(ScanCategory.allCases) { category in
                    Text(category.title).tag(category)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)
            .onChange(of: viewModel.selectedCategory) { _, _ in
                viewModel.clearSelection()
            }

            HStack {
                Text("Scanned \(viewModel.scannedCount) items")
                Spacer()
                Text(viewModel.activeScope.label)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .padding(.bottom, 6)

            if viewModel.hasMoreBatches {
                HStack(spacing: 10) {
                    Button {
                        Task { await viewModel.scanNextBatch() }
                    } label: {
                        Label("Next \(viewModel.nextBatchSize)", systemImage: "arrow.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        Task { await viewModel.scanFullLibrary() }
                    } label: {
                        Label("Full library", systemImage: "rectangle.stack")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.bottom, 6)
            }

            Toggle("Review before deleting", isOn: $viewModel.reviewBeforeDeleting)
                .font(.subheadline)
                .padding(.horizontal)
                .padding(.bottom, 4)

            if !viewModel.allIssueAssets.isEmpty {
                Button {
                    swipeItems = viewModel.allIssueAssets
                    showingSwipeReview = true
                } label: {
                    Label("Swipe Review", systemImage: "hand.thumbsup")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
                .padding(.bottom, 6)
            }

            if viewModel.currentGroups.isEmpty {
                ContentUnavailableView(
                    viewModel.selectedCategory.emptyStateTitle,
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
                    if viewModel.reviewBeforeDeleting {
                        showingReview = true
                    } else {
                        showingDeleteConfirmation = true
                    }
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
        .sheet(isPresented: $showingReview) {
            ReviewView(viewModel: viewModel, items: selectedAssets)
        }
        .sheet(isPresented: $showingSwipeReview) {
            SwipeReviewView(viewModel: viewModel, items: swipeItems)
        }
    }
}
