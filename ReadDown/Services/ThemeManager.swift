import SwiftUI

@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    var current: Theme {
        didSet { UserDefaults.standard.set(current.rawValue, forKey: "selectedTheme") }
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: "selectedTheme") ?? ""
        self.current = Theme(rawValue: stored) ?? .githubLight
    }

    func cssContent() -> String {
        guard let url = Bundle.main.url(forResource: current.cssFileName, withExtension: "css", subdirectory: "themes"),
              let css = try? String(contentsOf: url, encoding: .utf8) else {
            return ""
        }
        return css
    }
}
