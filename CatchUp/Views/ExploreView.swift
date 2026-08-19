import SafariServices
import SwiftUI

struct ExploreView: View {
    private let discoverURL = URL(string: "https://www.perplexity.ai/discover")!

    var body: some View {
        SafariPage(url: discoverURL)
            .ignoresSafeArea(edges: .top)
            .accessibilityLabel("Perplexity Discover")
    }
}

private struct SafariPage: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        configuration.barCollapsingEnabled = true
        let controller = SFSafariViewController(url: url, configuration: configuration)
        controller.preferredControlTintColor = .black
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

