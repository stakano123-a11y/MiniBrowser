import XCTest
@testable import MiniBrowser

final class URLNormalizerTests: XCTestCase {
    func testAddsHTTPSWhenSchemeIsMissing() {
        XCTAssertEqual(URLNormalizer.normalize("example.com/path")?.absoluteString,
                       "https://example.com/path")
    }

    func testKeepsHTTPAndHTTPS() {
        XCTAssertEqual(URLNormalizer.normalize("http://example.com")?.absoluteString,
                       "http://example.com")
        XCTAssertEqual(URLNormalizer.normalize("https://example.com?a=1")?.absoluteString,
                       "https://example.com?a=1")
    }

    func testRejectsUnsupportedSchemeAndSearchText() {
        XCTAssertNil(URLNormalizer.normalize("javascript:alert(1)"))
        XCTAssertNil(URLNormalizer.normalize("two words"))
    }
}
