import SwiftUI

@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    private let defaults: UserDefaults
    private let bundle: Bundle
    static let defaultsKey = "selectedTheme"

    var current: Theme {
        didSet { defaults.set(current.rawValue, forKey: Self.defaultsKey) }
    }

    convenience init() {
        self.init(defaults: .standard, bundle: .main)
    }

    init(defaults: UserDefaults, bundle: Bundle) {
        self.defaults = defaults
        self.bundle = bundle
        let stored = defaults.string(forKey: Self.defaultsKey) ?? ""
        self.current = Theme(rawValue: stored) ?? .githubLight
    }

    func cssContent() -> String {
        guard let url = bundle.url(forResource: current.cssFileName, withExtension: "css", subdirectory: "themes"),
              let css = try? String(contentsOf: url, encoding: .utf8) else {
            return ""
        }
        return css
    }
}
