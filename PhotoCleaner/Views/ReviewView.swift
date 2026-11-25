import SwiftUI

struct ReviewView: View {
    @ObservedObject var viewModel: ScanViewModel
    let items: [AssetDescriptor]

    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var approvedIDs: Set<String> = []
    @State private var isFinished = false

    private var isShowingSummary: Bool { isFinished || items.isEmpty }

    var body: some View {
        NavigationStack {
            Group {
                if isShowingSummary {
                    summaryView
                } else {
                    reviewView
                }
            }
            .navigationTitle(isShowingSummary ? "Ready to Delete" : "Review \(index + 1) of \(items.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var reviewView: some View {
        let item = items[index]

        return VStack(spacing: 16) {
            FullScreenAssetView(asset: item.asset)
                .id(item.id)

            HStack(spacing: 16) {
                Button {
                    advance()
                } label: {
                    Label("Keep", systemImage: "hand.thumbsup")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(role: .destructive) {
                    approvedIDs.insert(item.id)
                    advance()
                } label: {
                    Label("Delete", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private var summaryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "trash.circle")
                .font(.system(size: 64))
                .foregroundStyle(.red)

            Text("\(approvedIDs.count) marked for deletion")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("Everything you chose to keep stays in your library.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(role: .destructive) {
                Task {
                    await viewModel.delete(ids: approvedIDs)
                    dismiss()
                }
            } label: {
                Label("Delete \(approvedIDs.count) items", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(approvedIDs.isEmpty)
            .padding(.horizontal, 40)

            Button("Cancel") { dismiss() }
        }
        .padding()
    }

    private func advance() {
        if index + 1 < items.count {
            index += 1
        } else {
            isFinished = true
        }
    }
}
