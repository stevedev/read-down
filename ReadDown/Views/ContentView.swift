import SwiftUI
import WebKit
import os

private let logger = Logger(subsystem: "com.readdown.app", category: "Navigation")

private final class ScrollPositionTracker {
    var y: Double = 0
}

struct ContentView: View {
    @Binding var document: MarkdownDocument
    let fileURL: URL?
    @State private var navigationHistory = NavigationHistory()
    @State private var fileWatcher: FileWatcher?
    @State private var currentMarkdown: String = ""
    @State private var currentFileURL: URL?
    @State private var showFind = false
    @State private var findQuery = ""
    @State private var headings: [HeadingItem] = []
    @State private var showTOC = false
    @State private var targetScrollY: Double = 0
    @State private var scrollTracker = ScrollPositionTracker()
    @Bindable var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            if showFind {
                findBar
                Divider()
            }
            HStack(spacing: 0) {
                if showTOC && !headings.isEmpty {
                    tocSidebar
                    Divider()
                }
                MarkdownWebView(
                    markdown: currentMarkdown,
                    theme: themeManager.current,
                    baseURL: currentFileURL,
                    scrollY: targetScrollY,
                    onNavigateToFile: navigateToFile,
                    onLinkClickedWithScroll: navigateToFileFromLink,
                    onHeadingsExtracted: { self.headings = $0 },
                    onScrollPositionChanged: { self.scrollTracker.y = $0 }
                )
            }
        }
        .onAppear {
            currentMarkdown = document.text
            if let url = fileURL {
                currentFileURL = url
                navigationHistory.push(url)
                startWatching(url: url)
            }
        }
        .onChange(of: document.text) { _, newValue in
            if currentFileURL == fileURL {
                currentMarkdown = newValue
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleFind)) { _ in
            showFind.toggle()
            if !showFind { findQuery = "" }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button(action: goBack) {
                Image(systemName: "chevron.left")
            }
            .disabled(!navigationHistory.canGoBack)
            .help("Back")
            .keyboardShortcut("[", modifiers: .command)

            Button(action: goForward) {
                Image(systemName: "chevron.right")
            }
            .disabled(!navigationHistory.canGoForward)
            .help("Forward")
            .keyboardShortcut("]", modifiers: .command)

            Spacer()

            if let url = currentFileURL {
                Text(url.lastPathComponent)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: { showTOC.toggle() }) {
                Image(systemName: "list.bullet.indent")
            }
            .help("Table of Contents")
            .disabled(headings.isEmpty)

            Picker("Theme", selection: $themeManager.current) {
                ForEach(Theme.allCases) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 160)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var findBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Find in document...", text: $findQuery)
                .textFieldStyle(.plain)
                .onSubmit { performFind(forward: true) }

            Button(action: { performFind(forward: false) }) {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(.borderless)
            .help("Previous match")

            Button(action: { performFind(forward: true) }) {
                Image(systemName: "chevron.down")
            }
            .buttonStyle(.borderless)
            .help("Next match")

            Button(action: {
                showFind = false
                findQuery = ""
                clearFind()
            }) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .help("Close find bar")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    private var tocSidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(headings) { heading in
                    Button(action: { scrollToHeading(heading.id) }) {
                        Text(heading.text)
                            .font(.system(size: 12))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, CGFloat((heading.level - 1) * 12))
                    .padding(.vertical, 3)
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
                }
            }
            .padding(.vertical, 8)
        }
        .frame(width: 220)
        .background(.background.opacity(0.5))
    }

    private func performFind(forward: Bool) {
        guard !findQuery.isEmpty else { return }
        let escaped = findQuery
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
        let js = "window.findText('\(escaped)', \(forward));"
        evaluateJS(js)
    }

    private func clearFind() {
        evaluateJS("window.getSelection().removeAllRanges();")
    }

    private func scrollToHeading(_ id: String) {
        let escaped = id.replacingOccurrences(of: "'", with: "\\'")
        evaluateJS("window.scrollToHeading('\(escaped)');")
    }

    private func evaluateJS(_ js: String) {
        guard let window = NSApp.keyWindow,
              let contentView = window.contentView,
              let webView = findWebView(in: contentView) else { return }
        webView.evaluateJavaScript(js)
    }

    private func findWebView(in view: NSView) -> WKWebView? {
        if let wv = view as? WKWebView { return wv }
        for subview in view.subviews {
            if let wv = findWebView(in: subview) { return wv }
        }
        return nil
    }

    // MARK: - Navigation

    private func resolveURL(_ url: URL) -> URL {
        if url.path.hasPrefix("/") { return url }
        if let base = currentFileURL {
            return base.deletingLastPathComponent().appendingPathComponent(url.path)
        }
        return url
    }

    private func navigateToFile(_ url: URL) {
        let resolvedURL = resolveURL(url)
        guard let content = try? String(contentsOf: resolvedURL, encoding: .utf8) else {
            logger.error("navigateToFile: failed to read \(resolvedURL.path)")
            return
        }

        logger.info("navigateToFile: \(resolvedURL.lastPathComponent)")
        navigationHistory.push(resolvedURL)
        currentFileURL = resolvedURL
        currentMarkdown = content
        targetScrollY = 0
        startWatching(url: resolvedURL)
    }

    private func navigateToFileFromLink(_ url: URL, _ scrollY: Double) {
        let resolvedURL = resolveURL(url)
        guard let content = try? String(contentsOf: resolvedURL, encoding: .utf8) else {
            logger.error("navigateToFileFromLink: failed to read \(resolvedURL.path)")
            return
        }

        logger.info("navigateToFileFromLink: \(resolvedURL.lastPathComponent) (saving scrollY=\(scrollY))")
        navigationHistory.saveScrollPosition(scrollY)
        navigationHistory.push(resolvedURL)
        currentFileURL = resolvedURL
        currentMarkdown = content
        targetScrollY = 0
        startWatching(url: resolvedURL)
    }

    private func goBack() {
        let currentScroll = scrollTracker.y
        logger.info("goBack: saving scrollY=\(currentScroll)")
        navigationHistory.saveScrollPosition(currentScroll)

        guard let result = navigationHistory.goBack(),
              let content = try? String(contentsOf: result.url, encoding: .utf8) else {
            logger.error("goBack: failed")
            return
        }

        logger.info("goBack: → \(result.url.lastPathComponent) restoring scrollY=\(result.scrollY)")
        currentFileURL = result.url
        currentMarkdown = content
        targetScrollY = result.scrollY
        startWatching(url: result.url)
    }

    private func goForward() {
        let currentScroll = scrollTracker.y
        logger.info("goForward: saving scrollY=\(currentScroll)")
        navigationHistory.saveScrollPosition(currentScroll)

        guard let result = navigationHistory.goForward(),
              let content = try? String(contentsOf: result.url, encoding: .utf8) else {
            logger.error("goForward: failed")
            return
        }

        logger.info("goForward: → \(result.url.lastPathComponent) restoring scrollY=\(result.scrollY)")
        currentFileURL = result.url
        currentMarkdown = content
        targetScrollY = result.scrollY
        startWatching(url: result.url)
    }

    private func startWatching(url: URL) {
        fileWatcher?.stop()
        let watcher = FileWatcher { [url] in
            guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
            currentMarkdown = content
        }
        watcher.watch(url: url)
        fileWatcher = watcher
    }
}
