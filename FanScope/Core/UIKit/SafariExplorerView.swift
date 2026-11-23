import SafariServices
import SwiftUI

struct SafariExplorerView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let controller = SFSafariViewController(url: url, configuration: config)
        controller.preferredControlTintColor = UIColor.systemBlue
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct ExplorerSheetDestination: Identifiable, Hashable {
    let url: URL
    var id: String { url.absoluteString }
}
