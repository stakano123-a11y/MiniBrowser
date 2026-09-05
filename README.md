# MiniBrowser

MiniBrowser is a lightweight iPhone browser built with SwiftUI and `WKWebView`. It targets iOS 26 and is designed to be built unsigned on GitHub Actions, then re-signed and installed with SideStore.

## MVP features

- URL-only navigation, current URL tracking, last URL restoration, back/forward/reload, and a 30-second timeout
- Ten persistent iOS/iPadOS-style User-Agent profiles
- Current-host and parent-domain Cookie deletion followed by reload and verified reacquisition
- `セルラー再接続` through Apple's Shortcuts x-callback URL, automatic return, and public IPv4 comparison without reloading the page
- Local bookmarks and unlimited-length multiline bookmarklets with edit/delete/drag reorder and exact-domain automatic execution
- Conservative always-on `WKContentRuleList` ad/tracker blocking
- A focused `img.targethost.net` thread layout that keeps the reply form, thread image, and locally tracked own replies
- A 500-entry redacted debug log; long-press the bottom toolbar and choose `ログをコピー` to copy the latest 50 entries
- Reusable GitHub Actions unsigned IPA build and Windows/iCloud Drive delivery

## Build flow

1. Push the project to a GitHub repository whose default branch is `main`.
2. The caller workflow generates `MiniBrowser.xcodeproj` with XcodeGen on `macos-26` and builds with code signing disabled.
3. It packages and validates `MiniBrowser.ipa`, uploads the IPA without an extra ZIP wrapper, and writes a SHA-256 artifact.
4. A Windows self-hosted runner with the `ios-ipa-delivery` label downloads and validates the IPA.
5. The runner overwrites only `%MINIBROWSER_DELIVERY_DIRECTORY%\MiniBrowser.ipa` and verifies its SHA-256.
6. Open that IPA from the iPhone and let SideStore sign/install it.

No Apple credentials, certificates, provisioning profiles, pairing files, or device identifiers belong in GitHub.

## Local checks on Windows

```powershell
.\scripts\Static-Check.ps1
```

Windows cannot compile this iOS target. The authoritative compile/test check is the GitHub Actions macOS job. See [Windows runner setup](docs/WINDOWS_RUNNER_SETUP.md) for the one-time runner registration.

## Implementation notes

- Cookie matching accepts an exact host or a cookie parent domain only; it does not clear unrelated WebKit data or LocalStorage.
- AP callback uses `shortcuts://x-callback-url/run-shortcut` with success/cancel/error callbacks to `minibrowser://return`. Returning never reloads the page.
- Public IPv4 comes from the replaceable `IPAddressService` endpoint (`https://api.ipify.org?format=json`) with an 8-second request timeout.
- Browser-family UA tokens are representative hardcoded profiles. iOS 26 freezes the OS portion at the final iOS 18 value for compatibility; changing a UA does not change the underlying WebKit engine.
- Automatic bookmarklets run only when the configured domain exactly matches the current host. Their stored source is unchanged; execution forces a bridgeable Boolean completion value.
- TargetPage focus mode runs only on `img.targethost.net/*/res/*.htm`. Pending reply text stays in per-tab session storage until matched or expired; persistent history contains response numbers only.

Primary references:

- [Apple WKWebView customUserAgent](https://developer.apple.com/documentation/webkit/wkwebview/customuseragent)
- [Apple WKWebsiteDataStore](https://developer.apple.com/documentation/webkit/wkwebsitedatastore)
- [Apple WKContentRuleList](https://developer.apple.com/documentation/webkit/wkcontentrulelist)
- [Apple Shortcuts x-callback-url](https://support.apple.com/guide/shortcuts/use-x-callback-url-apdcd7f20a6f/ios)
- [WebKit: Safari 26 UA string change](https://webkit.org/blog/17333/webkit-features-in-safari-26-0/#update-to-ua-string)
- [GitHub-hosted runner images](https://github.com/actions/runner-images)
- [GitHub self-hosted runners](https://docs.github.com/en/actions/reference/runners/self-hosted-runners)
- [ipify API](https://www.ipify.org/)
