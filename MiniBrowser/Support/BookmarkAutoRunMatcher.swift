import Foundation

enum BookmarkAutoRunMatcher {
    static func normalizedDomain(_ input: String?) -> String? {
        guard var value = input?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(),
              !value.isEmpty else { return nil }

        if value.contains("://") {
            guard let components = URLComponents(string: value),
                  ["http", "https"].contains(components.scheme?.lowercased() ?? ""),
                  let host = components.host else { return nil }
            value = host.lowercased()
        } else {
            value = value.split(separator: "/", maxSplits: 1).first.map(String.init) ?? value
            let hostAndPort = value.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            if hostAndPort.count == 2,
               Int(hostAndPort[1]) == nil {
                return nil
            }
            value = String(hostAndPort[0])
        }

        while value.hasPrefix(".") {
            value.removeFirst()
        }
        while value.hasSuffix(".") {
            value.removeLast()
        }

        guard !value.isEmpty,
              value.range(of: "^[a-z0-9.-]+$", options: .regularExpression) != nil,
              !value.contains("..") else { return nil }
        return value
    }

    static func matches(host: String?, configuredDomain: String?) -> Bool {
        guard let host = host?.lowercased(),
              let domain = normalizedDomain(configuredDomain) else { return false }
        return host == domain
    }
}
