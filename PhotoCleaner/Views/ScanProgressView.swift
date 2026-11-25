import SwiftUI

struct ScanProgressView: View {
    let progress: Double
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ProgressView(value: progress) {
                Text("Analyzing your library")
                    .font(.title2.weight(.semibold))
            } currentValueLabel: {
                Text("\(Int(progress * 100))%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .progressViewStyle(.linear)
            .padding(.horizontal, 40)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}
