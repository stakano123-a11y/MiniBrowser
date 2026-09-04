import SwiftUI

struct ContentView: View {
    @ObservedObject var model: BrowserViewModel
    @State private var showingBookmarks = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                topBar
                Divider()
                BrowserWebView(model: model)
                Divider()
                bottomBar
            }

            ToastStackView(toasts: model.toasts)
                .padding(.horizontal, 12)
                .padding(.bottom, 58)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showingBookmarks) {
            BookmarkListView(store: model.bookmarkStore,
                             currentURL: model.currentURL,
                             onOpen: model.openBookmark,
                             onValidateBookmarklet: model.validateBookmarklet)
        }
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            Button {
                showingBookmarks = true
            } label: {
                Image(systemName: "bookmark")
                    .frame(width: 30, height: 34)
            }
            .accessibilityLabel("ブックマーク")

            URLTextField(text: $model.urlText, onGo: model.openURLFromField)
                .frame(height: 36)

            if model.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 20)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.bar)
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            toolbarButton("chevron.backward", label: "戻る", enabled: model.canGoBack, action: model.goBack)
            toolbarButton("chevron.forward", label: "進む", enabled: model.canGoForward, action: model.goForward)
            toolbarButton("arrow.clockwise", label: "更新", action: model.reload)
            toolbarTextButton(model.userAgentButtonTitle,
                              enabled: !model.isUAChanging,
                              action: model.cycleUserAgent)
            toolbarTextButton("Cookie",
                              enabled: !model.isCookieRefreshing && !model.isLoading,
                              action: model.refreshCookies)
            toolbarTextButton("AP",
                              enabled: !model.isAPRunning,
                              action: model.startCellularReconnect)
        }
        .frame(height: 48)
        .background(.bar)
        .contextMenu {
            Button("ログをコピー", action: model.copyDebugLog)
        }
    }

    private func toolbarButton(_ systemName: String,
                               label: String,
                               enabled: Bool = true,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    private func toolbarTextButton(_ title: String,
                                   enabled: Bool = true,
                                   action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.caption.weight(.semibold))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .disabled(!enabled)
    }
}
