import Foundation

enum URLNormalizer {
    static func normalize(_ input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let candidate: String
        if trimmed.range(of: #"^[A-Za-z][A-Za-z0-9+.-]*://"#,
                         options: .regularExpression) == nil {
            candidate = "https://\(trimmed)"
        } else {
            candidate = trimmed
        }

        guard let url = URL(string: candidate),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            return nil
        }
        return url
    }
}

