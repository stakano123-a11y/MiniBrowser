import Foundation

enum WebDialogPolicy {
    private static let targetpageCookieRetryMessage = "cookieを有効にしてもう一度送信してください"

    static func shouldAutoDismissAlert(host: String?, message: String) -> Bool {
        guard host?.lowercased() == "img.2chan.net" else { return false }
        let normalized = message
            .precomposedStringWithCanonicalMapping
            .replacingOccurrences(of: #"\s+"#, with: "", options: .regularExpression)
            .lowercased()
        return normalized == targetpageCookieRetryMessage
    }
}
