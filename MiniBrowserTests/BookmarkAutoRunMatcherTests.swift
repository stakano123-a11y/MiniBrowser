import XCTest
@testable import MiniBrowser

final class BookmarkAutoRunMatcherTests: XCTestCase {
    func testNormalizesDomainOrFullURL() {
        XCTAssertEqual(BookmarkAutoRunMatcher.normalizedDomain(" IMG.2CHAN.NET "),
                       "img.2chan.net")
        XCTAssertEqual(BookmarkAutoRunMatcher.normalizedDomain("https://img.2chan.net/b/res/1.htm"),
                       "img.2chan.net")
    }

    func testMatchingIsExactAndDoesNotLeakToSiblingDomains() {
        XCTAssertTrue(BookmarkAutoRunMatcher.matches(host: "img.2chan.net",
                                                     configuredDomain: "img.2chan.net"))
        XCTAssertFalse(BookmarkAutoRunMatcher.matches(host: "may.2chan.net",
                                                      configuredDomain: "img.2chan.net"))
        XCTAssertFalse(BookmarkAutoRunMatcher.matches(host: "notimg.2chan.net",
                                                      configuredDomain: "img.2chan.net"))
    }

    func testRejectsInvalidDomain() {
        XCTAssertNil(BookmarkAutoRunMatcher.normalizedDomain("img..2chan.net"))
        XCTAssertNil(BookmarkAutoRunMatcher.normalizedDomain("javascript:alert(1)"))
    }
}
