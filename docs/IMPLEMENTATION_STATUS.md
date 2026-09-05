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
| UI | TargetPage focus mode: corrected viewport, four-line opener image/text summary beside the form, surrounding site chrome and other-user reply hiding, own-reply tracking | DOM selectors verified against the live page; script syntax checks and Actions compile pass |
| UI | Fixed-width top/bottom controls and explicit bookmark icon color | Actions compile passed |
| UI | Prevent automatic focus zoom on form fields below 16 px while retaining manual pinch zoom, including dynamically inserted controls and subframes | Script syntax/static guards pass; Actions compile passed |
| UI | Compact TargetPage posting form with forced-empty Email, two-line comment field, disabled form-position switch, and global ON/OFF draft retention | Script syntax/static guards pass; Actions compile passed |
| UI | Collapsible 65/35 split view with a native two-column, 30-item official TargetPage list and bounded opener-text loading | Parser/request tests authored; Actions compile passed |

The unit-test bundle and app compilation run on the GitHub Actions macOS runner because UIKit/WebKit iOS targets cannot be compiled on Windows. Workflow run `#6` completed successfully for commit `70ad4b2`: the simulator test bundle compiled, the unsigned device IPA was packaged, and the Windows self-hosted runner delivered it to `%MINIBROWSER_DELIVERY_DIRECTORY%\MiniBrowser.ipa`. Local post-delivery checks confirmed a readable ZIP/IPA structure, one `Payload/MiniBrowser.app/Info.plist`, deployment target 26.0, and no code-signature or embedded provisioning entries.

Workflow run `#7` completed successfully for commit `bcad976` and delivered the focus-mode build to the fixed IPA path. The JavaScript dialog issue was resolved and confirmed on device. TargetPage focus mode and the native toolbar sizing changes still require device confirmation.

Workflow run `#8` completed successfully for commit `a8b4b49` and delivered the input-focus zoom build to the fixed IPA path. Local verification found SHA-256 `1E9F5AE160C17543D17EACBF50837132D04FB27FD2375AA9E17AFA479F3C5CCE`, a valid ZIP structure, deployment target 26.0, and no signature or embedded provisioning entries. Manual pinch zoom remains enabled by design; focus behavior requires device confirmation.

Workflow run `#9` completed successfully for commit `9d89209` and delivered the simplified TargetPage layout build to the fixed IPA path. Local verification found SHA-256 `E12B8CB33DF87E3BA6336882A7A91ECA2941EA492802A4E5FC2475CCE088F207`, a valid ZIP structure, deployment target 26.0, and no signature or embedded provisioning entries. Layout, posting, and own-reply visibility require device confirmation.

Workflow run `#10` completed successfully for commit `8fcefe5` and delivered the compact form and official-list split-view build to the fixed IPA path. Local verification found SHA-256 `E2D64E3830EBB919FE6A29B1B1FB7B500485DC30D15A5030C24CCC4803885C35`, a valid `Payload/MiniBrowser.app` ZIP structure, deployment target 26.0, and no signature or embedded provisioning entries. The split layout, sort switching, draft retention, posting, and own-reply visibility require device confirmation. The reusable workflow is subsequently updated to execute XCTest on an automatically selected available iPhone Simulator instead of only compiling the test bundle.

Workflow run `#11` completed successfully for commit `ddf9838`: all XCTest cases ran on an automatically selected iPhone Simulator, the unsigned device IPA was rebuilt, and the Windows self-hosted runner replaced the fixed delivery file. Local verification found SHA-256 `626320098A0DCB5A4DAA2A59D5E26B1A31417E46640B6AFD085F75524FFFDDAA`, deployment target 26.0, a valid `Payload/MiniBrowser.app` structure, and zero signature or embedded-provisioning entries.

An iPhone 14-class device on iOS 26.5.2 then reported an immediate `SIGABRT` in `swift::AsyncTask::completeFuture` / `__cxa_pure_virtual` while opener texts were loading. The four-child throwing task group was removed in favor of one cancellable sequential loader, eliminating the implicated concurrent future-completion path while retaining bounded Range requests and progressive list updates.
