# Catch Up

Catch Up is a local-first iPhone habit app that turns a morning alarm into a short, finite news briefing.

## Product behavior

1. Catch Up schedules a real repeating alarm with AlarmKit.
2. At the alarm time, an optional Screen Time monitor shields the distracting apps the user selected.
3. The alarm's **Start Catch-up** action opens the morning briefing.
4. The user reads a finite set of three to seven cited story summaries—there is no infinite feed.
5. Completing the set advances the daily streak and immediately removes the shields.

iOS always provides a standard Stop control. Apple does not allow Catch Up to force-launch itself when that control is used. The explicit **Start Catch-up** action is the supported path.

## Included

- SwiftUI iOS 26 app with onboarding, topic selection, adjustable briefing length, alarm management, catch-up feed, streaks, settings, accessibility labels, and offline cache.
- AlarmKit alarm and open-app Live Activity intent.
- Opt-in Family Controls picker, Device Activity monitor extension, and Managed Settings shields.
- Keychain-protected backend access token.
- Zero-dependency Node backend using Perplexity Sonar structured output and citation validation.
- Apple privacy manifests, privacy-policy draft, App Store metadata, unit tests, GitHub CI, and Codemagic TestFlight pipeline.
- Production 1024×1024 app icon.

## Modes

- **Demo mode:** Works without accounts or a backend and uses clearly labeled sample stories.
- **Live mode:** Enter the deployed backend HTTPS origin and private access token under **Settings → News service**.

## Build locally on a Mac

Requirements: Xcode 26+, XcodeGen, an iPhone running iOS 26+, and an Apple Developer account.

```sh
export BUNDLE_ID=com.yourname.CatchUp
bash scripts/configure_identifiers.sh
xcodegen generate
open CatchUp.xcodeproj
```

Select the development team in Xcode and run on a physical iPhone. AlarmKit and Screen Time behavior must be tested on-device.

## Build without owning a Mac

Follow [docs/INSTALL_WITHOUT_A_MAC.md](docs/INSTALL_WITHOUT_A_MAC.md) to build on Codemagic and install through TestFlight. A paid Apple Developer membership remains an Apple requirement.

For the free Apple Account edition without Screen Time shielding, follow [docs/SIDESTORE_INSTALL.md](docs/SIDESTORE_INSTALL.md). Its GitHub Actions workflow builds an unsigned SideStore-compatible IPA and publishes the IPA plus its AltSource JSON.

## Tests

```sh
cd backend && node --test
```

In Xcode, use **Product → Test** for the Swift streak and daily-reset tests. GitHub Actions runs the simulator build and tests on macOS after the project is pushed to a repository.

## Configuration that must be replaced before release

- Bundle IDs and App Group: use `scripts/configure_identifiers.sh`.
- Support email in `docs/PRIVACY.md` and `docs/APP_STORE_METADATA.md`.
- Privacy-policy public URL in App Store Connect.
- `PERPLEXITY_API_KEY` and `CATCHUP_ACCESS_TOKEN` in the backend host.
- Apple Family Controls distribution entitlement approval for both app IDs.
