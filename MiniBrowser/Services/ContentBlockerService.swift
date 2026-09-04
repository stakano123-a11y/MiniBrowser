import Foundation
import WebKit

enum ContentBlockerRuleProvider {
    private static let blockedDomains = [
        "doubleclick.net",
        "googlesyndication.com",
        "googleadservices.com",
        "amazon-adsystem.com",
        "criteo.com",
        "taboola.com",
        "outbrain.com",
        "scorecardresearch.com"
    ]

    static func encodedRules(excludingDomains: Set<String> = []) throws -> String {
        let resourceTypes = ["image", "style-sheet", "script", "font", "raw", "media", "popup"]
        let exceptions = excludingDomains.sorted().map { "*\($0)" }

        let rules: [[String: Any]] = blockedDomains.map { domain in
            var trigger: [String: Any] = [
                "url-filter": "^https?://([^/]+\\.)?\(NSRegularExpression.escapedPattern(for: domain))/",
                "resource-type": resourceTypes,
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
        let identifier = "MiniBrowser.LightBlocker.v1"

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

