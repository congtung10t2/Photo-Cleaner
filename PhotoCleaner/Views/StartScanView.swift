import SwiftUI

struct StartScanView: View {
    @ObservedObject var viewModel: ScanViewModel

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
                ForEach(ScanCategory.allCases) { category in
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

            Button {
                Task { await viewModel.startScan() }
            } label: {
                Label("Scan \(viewModel.activeScope.label)", systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)

            Text("Analysis happens entirely on this device.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }
}
