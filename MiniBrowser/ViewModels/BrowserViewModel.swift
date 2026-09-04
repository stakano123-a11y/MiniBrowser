import Combine
import Foundation
import UIKit
import WebKit

@MainActor
final class BrowserViewModel: ObservableObject {
    private enum Keys {
        static let lastURL = "lastURL"
        static let userAgentIndex = "userAgentIndex"
    }

    @Published var urlText = ""
    @Published private(set) var currentURL: URL?
    @Published private(set) var canGoBack = false
    @Published private(set) var canGoForward = false
    @Published private(set) var isLoading = false
    @Published private(set) var isUAChanging = false
    @Published private(set) var isCookieRefreshing = false
    @Published private(set) var isAPRunning = false
    @Published private(set) var toasts: [ToastMessage] = []

    let bookmarkStore: BookmarkStore

    weak var webView: WKWebView?
    private let defaults: UserDefaults
    private let logStore: DebugLogStore
    private let ipService: IPAddressService
    private var selectedUAIndex: Int
    private var pendingCookieRefresh: PendingCookieRefresh?
    private var pendingAP: PendingAP?

    private struct PendingCookieRefresh {
        let host: String
        let beforeCount: Int
        let deletedCount: Int
        let deletionConfirmed: Bool
    }

    private struct PendingAP {
        let beforeIPv4: String?
    }

    init(defaults: UserDefaults = .standard,
         ipService: IPAddressService = IPAddressService()) {
        self.defaults = defaults
        self.logStore = DebugLogStore(defaults: defaults)
        self.bookmarkStore = BookmarkStore(defaults: defaults)
        self.ipService = ipService
        let savedIndex = defaults.integer(forKey: Keys.userAgentIndex)
        self.selectedUAIndex = BrowserUserAgent.all.indices.contains(savedIndex) ? savedIndex : 0
    }

    var currentUserAgent: BrowserUserAgent {
        BrowserUserAgent.all[selectedUAIndex]
    }

    var userAgentButtonTitle: String {
        "UA \(selectedUAIndex + 1)/\(BrowserUserAgent.all.count)"
    }

    func attach(webView: WKWebView) {
        guard self.webView !== webView else { return }
        self.webView = webView
        webView.customUserAgent = currentUserAgent.value

        if let saved = defaults.string(forKey: Keys.lastURL),
           let url = URLNormalizer.normalize(saved) {
            urlText = url.absoluteString
            webView.load(URLRequest(url: url))
        }
    }

