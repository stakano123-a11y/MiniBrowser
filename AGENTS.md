# MiniBrowser project rules

## Canonical source

- The canonical repository is `https://github.com/project-maintainer/MiniBrowser`.
- Keep application source, XcodeGen configuration, workflows, scripts, tests, documentation, and issue tracking in this repository.
- Treat `main` as the integration branch. Do not create an independent authoritative copy elsewhere.
- `MiniBrowser_Codex_Spec.md` is the baseline product specification. A later explicit user requirement may extend or override it; record lasting changes in repository documentation.

## Product constraints

- Support iPhone on iOS 26 or later only.
- Use SwiftUI with `WKWebView`; generate the Xcode project with XcodeGen.
- Development and static checks run on Windows 11. Do not require a local Mac.
- Build unsigned IPA files on a GitHub-hosted macOS runner. SideStore performs device signing and installation.
- Prioritize stability, then low resource use, few operations, debuggability, and simple UI.
- Implement the requested MVP directly. Do not add settings screens, tabs, search engines, or unrelated features.
- Do not change specified user operations or persistence behavior without an explicit requirement.

## Security and data handling

- Never log or commit Cookie values, passwords, authentication tokens, form contents, Apple credentials, certificates, provisioning profiles, pairing files, or device secrets.
- Cookie refresh may delete only cookies related to the current host and its parent domain. It must not clear LocalStorage or unrelated WebKit data.
- Changing User-Agent must retain cookies, LocalStorage, and navigation history.
- Returning from `セルラー再接続` must not reload the current page.
- Bookmarklet source must not be silently shortened or rewritten.

## Implementation and verification

- Preserve existing working behavior and unrelated user changes.
- Keep the Windows delivery workflow reusable across iOS applications; app name, artifact name, and destination filename must remain inputs.
- MiniBrowser delivery must replace only `%MINIBROWSER_DELIVERY_DIRECTORY%\MiniBrowser.ipa`.
- Before push, run `.\scripts\Static-Check.ps1`, `git diff --check`, and JavaScript syntax checks when injected scripts change.
- GitHub Actions must run XCTest on an iPhone Simulator, build with code signing disabled, validate the IPA ZIP structure, and deliver it through the Windows self-hosted runner.
- After delivery, verify `Payload/MiniBrowser.app`, minimum OS 26.0, absence of signature/provisioning entries, and SHA-256.
- Device-only behavior remains unconfirmed until tested on the reporting iPhone; do not close such work solely because Simulator tests pass.

## Issues and change handoff

- Use GitHub Issues as the handoff point for development tasks, bugs, and device verification.
- A bug issue should contain reproduction steps, environment, evidence or logs, expected behavior, and completion criteria.
- A development issue should state the requested outcome, scope boundaries, and acceptance checks.
- Reference the relevant issue from commits when practical. Close an issue only after its acceptance criteria are satisfied.
- Keep `README.md` and `docs/IMPLEMENTATION_STATUS.md` aligned with meaningful implemented and delivered changes.
