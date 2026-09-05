# Windows self-hosted runner setup

The workflow performs the iOS build only on GitHub's `macos-26` runner. The Windows runner waits for a job, downloads one small IPA artifact, validates it, and copies it to iCloud Drive. It does not poll GitHub or build the app.

## One-time setup

1. Create or select the GitHub repository that contains this project.
2. In that repository, open **Settings → Actions → Runners → New self-hosted runner**.
3. Choose **Windows / x64** and run GitHub's generated commands. GitHub recommends `C:\actions-runner` to avoid path and service-identity issues.
4. During configuration, add the custom label `ios-ipa-delivery`. For an iCloud destination, run under the signed-in Windows user: either use a service configured with that account, or create a logon task that starts `C:\actions-runner\run.cmd` hidden.
5. Confirm that the runner has all four labels: `self-hosted`, `Windows`, `X64`, and `ios-ipa-delivery`.
6. Keep the runner current enough for Node 24-based actions (`actions/checkout@v6` requires runner 2.329.0 or later for all supported scenarios).
7. Confirm that the service account can write to `%MINIBROWSER_DELIVERY_DIRECTORY%`. Running the service under a system account may not have access to the signed-in user's iCloud Drive; use the signed-in user account if necessary.
8. Confirm the directory already exists. The delivery script intentionally does not create or guess a replacement iCloud path.

On this PC the runner is registered as `MiniBrowser-Windows`. Task Scheduler entry `GitHub Actions MiniBrowser Delivery` starts it at logon as user `staka`, with limited privileges. This avoids granting a system service access to the user's iCloud Drive. The runner must be online before dispatching an IPA workflow. If the task was created after the current Windows sign-in, start it once from Task Scheduler; it will run automatically at subsequent sign-ins. The macOS build can still finish while it is offline, but a job queued before the runner was online may need the delivery-only workflow below.

The registration token shown by GitHub is short-lived. Do not commit it, an Apple ID, a password, a certificate, a provisioning profile, a pairing file, or a device identifier.

## Reuse for another iOS app

Create a small caller workflow like `.github/workflows/minibrowser.yml` and change only `app_name` and `destination_filename` when the scheme/project follow the app-name convention. With direct uploads, the IPA filename is also the GitHub artifact name. Optional overrides remain available for unusual project names. Keep the reusable workflow and `scripts/Deliver-Ipa.ps1` unchanged.

When an unsigned IPA artifact already exists but Windows delivery was queued while the runner was offline, run `Deliver an existing unsigned IPA` manually. Enter the successful build run ID and its IPA artifact name; this Windows-only workflow downloads, validates, and replaces the requested file without consuming another macOS build.

## Safe local delivery test

After an IPA exists locally, run:

```powershell
.\scripts\Deliver-Ipa.ps1 `
  -SourceDirectory 'C:\path\to\artifact' `
  -SourceFileName 'AppA.ipa' `
  -DestinationDirectory '%MINIBROWSER_DELIVERY_DIRECTORY%' `
  -DestinationFileName 'AppA.ipa'
```

The script validates the IPA structure, stages a temporary copy, compares SHA-256 before and after delivery, then overwrites only the requested destination filename.

Official references:

- [Adding self-hosted runners](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/add-runners)
- [Using self-hosted runner labels](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/use-in-a-workflow)