    func openURLFromField() {
        guard let url = URLNormalizer.normalize(urlText) else {
            showToast("URLを確認してください", kind: .failure)
            return
        }
        urlText = url.absoluteString
        webView?.load(URLRequest(url: url))
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reload() {
        webView?.reload()
    }

    func cycleUserAgent() {
        guard !isUAChanging else { return }
        selectedUAIndex = (selectedUAIndex + 1) % BrowserUserAgent.all.count
        defaults.set(selectedUAIndex, forKey: Keys.userAgentIndex)
        webView?.customUserAgent = currentUserAgent.value
        showToast("UA変更: \(currentUserAgent.name) (\(selectedUAIndex + 1)/\(BrowserUserAgent.all.count))",
                  kind: .success)
        logStore.append(action: "User Agent Change", fields: [
            ("URL", LogSanitizer.url(currentURL)),
            ("UA", "\(selectedUAIndex + 1)/\(BrowserUserAgent.all.count) \(currentUserAgent.name)"),
            ("RESULT", "CHANGED")
        ])

        if webView?.url != nil {
            isUAChanging = true
            webView?.reload()
        }
    }

    func refreshCookies() {
        guard !isCookieRefreshing,
              !isLoading,
              let webView,
              let host = webView.url?.host?.lowercased() else {
            showToast("Cookie確認失敗", kind: .warning)
            return
        }

        isCookieRefreshing = true
        Task { [weak self, weak webView] in
            guard let self, let webView else { return }
            let store = webView.configuration.websiteDataStore.httpCookieStore
            let before = await store.miniBrowserAllCookies()
            let targets = before.filter { CookieDomainMatcher.isRelated(cookieDomain: $0.domain, toHost: host) }

            guard !targets.isEmpty else {
                self.logCookieRefresh(host: host,
                                      before: 0,
                                      deleted: 0,
                                      after: 0,
                                      result: "NO_COOKIE")
                self.showToast("Cookieなし", kind: .warning)
                self.isCookieRefreshing = false
                return
            }

            for cookie in targets {
                await store.miniBrowserDelete(cookie)
            }

            let afterDeletion = await store.miniBrowserAllCookies()
            let remaining = afterDeletion.filter {
                CookieDomainMatcher.isRelated(cookieDomain: $0.domain, toHost: host)
            }
            let deletedCount = max(0, targets.count - remaining.count)
            self.pendingCookieRefresh = PendingCookieRefresh(host: host,
                                                             beforeCount: targets.count,
                                                             deletedCount: deletedCount,
                                                             deletionConfirmed: remaining.isEmpty)
            if webView.reload() == nil {
                self.failPendingCookieRefresh(result: "RELOAD_NOT_STARTED")
            }
        }
    }

    func startCellularReconnect() {
        guard !isAPRunning else { return }
        isAPRunning = true

        Task { [weak self] in
            guard let self else { return }
            let before = try? await ipService.fetchIPv4()
            self.pendingAP = PendingAP(beforeIPv4: before)

            guard let shortcutURL = Self.cellularReconnectURL(),
                  await Self.openExternalURL(shortcutURL) else {
                self.finishAPFailure(status: "SHORTCUT_OPEN_FAILED", before: before)
                return
            }
        }
    }

    func openBookmark(_ item: BookmarkItem) {
        switch item.kind {
        case .url:
            guard let url = URLNormalizer.normalize(item.content) else {
                showToast("URLを確認してください", kind: .failure)
                return
            }
            urlText = url.absoluteString
            webView?.load(URLRequest(url: url))
        case .bookmarklet:
            executeBookmarklet(item.content)
        }
    }

    func validateBookmarklet(_ source: String) {
        let script = Self.bookmarkletScript(from: source)
        guard let literal = Self.javaScriptStringLiteral(script) else {
            showToast("Bookmarklet構文を確認してください", kind: .warning)
            return
        }
        webView?.evaluateJavaScript("new Function(\(literal)); true;") { [weak self] _, error in
            if error != nil {
                self?.showToast("Bookmarklet構文を確認してください", kind: .warning)
            }
        }
    }

    func copyDebugLog() {
        let text = logStore.plainText(limit: 50)
        guard !text.isEmpty else {
            showToast("ログなし", kind: .warning)
            return
        }
        UIPasteboard.general.string = text
        showToast("ログをコピーしました", kind: .success)
    }

    func contentBlockerFailed(error: Error) {
        logStore.append(action: "Content Blocker Setup", fields: [
            ("ERROR_DOMAIN", (error as NSError).domain),
            ("ERROR_CODE", String((error as NSError).code)),
            ("DETAIL", error.localizedDescription),
            ("RESULT", "FAILED")
        ])
        showToast("広告ブロック初期化失敗", kind: .warning)
    }

    func navigationStarted() {
        isLoading = true
        refreshNavigationState()
    }

    func navigationCommitted(url: URL?) {
        updateCurrentURL(url)
        refreshNavigationState()
    }

    func navigationFinished(url: URL?) {
        isLoading = false
        isUAChanging = false
        updateCurrentURL(url)
        refreshNavigationState()
        if pendingCookieRefresh != nil {
            Task { [weak self] in
                await self?.completeCookieRefreshAfterReload()
            }
        }
    }

    func navigationFailed(url: URL?, error: Error) {
        isLoading = false
        isUAChanging = false
        updateCurrentURL(url)
        refreshNavigationState()
        showToast("読み込み失敗", kind: .failure)
        logStore.append(action: "Web Load Failure", fields: [
            ("URL", LogSanitizer.url(url)),
            ("UA", "\(selectedUAIndex + 1)/\(BrowserUserAgent.all.count) \(currentUserAgent.name)"),
            ("ERROR_DOMAIN", (error as NSError).domain),
            ("ERROR_CODE", String((error as NSError).code)),
            ("DETAIL", error.localizedDescription),
            ("RESULT", "FAILED")
        ])
        failPendingCookieRefresh(result: "RELOAD_FAILED")
    }

    func navigationTimedOut(url: URL?) {
        isLoading = false
        isUAChanging = false
        updateCurrentURL(url)
        refreshNavigationState()
        showToast("読み込みタイムアウト", kind: .failure)
        logStore.append(action: "Web Load Timeout", fields: [
            ("URL", LogSanitizer.url(url)),
            ("UA", "\(selectedUAIndex + 1)/\(BrowserUserAgent.all.count) \(currentUserAgent.name)"),
            ("TIMEOUT_SECONDS", "30"),
            ("RESULT", "TIMEOUT")
        ])
        failPendingCookieRefresh(result: "RELOAD_TIMEOUT")
    }

    func handleCallbackURL(_ url: URL) {
        guard url.scheme?.lowercased() == "minibrowser",
              url.host?.lowercased() == "return",
              isAPRunning,
              let context = pendingAP else { return }

        let status = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "status" })?.value ?? "success"
        guard status == "success" else {
            finishAPFailure(status: "CALLBACK_\(status.uppercased())", before: context.beforeIPv4)
            return
        }

