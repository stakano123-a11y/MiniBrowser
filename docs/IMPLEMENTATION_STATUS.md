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
| 6 | Always-on conservative WKContentRuleList with future exclusion input | JSON rule unit test authored |
| 7 | Persistent 500-entry redacted log and latest-50 clipboard copy | Redaction unit tests authored |
| 8 | Reusable macOS unsigned build and Windows delivery | YAML parses; delivery script integration test passes |

The unit-test bundle and app compilation must run on the GitHub Actions macOS runner because UIKit/WebKit iOS targets cannot be compiled on Windows. A GitHub remote and registered Windows self-hosted runner are not currently present on this PC, so the live workflow and real-device checks remain pending.
