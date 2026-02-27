import XCTest
@testable import ReadDown

final class ThemeTests: XCTestCase {
    func testAllCasesCount() {
        XCTAssertEqual(Theme.allCases.count, 8)
    }

    func testRawValuesMatchCSSFileNames() {
        for theme in Theme.allCases {
            XCTAssertEqual(theme.rawValue, theme.cssFileName,
                           "\(theme) rawValue should equal cssFileName")
        }
    }

    func testIdentifiableIdMatchesRawValue() {
        for theme in Theme.allCases {
            XCTAssertEqual(theme.id, theme.rawValue)
        }
    }

    func testLightThemes() {
        let lightThemes: [Theme] = [.githubLight, .solarizedLight]

        for theme in lightThemes {
            XCTAssertFalse(theme.isDark, "\(theme.displayName) should be light")
        }
    }

    func testDarkThemes() {
        let darkThemes: [Theme] = [.githubDark, .dracula, .oneDark, .nord, .solarizedDark, .monokai]

        for theme in darkThemes {
            XCTAssertTrue(theme.isDark, "\(theme.displayName) should be dark")
        }
    }

    func testDisplayNamesAreNotEmpty() {
        for theme in Theme.allCases {
            XCTAssertFalse(theme.displayName.isEmpty, "\(theme) should have a display name")
        }
    }

    func testDisplayNamesAreUnique() {
        let names = Theme.allCases.map(\.displayName)
        XCTAssertEqual(names.count, Set(names).count, "Display names should be unique")
    }

    func testCSSFileNamesAreUnique() {
        let fileNames = Theme.allCases.map(\.cssFileName)
        XCTAssertEqual(fileNames.count, Set(fileNames).count, "CSS file names should be unique")
    }

    func testInitFromRawValue() {
        XCTAssertEqual(Theme(rawValue: "github-light"), .githubLight)
        XCTAssertEqual(Theme(rawValue: "dracula"), .dracula)
        XCTAssertEqual(Theme(rawValue: "one-dark"), .oneDark)
        XCTAssertNil(Theme(rawValue: "nonexistent"))
    }
}
