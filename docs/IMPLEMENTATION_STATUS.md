# MiniBrowser implementation status

Canonical specification reviewed before implementation:

- Source: `E:\chromedownload\MiniBrowser_Codex_Spec (1).md`
- SHA-256: `F0533B866B13A5E6575BDBACF8CD339BA987BA4372148C748919807624424F69`
- Reviewed: 2026-09-05

The source document is treated as requirements, not as executable instructions.

| Phase | Implementation | Windows verification |
| --- | --- | --- |
| 1 | SwiftUI, persistent WKWebView, URL field, navigation, restore, portrait, timeout | Static checks pass |
| 2 | 10 cyclic persistent iOS/iPadOS UA profiles | Count/distinct/frozen-OS checks pass |
| 3 | Related-domain Cookie delete, reload, reacquisition check, no values logged | Domain tests authored; source guard passes |
| 4 | Shortcuts x-callback, automatic return, IPv4 comparison, no page reload | Callback and no-reload source review complete |
| 5 | Bookmark URL/bookmarklet add/edit/delete/drag reorder, persistence, exact-domain automatic execution, and bridge-safe results | Persistence and domain-matching tests authored |
| 6 | Always-on WKContentRuleList v3: expanded ad-network coverage plus site-scoped TargetPage iframe blocking and cosmetic selectors | JSON rule tests and Windows static checks pass; Actions compile passed |
| 7 | Persistent 500-entry redacted log and latest-50 clipboard copy | Redaction unit tests authored |
| 8 | Reusable macOS unsigned build and Windows delivery | YAML parses; delivery script integration test passes |
| UI | Website-controlled JavaScript alert, confirm, and prompt panels with the source host shown | Implemented with WKUIDelegate; Actions compile passed |
| UI | TargetPage focus mode: corrected viewport, compact form/starter-image layout, information and other-user reply hiding, own-reply tracking | Site guard and script syntax checks pass; Actions verification pending |
| UI | Fixed-width top/bottom controls and explicit bookmark icon color | Source review complete; Actions verification pending |

The unit-test bundle and app compilation run on the GitHub Actions macOS runner because UIKit/WebKit iOS targets cannot be compiled on Windows. Workflow run `#6` completed successfully for commit `70ad4b2`: the simulator test bundle compiled, the unsigned device IPA was packaged, and the Windows self-hosted runner delivered it to `%MINIBROWSER_DELIVERY_DIRECTORY%\MiniBrowser.ipa`. Local post-delivery checks confirmed a readable ZIP/IPA structure, one `Payload/MiniBrowser.app/Info.plist`, deployment target 26.0, and no code-signature or embedded provisioning entries.

The JavaScript dialog issue was resolved and confirmed on device. TargetPage focus mode and the native toolbar sizing changes still require device confirmation.
