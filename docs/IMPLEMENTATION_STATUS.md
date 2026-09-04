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
| 5 | Bookmark URL/bookmarklet add/edit/delete/drag reorder and persistence | Persistence/unit tests authored |
| 6 | Always-on WKContentRuleList v3: expanded ad-network coverage plus site-scoped TargetPage iframe blocking and cosmetic selectors | JSON rule tests authored; Windows static checks pass; Actions verification pending |
| 7 | Persistent 500-entry redacted log and latest-50 clipboard copy | Redaction unit tests authored |
| 8 | Reusable macOS unsigned build and Windows delivery | YAML parses; delivery script integration test passes |

The unit-test bundle and app compilation run on the GitHub Actions macOS runner because UIKit/WebKit iOS targets cannot be compiled on Windows. Workflow run `#4` completed successfully for commit `14eda29`: the simulator test bundle compiled, the unsigned device IPA was packaged, and the Windows self-hosted runner delivered it to `%MINIBROWSER_DELIVERY_DIRECTORY%\MiniBrowser.ipa`. Local post-delivery checks confirmed a valid ZIP/IPA structure, one `Payload/MiniBrowser.app/Info.plist`, deployment target 26.0, and no code-signature or embedded provisioning entries.

Known device issue to address next: JavaScript `alert`, `confirm`, and `prompt` messages emitted by websites are not presented because the corresponding `WKUIDelegate` handlers have not yet been implemented.
