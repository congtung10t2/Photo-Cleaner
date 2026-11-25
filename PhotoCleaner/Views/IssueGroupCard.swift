import SwiftUI

struct IssueGroupCard: View {
    @ObservedObject var viewModel: ScanViewModel
    let group: IssueGroup

    private var allSelected: Bool {
        group.assets.allSatisfy { viewModel.isSelected($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.title)
                        .font(.headline)
                    Text(group.reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(allSelected ? "Deselect all" : "Select all") {
                    viewModel.toggleAll(in: group)
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(group.assets) { item in
                        thumbnail(for: item)
                    }
                }
                .padding(.bottom, 4)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }

    private func thumbnail(for item: AssetDescriptor) -> some View {
        let selected = viewModel.isSelected(item.id)
        let isKeep = group.keepID == item.id

        return ZStack(alignment: .topTrailing) {
            AssetThumbnailView(asset: item.asset, side: 84)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(selected ? Color.accentColor : Color.clear, lineWidth: 3)
                }

            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(selected ? Color.accentColor : Color.white)
                .shadow(radius: 2)
                .padding(5)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .bottomLeading) {
            if isKeep {
                Text("KEEP")
                    .font(.system(size: 8, weight: .bold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(.green.opacity(0.9), in: Capsule())
                    .padding(5)
                    .allowsHitTesting(false)
            }
        }
        .onTapGesture { viewModel.toggle(item.id) }
    }
}
