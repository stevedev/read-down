import XCTest
@testable import ReadDown

final class FileWatcherTests: XCTestCase {
    private var tempFile: URL!

    override func setUp() {
        super.setUp()
        tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("filewatcher-test-\(UUID().uuidString).md")
        FileManager.default.createFile(atPath: tempFile.path, contents: "initial".data(using: .utf8))
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempFile)
        super.tearDown()
    }

    func testCallbackFiresOnFileWrite() {
        let expectation = expectation(description: "onChange called")
        let watcher = FileWatcher { expectation.fulfill() }

        watcher.watch(url: tempFile)
        try! "updated".write(to: tempFile, atomically: true, encoding: .utf8)

        waitForExpectations(timeout: 2)
        watcher.stop()
    }

    func testStopPreventsCallback() {
        var callCount = 0
        let watcher = FileWatcher { callCount += 1 }

        watcher.watch(url: tempFile)
        watcher.stop()
        try! "updated".write(to: tempFile, atomically: true, encoding: .utf8)

        let expectation = expectation(description: "wait for potential callback")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { expectation.fulfill() }
        waitForExpectations(timeout: 2)

        XCTAssertEqual(callCount, 0)
    }

    func testWatchNewURLStopsPrevious() {
        let secondFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("filewatcher-test2-\(UUID().uuidString).md")
        FileManager.default.createFile(atPath: secondFile.path, contents: "second".data(using: .utf8))
        defer { try? FileManager.default.removeItem(at: secondFile) }

        var firstFileCallCount = 0
        let secondFileExpectation = expectation(description: "onChange for second file")
        let watcher = FileWatcher { secondFileExpectation.fulfill() }

        watcher.watch(url: tempFile)

        let firstWatcher = FileWatcher { firstFileCallCount += 1 }
        firstWatcher.watch(url: tempFile)
        firstWatcher.stop()

        watcher.watch(url: secondFile)

        try! "changed first".write(to: tempFile, atomically: true, encoding: .utf8)
        try! "changed second".write(to: secondFile, atomically: true, encoding: .utf8)

        waitForExpectations(timeout: 2)
        watcher.stop()
    }

    func testWatchNonexistentFileDoesNotCrash() {
        let bogus = URL(fileURLWithPath: "/tmp/nonexistent-\(UUID().uuidString).md")
        let watcher = FileWatcher { XCTFail("Should not be called") }

        watcher.watch(url: bogus)
        watcher.stop()
    }
}
