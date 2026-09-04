import XCTest
@testable import MiniBrowser

final class CookieDomainMatcherTests: XCTestCase {
    func testMatchesCurrentHostAndParentDomain() {
        XCTAssertTrue(CookieDomainMatcher.isRelated(cookieDomain: "img.example.com",
                                                    toHost: "img.example.com"))
        XCTAssertTrue(CookieDomainMatcher.isRelated(cookieDomain: ".example.com",
                                                    toHost: "img.example.com"))
    }

    func testDoesNotMatchSiblingOrSuffixAttack() {
        XCTAssertFalse(CookieDomainMatcher.isRelated(cookieDomain: "www.example.com",
                                                     toHost: "img.example.com"))
        XCTAssertFalse(CookieDomainMatcher.isRelated(cookieDomain: "example.com",
                                                     toHost: "notexample.com"))
    }
}

