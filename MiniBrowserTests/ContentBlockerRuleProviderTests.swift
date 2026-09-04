import XCTest
@testable import MiniBrowser

final class ContentBlockerRuleProviderTests: XCTestCase {
    func testRulesAreValidJSONAndSupportFutureExceptions() throws {
        let encoded = try ContentBlockerRuleProvider.encodedRules(excludingDomains: ["example.com"])
        let data = try XCTUnwrap(encoded.data(using: .utf8))
        let object = try JSONSerialization.jsonObject(with: data)
        let rules = try XCTUnwrap(object as? [[String: Any]])
        XCTAssertFalse(rules.isEmpty)
        let trigger = try XCTUnwrap(rules.first?["trigger"] as? [String: Any])
        XCTAssertEqual(trigger["unless-domain"] as? [String], ["*example.com"])
    }
}
