import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    let markdown: String
    let theme: Theme
    let baseURL: URL?
    var onNavigateToFile: ((URL) -> Void)?

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")

        let coordinator = context.coordinator
        coordinator.webView = webView

        webView.configuration.userContentController.add(coordinator, name: "linkClicked")
        loadTemplate(into: webView, coordinator: coordinator)
        setupContextMenu(webView: webView, coordinator: coordinator)

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onNavigateToFile = onNavigateToFile
        coordinator.baseURL = baseURL
        coordinator.currentTheme = theme

        if coordinator.isLoaded {
            updateBaseURL(in: webView, baseURL: baseURL)
            applyTheme(to: webView, theme: theme)
            renderMarkdown(in: webView, markdown: markdown, isDark: theme.isDark)
        } else {
            coordinator.pendingMarkdown = markdown
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func loadTemplate(into webView: WKWebView, coordinator: Coordinator) {
        guard let templateURL = Bundle.main.url(forResource: "template", withExtension: "html"),
              var html = try? String(contentsOf: templateURL, encoding: .utf8) else {
            return
        }

        let markedJS = loadJS("marked.min")
        let mermaidJS = loadJS("mermaid.min")
        html = html.replacingOccurrences(of: "MARKED_JS_PLACEHOLDER", with: markedJS)
        html = html.replacingOccurrences(of: "MERMAID_JS_PLACEHOLDER", with: mermaidJS)

        webView.loadHTMLString(html, baseURL: baseURL)
    }

    private func loadJS(_ name: String) -> String {
        guard let url = Bundle.main.url(forResource: name, withExtension: "js", subdirectory: "js"),
              let js = try? String(contentsOf: url, encoding: .utf8) else {
            return ""
        }
        return js
    }

    private func updateBaseURL(in webView: WKWebView, baseURL: URL?) {
        guard let base = baseURL else { return }
        let dirURL = base.deletingLastPathComponent()
        let escaped = dirURL.absoluteString
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
        webView.evaluateJavaScript("window.setBaseURL('\(escaped)');")
    }

    private func applyTheme(to webView: WKWebView, theme: Theme) {
        let css = ThemeManager.shared.cssContent()
        let escapedCSS = css
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
        webView.evaluateJavaScript("window.applyThemeCSS('\(escapedCSS)');")
    }

    private func renderMarkdown(in webView: WKWebView, markdown: String, isDark: Bool) {
        let escaped = markdown
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
        webView.evaluateJavaScript("window.setRawMarkdown(`\(escaped)`);")
        webView.evaluateJavaScript("window.renderMarkdown(`\(escaped)`, \(isDark));")
    }

    private func setupContextMenu(webView: WKWebView, coordinator: Coordinator) {
        let script = WKUserScript(
            source: """
            document.addEventListener('contextmenu', function(e) {
                window.webkit.messageHandlers.contextMenu.postMessage({
                    hasSelection: window.getSelection().toString().length > 0
                });
            });
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        webView.configuration.userContentController.addUserScript(script)
        webView.configuration.userContentController.add(coordinator, name: "contextMenu")
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        weak var webView: WKWebView?
        var isLoaded = false
        var pendingMarkdown: String?
        var onNavigateToFile: ((URL) -> Void)?
        var baseURL: URL?
        var currentTheme: Theme = .githubLight

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoaded = true
            if let pending = pendingMarkdown {
                if let base = baseURL {
                    let dirURL = base.deletingLastPathComponent()
                    let escaped = dirURL.absoluteString
                        .replacingOccurrences(of: "\\", with: "\\\\")
                        .replacingOccurrences(of: "'", with: "\\'")
                    webView.evaluateJavaScript("window.setBaseURL('\(escaped)');")
                }

                let css = ThemeManager.shared.cssContent()
                let escapedCSS = css
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "'", with: "\\'")
                    .replacingOccurrences(of: "\n", with: "\\n")
                webView.evaluateJavaScript("window.applyThemeCSS('\(escapedCSS)');")

                let escaped = pending
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "`", with: "\\`")
                    .replacingOccurrences(of: "$", with: "\\$")
                webView.evaluateJavaScript("window.setRawMarkdown(`\(escaped)`);")
                webView.evaluateJavaScript("window.renderMarkdown(`\(escaped)`, \(currentTheme.isDark));")
                pendingMarkdown = nil
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard navigationAction.navigationType == .linkActivated,
                  let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            if let scheme = url.scheme, scheme == "http" || scheme == "https" {
                decisionHandler(.cancel)
                NSWorkspace.shared.open(url)
                return
            }

            if url.isFileURL, isMarkdownFile(url) {
                decisionHandler(.cancel)
                onNavigateToFile?(url)
                return
            }

            // Fallback: URL has a markdown extension but wasn't resolved to a file://
            // URL (e.g. applewebdata:// from a nil base URL). Resolve manually.
            if isMarkdownFile(url), let base = baseURL {
                let relativePath = url.path.hasPrefix("/") ? String(url.path.dropFirst()) : url.path
                let resolved = base.deletingLastPathComponent().appendingPathComponent(relativePath)
                decisionHandler(.cancel)
                onNavigateToFile?(resolved)
                return
            }

            decisionHandler(.allow)
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "linkClicked",
                  let href = message.body as? String else { return }

            if href.hasPrefix("http://") || href.hasPrefix("https://") {
                if let url = URL(string: href) {
                    NSWorkspace.shared.open(url)
                }
                return
            }

            guard let base = baseURL else { return }
            let resolved = base.deletingLastPathComponent().appendingPathComponent(href)
            let standardized = resolved.standardized

            if isMarkdownFile(standardized) {
                onNavigateToFile?(standardized)
            }
        }

        private func isMarkdownFile(_ url: URL) -> Bool {
            let ext = url.pathExtension.lowercased()
            return ["md", "markdown", "mdown", "mkd"].contains(ext)
        }
    }
}
