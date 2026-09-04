import XCTest
@testable import MiniBrowser

final class ContentBlockerRuleProviderTests: XCTestCase {
    func testRulesAreValidJSONAndSupportFutureExceptions() throws {
        let rules = try decodedRules(excludingDomains: [" Example.COM "])

        XCTAssertGreaterThanOrEqual(rules.count, 30)
        for rule in rules {
            let trigger = try XCTUnwrap(rule["trigger"] as? [String: Any])
            XCTAssertEqual(trigger["unless-domain"] as? [String], ["*example.com"])
        }
    }

    func testNetworkRulesCoverAllResourceTypesButRemainThirdPartyOnly() throws {
        let rules = try decodedRules()
        let networkRules = rules.filter {
            ($0["action"] as? [String: Any])?["type"] as? String == "block"
        }

        XCTAssertGreaterThanOrEqual(networkRules.count, 30)
        for rule in networkRules {
            let trigger = try XCTUnwrap(rule["trigger"] as? [String: Any])
            XCTAssertEqual(trigger["load-type"] as? [String], ["third-party"])
            XCTAssertNil(trigger["resource-type"], "Omitting resource-type intentionally covers child documents, fetch, ping, popup, and future load types.")
        }

        let filters = networkRules.compactMap {
            ($0["trigger"] as? [String: Any])?["url-filter"] as? String
        }
        XCTAssertTrue(filters.contains { $0.contains("doubleclick\\.net") })
        XCTAssertTrue(filters.contains { $0.contains("googlesyndication\\.com") })
        XCTAssertTrue(filters.contains { $0.contains("microad\\.jp") })
    }

    func testCosmeticRuleUsesConservativeAdvertisingSelectors() throws {
        let rules = try decodedRules()
        let cosmeticRule = try XCTUnwrap(rules.first {
            ($0["action"] as? [String: Any])?["type"] as? String == "css-display-none"
        })
        let trigger = try XCTUnwrap(cosmeticRule["trigger"] as? [String: Any])
        let action = try XCTUnwrap(cosmeticRule["action"] as? [String: Any])
        let selector = try XCTUnwrap(action["selector"] as? String)

        XCTAssertEqual(trigger["url-filter"] as? String, ".*")
        XCTAssertTrue(selector.contains("ins.adsbygoogle"))
        XCTAssertTrue(selector.contains("iframe[src*='doubleclick.net']"))
        XCTAssertFalse(selector.contains("[class*='ad']"), "Avoid broad substring selectors that can hide normal content.")
    }

    private func decodedRules(excludingDomains: Set<String> = []) throws -> [[String: Any]] {
        let encoded = try ContentBlockerRuleProvider.encodedRules(excludingDomains: excludingDomains)
        let data = try XCTUnwrap(encoded.data(using: .utf8))
        let object = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(object as? [[String: Any]])
    }
}
