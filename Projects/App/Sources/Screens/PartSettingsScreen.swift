import SwiftUI

struct PartSettingsScreen: View {
    @Binding var fontSize: CGFloat
    @AppStorage(LSDefaults.Keys.AppearanceMode) private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    private var selectedMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    private let minFontSize: CGFloat = 14
    private let maxFontSize: CGFloat = 30

    var body: some View {
        VStack(spacing: 24) {
            // Font size setting
            VStack(alignment: .leading, spacing: 12) {
                Slider(value: $fontSize, in: minFontSize...maxFontSize, step: 1)
                    .tint(Color.themePrimary)
                    .onChange(of: fontSize) { _, newValue in
                        LSDefaults.ContentSize = Float(newValue)
                    }

                HStack {
                    Image(systemName: "textformat.size.smaller")
                        .font(.body)
                    Spacer()
                    Image(systemName: "textformat.size.larger")
                        .font(.title3)
                }
                .foregroundStyle(Color.themePrimary)
            }

            Divider()

            // Appearance mode picker
            HStack(spacing: 0) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Button {
                        appearanceModeRaw = mode.rawValue
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.title3)
                            Text(mode.title)
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedMode == mode ? Color.themePrimary.opacity(0.15) : Color.clear)
                        .foregroundStyle(selectedMode == mode ? Color.themePrimary : Color.secondary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding()
    }
}
