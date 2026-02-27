import XCTest
@testable import ReadDown

final class ThemeManagerTests: XCTestCase {
    private func freshDefaults() -> UserDefaults {
        let suiteName = "com.readdown.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    func testDefaultThemeIsGithubLight() {
        let manager = ThemeManager(defaults: freshDefaults(), bundle: .main)

        XCTAssertEqual(manager.current, .githubLight)
    }

    func testPersistsThemeToDefaults() {
        let defaults = freshDefaults()
        let manager = ThemeManager(defaults: defaults, bundle: .main)

        manager.current = .dracula

        let stored = defaults.string(forKey: ThemeManager.defaultsKey)
        XCTAssertEqual(stored, "dracula")
    }

    func testRestoresThemeFromDefaults() {
        let defaults = freshDefaults()
        defaults.set("nord", forKey: ThemeManager.defaultsKey)

        let manager = ThemeManager(defaults: defaults, bundle: .main)

        XCTAssertEqual(manager.current, .nord)
    }

    func testInvalidStoredValueFallsBackToDefault() {
        let defaults = freshDefaults()
        defaults.set("nonexistent-theme", forKey: ThemeManager.defaultsKey)

        let manager = ThemeManager(defaults: defaults, bundle: .main)

        XCTAssertEqual(manager.current, .githubLight)
    }

    func testCSSContentReturnsNonEmptyForBundledThemes() {
        let manager = ThemeManager(defaults: freshDefaults(), bundle: .main)

        for theme in Theme.allCases {
            manager.current = theme
            let css = manager.cssContent()
            XCTAssertFalse(css.isEmpty, "CSS should be loadable for \(theme.displayName)")
        }
    }

    func testCSSContentReturnsEmptyForMissingBundle() {
        let emptyBundle = Bundle(for: type(of: self))
        let manager = ThemeManager(defaults: freshDefaults(), bundle: emptyBundle)

        let css = manager.cssContent()

        XCTAssertEqual(css, "")
    }

    func testChangingThemeUpdatesPersistence() {
        let defaults = freshDefaults()
        let manager = ThemeManager(defaults: defaults, bundle: .main)

        manager.current = .monokai
        XCTAssertEqual(defaults.string(forKey: ThemeManager.defaultsKey), "monokai")

        manager.current = .solarizedLight
        XCTAssertEqual(defaults.string(forKey: ThemeManager.defaultsKey), "solarized-light")
    }
}
