import XCTest
import UniformTypeIdentifiers
@testable import ReadDown

final class MarkdownDocumentTests: XCTestCase {
    func testReadableContentTypesIncludesMarkdown() {
        let types = MarkdownDocument.readableContentTypes

        XCTAssertTrue(types.contains(.markdown))
    }

    func testReadableContentTypesIncludesPlainText() {
        let types = MarkdownDocument.readableContentTypes

        XCTAssertTrue(types.contains(.plainText))
    }

    func testDefaultInitHasEmptyText() {
        let doc = MarkdownDocument()

        XCTAssertEqual(doc.text, "")
        XCTAssertNil(doc.fileURL)
    }

    func testInitWithText() {
        let doc = MarkdownDocument(text: "# Hello")

        XCTAssertEqual(doc.text, "# Hello")
    }

    func testInitWithFileURL() {
        let url = URL(fileURLWithPath: "/tmp/test.md")
        let doc = MarkdownDocument(text: "content", fileURL: url)

        XCTAssertEqual(doc.fileURL, url)
    }

    func testTextIsMutable() {
        var doc = MarkdownDocument(text: "before")

        doc.text = "after"

        XCTAssertEqual(doc.text, "after")
    }

    func testMarkdownUTTypeConformsToPlainText() {
        XCTAssertTrue(UTType.markdown.conforms(to: .plainText))
    }

    func testMarkdownUTTypeIdentifier() {
        XCTAssertEqual(UTType.markdown.identifier, "net.daringfireball.markdown")
    }

    func testTextSurvivesUTF8RoundTrip() {
        let original = "# Test\n\nHello, world!"
        let doc = MarkdownDocument(text: original)
        let data = doc.text.data(using: .utf8)!
        let restored = String(data: data, encoding: .utf8)

        XCTAssertEqual(restored, original)
    }

    func testUnicodeContentPreserved() {
        let original = "Caf\u{00E9} \u{1F680} \u{4F60}\u{597D}"
        let doc = MarkdownDocument(text: original)
        let data = doc.text.data(using: .utf8)!
        let restored = String(data: data, encoding: .utf8)

        XCTAssertEqual(restored, original)
    }

    func testEmptyTextProducesEmptyData() {
        let doc = MarkdownDocument(text: "")
        let data = doc.text.data(using: .utf8)!

        XCTAssertEqual(data.count, 0)
    }
}
