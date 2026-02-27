import Foundation
import os

private let logger = Logger(subsystem: "com.readdown.app", category: "NavHistory")

@Observable
final class NavigationHistory {
    private(set) var stack: [URL] = []
    private(set) var currentIndex: Int = -1
    private var scrollPositions: [Int: Double] = [:]

    var canGoBack: Bool { currentIndex > 0 }
    var canGoForward: Bool { currentIndex < stack.count - 1 }
    var currentURL: URL? { stack.indices.contains(currentIndex) ? stack[currentIndex] : nil }

    func push(_ url: URL) {
        let normalized = url.standardizedFileURL

        if let current = currentURL, normalized == current { return }

        if currentIndex < stack.count - 1 {
            for i in (currentIndex + 1)..<stack.count {
                scrollPositions.removeValue(forKey: i)
            }
            stack.removeSubrange((currentIndex + 1)...)
        }
        stack.append(normalized)
        currentIndex = stack.count - 1
        logger.debug("push: \(normalized.lastPathComponent) [index=\(self.currentIndex), depth=\(self.stack.count)]")
    }

    func saveScrollPosition(_ y: Double) {
        guard currentIndex >= 0 else { return }
        scrollPositions[currentIndex] = y
        logger.debug("saveScroll: index=\(self.currentIndex) y=\(y)")
    }

    func goBack() -> (url: URL, scrollY: Double)? {
        guard canGoBack else { return nil }
        currentIndex -= 1
        let scrollY = scrollPositions[currentIndex] ?? 0
        logger.debug("goBack: → index=\(self.currentIndex) scrollY=\(scrollY)")
        return (stack[currentIndex], scrollY)
    }

    func goForward() -> (url: URL, scrollY: Double)? {
        guard canGoForward else { return nil }
        currentIndex += 1
        let scrollY = scrollPositions[currentIndex] ?? 0
        logger.debug("goForward: → index=\(self.currentIndex) scrollY=\(scrollY)")
        return (stack[currentIndex], scrollY)
    }
}
