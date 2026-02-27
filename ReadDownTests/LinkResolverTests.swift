import XCTest
@testable import ReadDown

final class LinkResolverTests: XCTestCase {
    private let baseURL = URL(fileURLWithPath: "/docs/project/README.md")

    // MARK: - isMarkdownFile

    func testRecognizesMDExtension() {
        let url = URL(fileURLWithPath: "/docs/file.md")

        XCTAssertTrue(LinkResolver.isMarkdownFile(url))
    }

    func testRecognizesMarkdownExtension() {
        let url = URL(fileURLWithPath: "/docs/file.markdown")

        XCTAssertTrue(LinkResolver.isMarkdownFile(url))
    }

    func testRecognizesMdownExtension() {
        let url = URL(fileURLWithPath: "/docs/file.mdown")

        XCTAssertTrue(LinkResolver.isMarkdownFile(url))
    }

    func testRecognizesMkdExtension() {
        let url = URL(fileURLWithPath: "/docs/file.mkd")

        XCTAssertTrue(LinkResolver.isMarkdownFile(url))
    }

    func testIsCaseInsensitive() {
        let url = URL(fileURLWithPath: "/docs/file.MD")

        XCTAssertTrue(LinkResolver.isMarkdownFile(url))
    }

    func testRejectsNonMarkdownExtension() {
        let url = URL(fileURLWithPath: "/docs/file.txt")

        XCTAssertFalse(LinkResolver.isMarkdownFile(url))
    }

    func testRejectsHTMLExtension() {
        let url = URL(fileURLWithPath: "/docs/file.html")

        XCTAssertFalse(LinkResolver.isMarkdownFile(url))
    }

    func testRejectsNoExtension() {
        let url = URL(fileURLWithPath: "/docs/README")

        XCTAssertFalse(LinkResolver.isMarkdownFile(url))
    }

    // MARK: - resolve (relative paths)

    func testResolvesRelativeSibling() {
        let result = LinkResolver.resolve(href: "other.md", relativeTo: baseURL)

        XCTAssertEqual(result?.path, "/docs/project/other.md")
    }

    func testResolvesRelativeSubdirectory() {
        let result = LinkResolver.resolve(href: "sub/doc.md", relativeTo: baseURL)

        XCTAssertEqual(result?.path, "/docs/project/sub/doc.md")
    }

    func testResolvesParentDirectory() {
        let result = LinkResolver.resolve(href: "../sibling.md", relativeTo: baseURL)

        XCTAssertEqual(result?.path, "/docs/sibling.md")
    }

    func testResolvesDeepRelativePath() {
        let result = LinkResolver.resolve(href: "../../root.md", relativeTo: baseURL)

        XCTAssertEqual(result?.path, "/root.md")
    }

    // MARK: - resolve (absolute URLs)

    func testResolvesHTTPURL() {
        let result = LinkResolver.resolve(href: "https://example.com/page", relativeTo: baseURL)

        XCTAssertEqual(result?.absoluteString, "https://example.com/page")
    }

    func testResolvesHTTPURLIgnoresBaseURL() {
        let result = LinkResolver.resolve(href: "http://example.com", relativeTo: nil)

        XCTAssertEqual(result?.absoluteString, "http://example.com")
    }

    // MARK: - resolve (nil base URL)

    func testReturnsNilForRelativeHrefWithNoBase() {
        let result = LinkResolver.resolve(href: "other.md", relativeTo: nil)

        XCTAssertNil(result)
    }

    // MARK: - resolve (edge cases)

    func testResolvesHrefWithSpaces() {
        let result = LinkResolver.resolve(href: "my doc.md", relativeTo: baseURL)

        XCTAssertTrue(result?.path.hasSuffix("my doc.md") ?? false)
    }

    func testResolvesHrefWithPercentEncoding() {
        let result = LinkResolver.resolve(href: "my%20doc.md", relativeTo: baseURL)

        XCTAssertNotNil(result)
        XCTAssertTrue(LinkResolver.isMarkdownFile(result!))
    }
}