        Task { [weak self] in
            guard let self else { return }
            let after = await self.fetchIPv4AfterRecovery()
            self.completeAP(before: context.beforeIPv4, after: after)
        }
    }

    func showToast(_ text: String, kind: ToastKind, duration: TimeInterval = 3.5) {
        let toast = ToastMessage(text: text, kind: kind)
        toasts.append(toast)

        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            self?.toasts.removeAll { $0.id == toast.id }
        }
    }

    private func updateCurrentURL(_ url: URL?) {
        guard let url, url.scheme != "about" else { return }
        currentURL = url
        urlText = url.absoluteString
        defaults.set(url.absoluteString, forKey: Keys.lastURL)
    }

    private func refreshNavigationState() {
        canGoBack = webView?.canGoBack ?? false
        canGoForward = webView?.canGoForward ?? false
    }

    private func executeBookmarklet(_ source: String) {
        guard let webView else {
            showToast("ブックマークレット実行失敗", kind: .failure)
            return
        }
        let script = Self.bookmarkletScript(from: source)
        webView.evaluateJavaScript(script) { [weak self] _, error in
            guard let self, let error else { return }
            self.showToast("ブックマークレット実行失敗", kind: .failure)
            self.logStore.append(action: "Bookmarklet Execution", fields: [
                ("URL", LogSanitizer.url(self.currentURL)),
                ("UA", "\(self.selectedUAIndex + 1)/\(BrowserUserAgent.all.count) \(self.currentUserAgent.name)"),
                ("ERROR_DOMAIN", (error as NSError).domain),
                ("ERROR_CODE", String((error as NSError).code)),
                ("DETAIL", error.localizedDescription),
                ("RESULT", "FAILED")
            ])
        }
    }

    private static func bookmarkletScript(from source: String) -> String {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let body: String
        if trimmed.lowercased().hasPrefix("javascript:") {
            body = String(trimmed.dropFirst("javascript:".count))
        } else {
            body = source
        }
        return body.removingPercentEncoding ?? body
    }

    private static func javaScriptStringLiteral(_ value: String) -> String? {
        guard let data = try? JSONEncoder().encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func completeCookieRefreshAfterReload() async {
        guard let pending = pendingCookieRefresh,
              let store = webView?.configuration.websiteDataStore.httpCookieStore else {
            return
        }
        let allAfterReload = await store.miniBrowserAllCookies()
        let after = allAfterReload.filter {
            CookieDomainMatcher.isRelated(cookieDomain: $0.domain, toHost: pending.host)
        }
        let success = pending.beforeCount > 0 && pending.deletionConfirmed && !after.isEmpty
        logCookieRefresh(host: pending.host,
                         before: pending.beforeCount,
                         deleted: pending.deletedCount,
                         after: after.count,
                         result: success ? "SUCCESS" : "FAILED")
        showToast(success ? "Cookie再取得済み" : "Cookie再取得失敗",
                  kind: success ? .success : .failure)
        pendingCookieRefresh = nil
        isCookieRefreshing = false
    }

    private func failPendingCookieRefresh(result: String) {
        guard let pending = pendingCookieRefresh else { return }
        logCookieRefresh(host: pending.host,
                         before: pending.beforeCount,
                         deleted: pending.deletedCount,
                         after: 0,
                         result: result)
        showToast("Cookie再取得失敗", kind: .failure)
        pendingCookieRefresh = nil
        isCookieRefreshing = false
    }

    private func logCookieRefresh(host: String,
                                  before: Int,
                                  deleted: Int,
                                  after: Int,
                                  result: String) {
        logStore.append(action: "Cookie Refresh", fields: [
            ("URL", LogSanitizer.url(currentURL)),
            ("DOMAIN", host),
            ("UA", "\(selectedUAIndex + 1)/\(BrowserUserAgent.all.count) \(currentUserAgent.name)"),
            ("COOKIE_BEFORE", String(before)),
            ("COOKIE_DELETED", String(deleted)),
            ("COOKIE_AFTER_RELOAD", String(after)),
            ("RESULT", result)
        ])
    }

    private static func cellularReconnectURL() -> URL? {
        var components = URLComponents()
        components.scheme = "shortcuts"
        components.host = "x-callback-url"
        components.path = "/run-shortcut"
        components.queryItems = [
            URLQueryItem(name: "name", value: "セルラー再接続"),
            URLQueryItem(name: "x-success", value: "minibrowser://return?status=success"),
            URLQueryItem(name: "x-cancel", value: "minibrowser://return?status=cancel"),
            URLQueryItem(name: "x-error", value: "minibrowser://return?status=error")
        ]
        return components.url
    }

    private static func openExternalURL(_ url: URL) async -> Bool {
        await withCheckedContinuation { continuation in
            UIApplication.shared.open(url, options: [:]) { opened in
                continuation.resume(returning: opened)
            }
        }
    }

    private func fetchIPv4AfterRecovery() async -> String? {
        let delays: [UInt64] = [1_500_000_000, 2_000_000_000, 3_000_000_000, 4_000_000_000]
        for delay in delays {
            try? await Task.sleep(nanoseconds: delay)
            if let value = try? await ipService.fetchIPv4() {
                return value
            }
        }
        return nil
    }

    private func completeAP(before: String?, after: String?) {
        let result: String
        if let before, let after {
            if before == after {
                result = "IP_UNCHANGED"
                showToast("IP変更なし", kind: .warning)
            } else {
                result = "IP_CHANGED"
                showToast("IP変更済み \(before) → \(after)", kind: .success, duration: 5)
            }
        } else {
            result = "IP_CHECK_FAILED"
            showToast("IP確認失敗", kind: .warning)
        }

        logStore.append(action: "Cellular Reconnect", fields: [
            ("IP_BEFORE", before ?? "UNAVAILABLE"),
            ("IP_AFTER", after ?? "UNAVAILABLE"),
            ("RESULT", result)
        ])
        pendingAP = nil
        isAPRunning = false
    }

    private func finishAPFailure(status: String, before: String?) {
        showToast("IP確認失敗", kind: .warning)
        logStore.append(action: "Cellular Reconnect", fields: [
            ("IP_BEFORE", before ?? "UNAVAILABLE"),
            ("IP_AFTER", "UNAVAILABLE"),
            ("CALLBACK_STATUS", status),
            ("RESULT", "FAILED")
        ])
        pendingAP = nil
        isAPRunning = false
    }
}

private extension WKHTTPCookieStore {
    func miniBrowserAllCookies() async -> [HTTPCookie] {
        await withCheckedContinuation { continuation in
            getAllCookies { continuation.resume(returning: $0) }
        }
    }

    func miniBrowserDelete(_ cookie: HTTPCookie) async {
        await withCheckedContinuation { continuation in
            delete(cookie) { continuation.resume() }
        }
    }
}
