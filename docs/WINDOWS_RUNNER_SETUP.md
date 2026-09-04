# Windows self-hosted runner setup

The workflow performs the iOS build only on GitHub's `macos-26` runner. The Windows runner waits for a job, downloads one small IPA artifact, validates it, and copies it to iCloud Drive. It does not poll GitHub or build the app.

## One-time setup

1. Create or select the GitHub repository that contains this project.
2. In that repository, open **Settings → Actions → Runners → New self-hosted runner**.
3. Choose **Windows / x64** and run GitHub's generated commands in an elevated PowerShell window. GitHub recommends `C:\actions-runner` for service installations.
4. During configuration, add the custom label `ios-ipa-delivery` and install the runner as a Windows service if delivery should work without an open terminal.
5. Confirm that the runner has all four labels: `self-hosted`, `Windows`, `X64`, and `ios-ipa-delivery`.
6. Keep the runner current enough for Node 24-based actions (`actions/checkout@v6` requires runner 2.329.0 or later for all supported scenarios).
7. Confirm that the service account can write to `%MINIBROWSER_DELIVERY_DIRECTORY%`. Running the service under a system account may not have access to the signed-in user's iCloud Drive; use the signed-in user account if necessary.
8. Confirm the directory already exists. The delivery script intentionally does not create or guess a replacement iCloud path.

The registration token shown by GitHub is short-lived. Do not commit it, an Apple ID, a password, a certificate, a provisioning profile, a pairing file, or a device identifier.

## Reuse for another iOS app

Create a small caller workflow like `.github/workflows/minibrowser.yml` and change only `app_name` and `destination_filename` when the scheme/project follow the app-name convention. With direct uploads, the IPA filename is also the GitHub artifact name. Optional overrides remain available for unusual project names. Keep the reusable workflow and `scripts/Deliver-Ipa.ps1` unchanged.

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
