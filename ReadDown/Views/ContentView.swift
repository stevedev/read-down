import SwiftUI

struct ContentView: View {
    @Binding var document: MarkdownDocument
    let fileURL: URL?
    @State private var navigationHistory = NavigationHistory()
    @State private var fileWatcher: FileWatcher?
    @State private var currentMarkdown: String = ""
    @State private var currentFileURL: URL?
    @Bindable var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            MarkdownWebView(
                markdown: currentMarkdown,
                theme: themeManager.current,
                baseURL: currentFileURL,
                onNavigateToFile: navigateToFile
            )
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

    private func navigateToFile(_ url: URL) {
        let resolvedURL: URL
        if url.path.hasPrefix("/") {
            resolvedURL = url
        } else if let base = currentFileURL {
            resolvedURL = base.deletingLastPathComponent().appendingPathComponent(url.path)
        } else {
            resolvedURL = url
        }

        guard let content = try? String(contentsOf: resolvedURL, encoding: .utf8) else { return }

        navigationHistory.push(resolvedURL)
        currentFileURL = resolvedURL
        currentMarkdown = content
        startWatching(url: resolvedURL)
    }

    private func goBack() {
        guard let url = navigationHistory.goBack(),
              let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        currentFileURL = url
        currentMarkdown = content
        startWatching(url: url)
    }

    private func goForward() {
        guard let url = navigationHistory.goForward(),
              let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        currentFileURL = url
        currentMarkdown = content
        startWatching(url: url)
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
