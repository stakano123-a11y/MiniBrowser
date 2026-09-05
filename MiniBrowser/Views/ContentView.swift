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
                    .foregroundStyle(.blue)
                    .frame(width: 30, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("ブックマーク")

            URLTextField(text: $model.urlText, onGo: model.openURLFromField)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36, maxHeight: 36)
                .layoutPriority(1)

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
        GeometryReader { geometry in
            let buttonWidth = geometry.size.width / 6
            HStack(spacing: 0) {
                toolbarButton("chevron.backward", label: "戻る", width: buttonWidth,
                              enabled: model.canGoBack, action: model.goBack)
                toolbarButton("chevron.forward", label: "進む", width: buttonWidth,
                              enabled: model.canGoForward, action: model.goForward)
                toolbarButton("arrow.clockwise", label: "更新", width: buttonWidth,
                              action: model.reload)
                toolbarTextButton(model.userAgentButtonTitle,
                                  width: buttonWidth,
                                  enabled: !model.isUAChanging,
                                  action: model.cycleUserAgent)
                toolbarTextButton("Cookie",
                                  width: buttonWidth,
                                  enabled: !model.isCookieRefreshing && !model.isLoading,
                                  action: model.refreshCookies)
                toolbarTextButton("AP",
                                  width: buttonWidth,
                                  enabled: !model.isAPRunning,
                                  action: model.startCellularReconnect)
            }
        }
        .frame(height: 48)
        .background(.bar)
        .contextMenu {
            Button("ログをコピー", action: model.copyDebugLog)
        }
    }

    private func toolbarButton(_ systemName: String,
                               label: String,
                               width: CGFloat,
                               enabled: Bool = true,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .frame(width: width, height: 48)
        }
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    private func toolbarTextButton(_ title: String,
                                   width: CGFloat,
                                   enabled: Bool = true,
                                   action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: width, height: 48)
        }
            .disabled(!enabled)
    }
}
