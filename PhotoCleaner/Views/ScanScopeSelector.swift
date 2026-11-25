import SwiftUI

struct ScanScopeSelector: View {
    @ObservedObject var viewModel: ScanViewModel
    @State private var amountText = "100"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scan amount")
                .font(.headline)

            Picker("Scan amount", selection: $viewModel.selectedScopeOption) {
                ForEach(ScanScopeOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.menu)

            if viewModel.selectedScopeOption == .custom {
                HStack {
                    Text("Items per scan")
                    Spacer()
                    TextField("Amount", text: $amountText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
                .onChange(of: amountText) { _, newValue in
                    let digits = newValue.filter(\.isNumber)
                    if digits != newValue { amountText = digits }
                    viewModel.customAmount = max(1, Int(digits) ?? 1)
                }
            }

            Text(viewModel.selectedScopeOption == .full
                 ? "Scans the entire library in one pass."
                 : "Scans \(viewModel.activeScope.label) now; continue with more batches later.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: 420, alignment: .leading)
    }
}
