import XCTest
@testable import ReadDown

final class NavigationHistoryTests: XCTestCase {
    private let urlA = URL(fileURLWithPath: "/docs/a.md")
    private let urlB = URL(fileURLWithPath: "/docs/b.md")
    private let urlC = URL(fileURLWithPath: "/docs/c.md")
    private let urlD = URL(fileURLWithPath: "/docs/d.md")

    func testInitialStateIsEmpty() {
        let history = NavigationHistory()

        XCTAssertTrue(history.stack.isEmpty)
        XCTAssertNil(history.currentURL)
        XCTAssertFalse(history.canGoBack)
        XCTAssertFalse(history.canGoForward)
    }

    func testPushSingleURL() {
        let history = NavigationHistory()

        history.push(urlA)

        XCTAssertEqual(history.stack.count, 1)
        XCTAssertEqual(history.currentURL, urlA.standardizedFileURL)
        XCTAssertFalse(history.canGoBack)
        XCTAssertFalse(history.canGoForward)
    }

    func testPushDuplicateIsNoOp() {
        let history = NavigationHistory()

        history.push(urlA)
        history.push(urlA)

        XCTAssertEqual(history.stack.count, 1)
    }

    func testPushMultipleThenGoBack() {
        let history = NavigationHistory()
        history.push(urlA)
        history.push(urlB)
        history.push(urlC)

        let result = history.goBack()

        XCTAssertEqual(result?.url, urlB.standardizedFileURL)
        XCTAssertEqual(history.currentURL, urlB.standardizedFileURL)
        XCTAssertTrue(history.canGoBack)
        XCTAssertTrue(history.canGoForward)
    }

    func testGoForwardAfterGoBack() {
        let history = NavigationHistory()
        history.push(urlA)
        history.push(urlB)
        history.push(urlC)
        _ = history.goBack()

        let result = history.goForward()

        XCTAssertEqual(result?.url, urlC.standardizedFileURL)
        XCTAssertEqual(history.currentURL, urlC.standardizedFileURL)
        XCTAssertFalse(history.canGoForward)
    }

    func testGoBackAtStartReturnsNil() {
        let history = NavigationHistory()
        history.push(urlA)

        let result = history.goBack()

        XCTAssertNil(result)
        XCTAssertEqual(history.currentURL, urlA.standardizedFileURL)
    }

    func testGoForwardAtEndReturnsNil() {
        let history = NavigationHistory()
        history.push(urlA)
        history.push(urlB)

        let result = history.goForward()

        XCTAssertNil(result)
        XCTAssertEqual(history.currentURL, urlB.standardizedFileURL)
    }

    func testPushAfterGoBackTruncatesForwardHistory() {
        let history = NavigationHistory()
        history.push(urlA)
        history.push(urlB)
        _ = history.goBack()

        history.push(urlC)

        XCTAssertEqual(history.stack.count, 2)
        XCTAssertEqual(history.stack[0], urlA.standardizedFileURL)
        XCTAssertEqual(history.stack[1], urlC.standardizedFileURL)
        XCTAssertEqual(history.currentURL, urlC.standardizedFileURL)
        XCTAssertFalse(history.canGoForward)
    }

    func testPushAfterMultipleGoBacksTruncatesCorrectly() {
        let history = NavigationHistory()
        history.push(urlA)
        history.push(urlB)
        history.push(urlC)
        history.push(urlD)
        _ = history.goBack()
        _ = history.goBack()

        history.push(urlD)

        XCTAssertEqual(history.stack.count, 3)
        XCTAssertEqual(history.stack[0], urlA.standardizedFileURL)
        XCTAssertEqual(history.stack[1], urlB.standardizedFileURL)
        XCTAssertEqual(history.stack[2], urlD.standardizedFileURL)
        XCTAssertFalse(history.canGoForward)
    }

    func testSaveAndRestoreScrollPosition() {
        let history = NavigationHistory()
        history.push(urlA)
        history.saveScrollPosition(250.0)
        history.push(urlB)
        history.saveScrollPosition(500.0)

        let result = history.goBack()

        XCTAssertEqual(result?.scrollY, 250.0)
    }

    func testGoForwardRestoresScrollPosition() {
        let history = NavigationHistory()
        history.push(urlA)
        history.push(urlB)
        history.saveScrollPosition(300.0)
        _ = history.goBack()

        let result = history.goForward()

        XCTAssertEqual(result?.scrollY, 300.0)
    }

    func testScrollPositionDefaultsToZero() {
        let history = NavigationHistory()
        history.push(urlA)
        history.push(urlB)

        let result = history.goBack()

        XCTAssertEqual(result?.scrollY, 0)
    }

    func testScrollPositionsClearedOnTruncation() {
        let history = NavigationHistory()
        history.push(urlA)
        history.push(urlB)
        history.saveScrollPosition(400.0)
        _ = history.goBack()

        history.push(urlC)
        _ = history.goBack()
        let result = history.goForward()

        XCTAssertEqual(result?.url, urlC.standardizedFileURL)
        XCTAssertEqual(result?.scrollY, 0)
    }

    func testSaveScrollPositionWithEmptyStackDoesNotCrash() {
        let history = NavigationHistory()

        history.saveScrollPosition(100.0)

        XCTAssertNil(history.currentURL)
    }

    func testGoBackThenGoForwardThenGoBackIsConsistent() {
        let history = NavigationHistory()
        history.push(urlA)
        history.saveScrollPosition(100.0)
        history.push(urlB)
        history.saveScrollPosition(200.0)
        history.push(urlC)
        history.saveScrollPosition(300.0)

        let back1 = history.goBack()
        XCTAssertEqual(back1?.url, urlB.standardizedFileURL)
        XCTAssertEqual(back1?.scrollY, 200.0)

        let fwd1 = history.goForward()
        XCTAssertEqual(fwd1?.url, urlC.standardizedFileURL)
        XCTAssertEqual(fwd1?.scrollY, 300.0)

        let back2 = history.goBack()
        XCTAssertEqual(back2?.url, urlB.standardizedFileURL)
        XCTAssertEqual(back2?.scrollY, 200.0)

        let back3 = history.goBack()
        XCTAssertEqual(back3?.url, urlA.standardizedFileURL)
        XCTAssertEqual(back3?.scrollY, 100.0)
    }
}
