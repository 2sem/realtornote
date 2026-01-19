import SwiftUI

struct PartSettingsScreen: View {
    @Binding var fontSize: CGFloat

    private let minFontSize: CGFloat = 14
    private let maxFontSize: CGFloat = 30
    private let themeColor = Color(red: 0.506, green: 0.831, blue: 0.980)

    var body: some View {
        VStack(spacing: 20) {
            // Font size setting
            VStack(alignment: .leading, spacing: 12) {
                Slider(value: $fontSize, in: minFontSize...maxFontSize, step: 1)
                    .tint(themeColor)
                    .onChange(of: fontSize) { _, newValue in
                        // Save immediately for live preview
                        LSDefaults.ContentSize = Float(newValue)
                    }

                HStack {
                    Image(systemName: "textformat.size.smaller")
                        .font(.body)
                    Spacer()
                    Image(systemName: "textformat.size.larger")
                        .font(.title3)
                }
                .foregroundStyle(.white)
            }

            Spacer()
        }
        .padding()
    }
}
