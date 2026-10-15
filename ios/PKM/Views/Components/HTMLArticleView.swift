import SwiftUI
import WebKit

/// Показує HTML запису з сайту (з фото, відео YouTube тощо) у WKWebView з «рідними» шрифтами й темною темою.
/// Посилання відкриваються в Safari / відповідних застосунках.
struct HTMLArticleView: UIViewRepresentable {
    let title: String
    let subtitle: String?
    let html: String
    var baseURL: URL? = AppConfig.siteURL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let document = page
        guard context.coordinator.loadedDocument != document else { return }
        context.coordinator.loadedDocument = document
        webView.loadHTMLString(document, baseURL: baseURL)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        var loadedDocument: String?

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
                _ = await UIApplication.shared.open(url)
                return .cancel
            }
            return .allow
        }
    }

    private var page: String {
        let subtitleHTML = subtitle.map { "<p class=\"meta\">\(escape($0))</p>" } ?? ""
        return """
        <!doctype html>
        <html lang="uk"><head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          :root { color-scheme: light dark; --accent: #b0283a; }
          @media (prefers-color-scheme: dark) { :root { --accent: #e06373; } }
          body { font: -apple-system-body; font-size: 17px; line-height: 1.5; margin: 0;
                 padding: 16px 20px 48px; word-wrap: break-word; -webkit-text-size-adjust: 100%; }
          h1.title { font: -apple-system-title1; font-weight: 700; line-height: 1.2; margin: 0 0 6px; }
          .meta { color: gray; font-size: 15px; margin: 0 0 20px; }
          a { color: var(--accent); }
          img, video { max-width: 100%; height: auto; border-radius: 10px; }
          figure { margin: 16px 0; }
          iframe { width: 100%; aspect-ratio: 16 / 9; height: auto; border: 0; border-radius: 10px; }
          blockquote { margin: 16px 0; padding-left: 14px; border-left: 3px solid var(--accent); font-style: italic; }
          .wp-caption, .wp-block-image { max-width: 100% !important; }
          .addtoany_share_save_container, .sharedaddy { display: none; }
        </style></head>
        <body><h1 class="title">\(escape(title))</h1>\(subtitleHTML)\(html)</body></html>
        """
    }

    private func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
