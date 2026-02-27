import Foundation

@Observable
final class NavigationHistory {
    private(set) var stack: [URL] = []
    private(set) var currentIndex: Int = -1

    var canGoBack: Bool { currentIndex > 0 }
    var canGoForward: Bool { currentIndex < stack.count - 1 }
    var currentURL: URL? { stack.indices.contains(currentIndex) ? stack[currentIndex] : nil }

    func push(_ url: URL) {
        let normalized = url.standardizedFileURL

        if let current = currentURL, normalized == current { return }

        if currentIndex < stack.count - 1 {
            stack.removeSubrange((currentIndex + 1)...)
        }
        stack.append(normalized)
        currentIndex = stack.count - 1
    }

    func goBack() -> URL? {
        guard canGoBack else { return nil }
        currentIndex -= 1
        return stack[currentIndex]
    }

    func goForward() -> URL? {
        guard canGoForward else { return nil }
        currentIndex += 1
        return stack[currentIndex]
    }
}
