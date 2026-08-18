# Catch Up AltStore source

An AltStore Classic source is a publicly reachable JSON file describing an app and its downloadable `.ipa`. It does not compile the iOS source code.

## Before using this kit

The included `project.free.yml` and GitHub workflow build **CatchUp-Free.ipa** without Screen Time shielding. The workflow also performs all publishing steps in this document automatically. See `docs/FREE_IPHONE_INSTALL.md` for the shortest route.

## Recommended free hosting layout

Use a public GitHub repository named `catch-up`:

- GitHub Releases hosts `CatchUp-Free.ipa`.
- GitHub Pages hosts `source.json` and `CatchUp-AppIcon-1024.png`.

## Generate the finished source

From this directory, run:

```powershell
node generate-source.mjs `
  --ipa C:\path\to\CatchUp-Free.ipa `
  --owner YOUR_GITHUB_USERNAME `
  --repo catch-up `
  --bundle-id com.yourname.CatchUpFree `
  --developer "YOUR NAME"
```

The script reads the IPA, calculates its byte size and SHA-256, and creates `source.json`. The version and build values must match the compiled app exactly; override them with `--version` and `--build` if needed.

## Publish

1. Create a GitHub Release tagged `v1.0.0` and attach the IPA as `CatchUp-Free.ipa`.
2. Place the generated `source.json` and app icon at the root of the GitHub Pages branch.
3. Enable GitHub Pages for that branch.
4. Confirm these URLs open without signing in:
   - `https://YOUR_GITHUB_USERNAME.github.io/catch-up/source.json`
   - `https://YOUR_GITHUB_USERNAME.github.io/catch-up/CatchUp-AppIcon-1024.png`
   - The `downloadURL` contained inside `source.json`
5. In AltStore Classic on the iPhone, open **Sources**, tap **+**, and paste the `source.json` URL.

## Updating

For each update, upload the new IPA, then add its version object to the **beginning** of the app's `versions` array. AltStore treats the first compatible entry as the newest version.

## Important

- `bundleIdentifier`, `version`, `buildVersion`, permissions, size, and SHA-256 must match the IPA. AltStore verifies them.
- A free Apple Account must refresh sideloaded apps every seven days.
- Keep AltServer running on the Windows computer and the iPhone on the same Wi-Fi when refreshing.

