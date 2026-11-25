import SwiftUI

struct SwipeReviewView: View {
    @ObservedObject var viewModel: ScanViewModel
    let items: [AssetDescriptor]

    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var isDeleting = false

    private var isFinished: Bool { index >= items.count }

    var body: some View {
        NavigationStack {
            Group {
                if isFinished {
                    finishedView
                } else {
                    reviewView(for: items[index])
                }
            }
            .navigationTitle(isFinished ? "All Done" : "Review \(index + 1) of \(items.count)")
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

            HStack(spacing: 48) {
                decisionButton(title: "Remove", systemImage: "xmark", tint: .red) {
                    Task { await remove(item) }
                }
                .disabled(isDeleting)

                decisionButton(title: "Keep", systemImage: "checkmark", tint: .green) {
                    advance()
                }
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

            Text("You're all caught up")
                .font(.title2.bold())

            Text("Every flagged item has been reviewed.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func remove(_ item: AssetDescriptor) async {
        guard !isDeleting else { return }
        isDeleting = true
        await viewModel.delete(ids: [item.id])
        isDeleting = false
        guard viewModel.alertMessage == nil else { return }
        advance()
    }

    private func advance() {
        index += 1
    }

    private var deleteErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.alertMessage != nil },
            set: { if !$0 { viewModel.alertMessage = nil } }
        )
    }
}
