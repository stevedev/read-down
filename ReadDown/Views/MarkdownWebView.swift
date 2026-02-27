import SwiftUI
import WebKit
import os

private let logger = Logger(subsystem: "com.readdown.app", category: "WebView")

struct HeadingItem: Identifiable, Equatable {
    let id: String
    let level: Int
    let text: String
}

struct MarkdownWebView: NSViewRepresentable {
    let markdown: String
    let theme: Theme
    let baseURL: URL?
    var scrollY: Double = 0
    var onNavigateToFile: ((URL) -> Void)?
    var onLinkClickedWithScroll: ((_ url: URL, _ scrollY: Double) -> Void)?
    var onHeadingsExtracted: (([HeadingItem]) -> Void)?
    var onScrollPositionChanged: ((Double) -> Void)?

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")

        let coordinator = context.coordinator
        coordinator.webView = webView

        let ucc = webView.configuration.userContentController
        ucc.add(coordinator, name: "linkClicked")
        ucc.add(coordinator, name: "headingsExtracted")
        ucc.add(coordinator, name: "scrollPosition")
        loadTemplate(into: webView, coordinator: coordinator)
        setupContextMenu(webView: webView, coordinator: coordinator)

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onNavigateToFile = onNavigateToFile
        coordinator.onLinkClickedWithScroll = onLinkClickedWithScroll
        coordinator.onHeadingsExtracted = onHeadingsExtracted
        coordinator.onScrollPositionChanged = onScrollPositionChanged
        coordinator.baseURL = baseURL
        coordinator.currentTheme = theme

        guard coordinator.isLoaded else {
            coordinator.pendingMarkdown = markdown
            coordinator.pendingScrollY = scrollY
            return
        }

        updateBaseURL(in: webView, baseURL: baseURL)

        let contentChanged = coordinator.lastRenderedMarkdown != markdown
        let themeChanged = coordinator.lastRenderedTheme != theme

        if contentChanged || themeChanged {
            logger.debug("render: content=\(contentChanged) theme=\(themeChanged) scrollY=\(scrollY)")
            if themeChanged {
                applyTheme(to: webView, theme: theme)
            }
            renderMarkdown(in: webView, markdown: markdown, isDark: theme.isDark, scrollY: scrollY)
            coordinator.lastRenderedMarkdown = markdown
            coordinator.lastRenderedTheme = theme
            coordinator.lastRenderedScrollY = scrollY
        } else if coordinator.lastRenderedScrollY != scrollY {
            logger.debug("scroll-only: \(coordinator.lastRenderedScrollY) → \(scrollY)")
            webView.evaluateJavaScript("window.scrollTo(0, \(scrollY));")
            coordinator.lastRenderedScrollY = scrollY
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
        let hljsJS = loadJS("highlight.min")
        html = html.replacingOccurrences(of: "MARKED_JS_PLACEHOLDER", with: markedJS)
        html = html.replacingOccurrences(of: "MERMAID_JS_PLACEHOLDER", with: mermaidJS)
        html = html.replacingOccurrences(of: "HLJS_JS_PLACEHOLDER", with: hljsJS)

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

    private func renderMarkdown(in webView: WKWebView, markdown: String, isDark: Bool, scrollY: Double = 0) {
        let escaped = markdown
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
        webView.evaluateJavaScript("window.setRawMarkdown(`\(escaped)`);")
        webView.evaluateJavaScript("window.renderMarkdown(`\(escaped)`, \(isDark), \(scrollY));")
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
        var pendingScrollY: Double = 0
        var onNavigateToFile: ((URL) -> Void)?
        var onLinkClickedWithScroll: ((_ url: URL, _ scrollY: Double) -> Void)?
        var onHeadingsExtracted: (([HeadingItem]) -> Void)?
        var onScrollPositionChanged: ((Double) -> Void)?
        var baseURL: URL?
        var currentTheme: Theme = .githubLight

        var lastRenderedMarkdown: String?
        var lastRenderedTheme: Theme?
        var lastRenderedScrollY: Double = 0

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
                webView.evaluateJavaScript("window.renderMarkdown(`\(escaped)`, \(currentTheme.isDark), \(pendingScrollY));")

                lastRenderedMarkdown = pending
                lastRenderedTheme = currentTheme
                lastRenderedScrollY = pendingScrollY
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
                DispatchQueue.main.async { [weak self] in
                    self?.onNavigateToFile?(url)
                }
                return
            }

            if isMarkdownFile(url), let base = baseURL {
                let relativePath = url.path.hasPrefix("/") ? String(url.path.dropFirst()) : url.path
                let resolved = base.deletingLastPathComponent().appendingPathComponent(relativePath)
                decisionHandler(.cancel)
                DispatchQueue.main.async { [weak self] in
                    self?.onNavigateToFile?(resolved)
                }
                return
            }

            decisionHandler(.allow)
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            switch message.name {
            case "linkClicked":
                handleLinkClicked(message)
            case "headingsExtracted":
                handleHeadingsExtracted(message)
            case "scrollPosition":
                if let y = message.body as? Double {
                    onScrollPositionChanged?(y)
                }
            default:
                break
            }
        }

        private func handleLinkClicked(_ message: WKScriptMessage) {
            let href: String
            let scrollY: Double

            if let dict = message.body as? [String: Any] {
                href = dict["href"] as? String ?? ""
                scrollY = dict["scrollY"] as? Double ?? 0
            } else if let str = message.body as? String {
                href = str
                scrollY = 0
            } else {
                return
            }

            guard !href.isEmpty else { return }

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
                logger.debug("linkClicked: \(href) scrollY=\(scrollY)")
                DispatchQueue.main.async { [weak self] in
                    self?.onLinkClickedWithScroll?(standardized, scrollY)
                }
            }
        }

        private func handleHeadingsExtracted(_ message: WKScriptMessage) {
            guard let json = message.body as? String,
                  let data = json.data(using: .utf8),
                  let raw = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }

            let headings = raw.compactMap { dict -> HeadingItem? in
                guard let id = dict["id"] as? String,
                      let level = dict["level"] as? Int,
                      let text = dict["text"] as? String else { return nil }
                return HeadingItem(id: id, level: level, text: text)
            }
            DispatchQueue.main.async { [weak self] in
                self?.onHeadingsExtracted?(headings)
            }
        }

        private func isMarkdownFile(_ url: URL) -> Bool {
            let ext = url.pathExtension.lowercased()
            return ["md", "markdown", "mdown", "mkd"].contains(ext)
        }
    }
}
