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

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        configuration.barCollapsingEnabled = true

        let safariViewController = SFSafariViewController(url: url.url, configuration: configuration)
        safariViewController.preferredControlTintColor = .systemBlue
        safariViewController.preferredBarTintColor = .systemBackground
        safariViewController.dismissButtonStyle = .done

        return safariViewController
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}
