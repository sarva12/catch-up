# Put Catch Up on an iPhone without owning a Mac

The supported route is a cloud macOS build uploaded to TestFlight. Apple still requires an Apple Developer Program membership for code signing and physical-device installation.

## Accounts

1. Join the Apple Developer Program.
2. In the Apple developer portal, register these identifiers using your own reverse-domain bundle ID:
   - `com.yourname.CatchUp`
   - `com.yourname.CatchUp.Monitor`
   - App Group: `group.com.yourname.CatchUp`
3. Enable **Family Controls** and the App Group for both app identifiers. Request Apple's Family Controls distribution entitlement for the app and monitor extension.
4. Create the Catch Up app record in App Store Connect.

## Cloud build with Codemagic

1. Put this project in a private GitHub repository.
2. Create a Codemagic account and add the repository.
3. In App Store Connect, create an API key with **App Manager** access and download its `.p8` file once.
4. In Codemagic, connect that key under **Team settings → Developer Portal** and name it `CatchUpAppStoreKey`.
5. Generate or upload an Apple Distribution certificate and provisioning profiles for both bundle IDs. The profiles must include the approved Family Controls and App Group entitlements.
6. Change both occurrences of `com.yourname.CatchUp` in `codemagic.yaml` to your registered main bundle ID.
7. Start the `Catch Up — TestFlight` workflow.
8. After the upload finishes, open App Store Connect in a browser and add the build to an internal TestFlight group.
9. Install Apple's **TestFlight** app from the App Store on the iPhone, accept the invitation, and install Catch Up.

## Live news

Deploy the `backend` folder to Vercel and add your Perplexity key plus a long random `CATCHUP_ACCESS_TOKEN` as secret environment variables. In Catch Up, open **Settings → News service**, paste the deployed HTTPS origin and access token, then tap **Save and refresh**. The iPhone stores this token in its Keychain.

## What cannot be bypassed

- Apple requires a paid developer membership for TestFlight distribution.
- Apple must approve the Family Controls distribution entitlement before the shielding version can be signed for distribution.
- Until live news is configured, the app intentionally runs with demo stories.

