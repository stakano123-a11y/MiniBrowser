import SwiftUI
import UIKit
import WebKit

struct BrowserWebView: UIViewRepresentable {
    @ObservedObject var model: BrowserViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        Task { @MainActor [weak webView] in
            guard let webView else { return }
            do {
                try await ContentBlockerService.install(on: configuration.userContentController)
            } catch {
                model.contentBlockerFailed(error: error)
            }
            model.attach(webView: webView)
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private let model: BrowserViewModel
        private var timeoutTimer: Timer?

        init(model: BrowserViewModel) {
            self.model = model
        }

        deinit {
            timeoutTimer?.invalidate()
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url,
                  let scheme = url.scheme?.lowercased() else {
                decisionHandler(.cancel)
                return
            }

            if ["http", "https", "about"].contains(scheme) {
                decisionHandler(.allow)
            } else {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            startTimeout(for: webView)
            model.navigationStarted()
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            model.navigationCommitted(url: webView.url)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            cancelTimeout()
            model.navigationFinished(url: webView.url)
        }

        func webView(_ webView: WKWebView,
                     didFail navigation: WKNavigation!,
                     withError error: Error) {
            handleFailure(webView: webView, error: error)
        }

        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: Error) {
            handleFailure(webView: webView, error: error)
        }

        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil,
               let url = navigationAction.request.url {
                if ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                    webView.load(navigationAction.request)
                } else {
                    UIApplication.shared.open(url)
                }
            }
            return nil
        }

        private func startTimeout(for webView: WKWebView) {
            cancelTimeout()
            let timer = Timer(timeInterval: 30, repeats: false) { [weak self, weak webView] _ in
                guard let self, let webView, webView.isLoading else { return }
                webView.stopLoading()
                self.model.navigationTimedOut(url: webView.url)
            }
            timeoutTimer = timer
            RunLoop.main.add(timer, forMode: .common)
        }

        private func cancelTimeout() {
            timeoutTimer?.invalidate()
            timeoutTimer = nil
        }

        private func handleFailure(webView: WKWebView, error: Error) {
            cancelTimeout()
            if (error as NSError).code == NSURLErrorCancelled { return }
            model.navigationFailed(url: webView.url, error: error)
        }
    }
}
