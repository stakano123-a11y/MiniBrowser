import Foundation
import WebKit

enum ContentBlockerRuleProvider {
    private static let blockedDomains = [
        "2mdn.net",
        "ad-generation.jp",
        "ad-stir.com",
        "adform.net",
        "adingo.jp",
        "adnxs.com",
        "adsrvr.org",
        "adservice.google.com",
        "doubleclick.net",
        "amazon-adsystem.com",
        "casalemedia.com",
        "criteo.com",
        "criteo.net",
        "fluct.jp",
        "fout.jp",
        "geniee.jp",
        "googleadservices.com",
        "googlesyndication.com",
        "googletagservices.com",
        "i-mobile.co.jp",
        "logly.co.jp",
        "media.net",
        "microad.jp",
        "moatads.com",
        "nend.net",
        "openx.net",
        "outbrain.com",
        "pubmatic.com",
        "quantserve.com",
        "rubiconproject.com",
        "scorecardresearch.com",
        "smartadserver.com",
        "socdm.com",
        "taboola.com",
        "yieldmo.com",
        "zucks.net"
    ]

    private static let cosmeticSelectors = [
        "ins.adsbygoogle",
        ".google-auto-placed",
        "[id^='google_ads_']",
        "[id^='div-gpt-ad']",
        "[data-ad-client]",
        "[data-ad-slot]",
        "iframe[src*='doubleclick.net']",
        "iframe[src*='googlesyndication.com']",
        "iframe[src*='adnxs.com']",
        "iframe[src*='amazon-adsystem.com']",
        "[id^='taboola-']",
        ".taboola",
        ".OUTBRAIN",
        "[class~='ad-slot']",
        "[class~='ad-container']",
        "[class~='advertisement']",
        "[aria-label='広告']",
        "[aria-label='Advertisement']"
    ]

    // TargetPage serves ads from its own dec.2chan.net host, so the generic
    // third-party advertising rules above cannot catch them. Keep these
    // selectors specific to 2chan.net to avoid hiding similarly named content
    // on unrelated sites.
    private static let targetpageCosmeticSelectors = [
        "iframe[src^='https://dec.2chan.net/bin/']",
        "#ad-wrapper",
        "#ad-wrapper-overlay",
        "#rightad",
        "#rightadc",
        "#rightadfloat",
        "#radtop",
        ".tue",
        ".tue2",
        ".footfix",
        "#foot4n_left",
        "#foot4abdef_right",
        "div[style^='width:728px;height:90px']",
        "div[style^='width:300px;height:250px']",
        "div[style^='width:680px']",
        "div[style='width:610px;margin: 0 auto;']",
        "div[style='height:68px;']"
    ]

    static func encodedRules(excludingDomains: Set<String> = []) throws -> String {
        let normalizedExclusions = excludingDomains
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
            .sorted()
        let exceptions = normalizedExclusions.map { "*\($0)" }

        var rules: [[String: Any]] = blockedDomains.map { domain in
            var trigger: [String: Any] = [
                "url-filter": "^https?://([^/]+\\.)?\(NSRegularExpression.escapedPattern(for: domain))/",
                "load-type": ["third-party"]
            ]
            if !exceptions.isEmpty {
                trigger["unless-domain"] = exceptions
            }
            return [
                "trigger": trigger,
                "action": ["type": "block"]
            ]
        }

        var cosmeticTrigger: [String: Any] = ["url-filter": ".*"]
        if !exceptions.isEmpty {
            cosmeticTrigger["unless-domain"] = exceptions
        }
        rules.append([
            "trigger": cosmeticTrigger,
            "action": [
                "type": "css-display-none",
                "selector": cosmeticSelectors.joined(separator: ", ")
            ]
        ])

        let targetpageIsExcluded = normalizedExclusions.contains {
            $0 == "2chan.net" || $0.hasSuffix(".2chan.net")
        }
        if !targetpageIsExcluded {
            var targetpageNetworkTrigger: [String: Any] = [
                "url-filter": "^https?://dec\\.2chan\\.net/bin/",
                "resource-type": ["child-document"]
            ]
            if !exceptions.isEmpty {
                targetpageNetworkTrigger["unless-domain"] = exceptions
            }
            rules.append([
                "trigger": targetpageNetworkTrigger,
                "action": ["type": "block"]
            ])

            rules.append([
                "trigger": [
                    "url-filter": ".*",
                    "if-domain": ["*2chan.net"]
                ],
                "action": [
                    "type": "css-display-none",
                    "selector": targetpageCosmeticSelectors.joined(separator: ", ")
                ]
            ])
        }

        let data = try JSONSerialization.data(withJSONObject: rules, options: [])
        guard let json = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return json
    }
}

@MainActor
enum ContentBlockerService {
    static func install(on controller: WKUserContentController,
                        excludingDomains: Set<String> = []) async throws {
        let encoded = try ContentBlockerRuleProvider.encodedRules(excludingDomains: excludingDomains)
        let identifier = "MiniBrowser.LightBlocker.v3"

        let ruleList: WKContentRuleList = try await withCheckedThrowingContinuation { continuation in
            WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: identifier,
                encodedContentRuleList: encoded
            ) { list, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let list {
                    continuation.resume(returning: list)
                } else {
                    continuation.resume(throwing: CocoaError(.coderInvalidValue))
                }
            }
        }
        controller.add(ruleList)
    }
}
