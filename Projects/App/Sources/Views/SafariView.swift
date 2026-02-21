import SwiftUI
import SafariServices

/// Helper struct to make URL identifiable for sheet presentation
struct SafariURL: Identifiable {
    let id = UUID()
    let url: URL
}

/// SwiftUI wrapper for SFSafariViewController
/// Provides in-app web browsing with Safari's features
struct SafariView: UIViewControllerRepresentable {
    let url: SafariURL
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(LSDefaults.Keys.AppearanceMode) private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    private var interfaceStyleOverride: UIUserInterfaceStyle {
        switch AppearanceMode(rawValue: appearanceModeRaw) {
        case .dark:   return .dark
        case .light:  return .light
        default:      return .unspecified  // system: let SFSafariViewController follow iOS naturally
        }
    }

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        configuration.barCollapsingEnabled = true

        let safariViewController = SFSafariViewController(url: url.url, configuration: configuration)
        safariViewController.preferredControlTintColor = .systemBlue
        safariViewController.preferredBarTintColor = .systemBackground
        safariViewController.dismissButtonStyle = .done
        safariViewController.overrideUserInterfaceStyle = interfaceStyleOverride

        return safariViewController
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        uiViewController.overrideUserInterfaceStyle = interfaceStyleOverride
    }
}
