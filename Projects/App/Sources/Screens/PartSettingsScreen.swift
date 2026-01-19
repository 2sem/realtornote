import SwiftUI

struct PartSettingsScreen: View {
    @Binding var fontSize: CGFloat
    @Environment(\.dismiss) private var dismiss

    private let minFontSize: CGFloat = 14
    private let maxFontSize: CGFloat = 30

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                Text("설정")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Font size setting
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("글자 크기")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(fontSize))pt")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $fontSize, in: minFontSize...maxFontSize, step: 1)
                        .tint(Color(red: 0.506, green: 0.831, blue: 0.980))
                        .onChange(of: fontSize) { _, newValue in
                            // Save immediately for live preview
                            LSDefaults.ContentSize = Float(newValue)
                        }

                    HStack {
                        Text("A")
                            .font(.system(size: 14))
                        Spacer()
                        Text("A")
                            .font(.system(size: 30))
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
}
