# Verification report

Date: August 18, 2026

## Passed in this workspace

- All four Node backend tests pass.
- Every backend `.mjs` file passes `node --check`.
- JSON asset and deployment files parse successfully.
- Property lists, entitlements, and privacy manifests parse as XML.
- Swift source files pass structural brace checks.
- The bundle-ID replacement script was run against a clean copy; it replaced the main ID, monitor ID, App Group entitlement, and shared Swift constant without leaving backup files.
- The App Store icon is exactly 1024×1024 and registered in the asset catalog.
- No Perplexity-style secret was found in the product tree.

## Requires Apple's toolchain

This workspace is Windows-based and has no Xcode or iOS SDK. The following checks are intentionally delegated to the included macOS CI workflow:

- XcodeGen project generation
- Swift 6 compilation against the final iOS 26 SDK
- iOS Simulator unit tests
- Code-signing and provisioning-profile validation
- TestFlight archive and upload

AlarmKit alerts, the open-app alarm action, Family Controls authorization, Device Activity scheduling, and Managed Settings shields must also be exercised on a physical iPhone. These system integrations cannot be faithfully tested on Windows or solely in a browser.

Do not describe the product as device-verified until the cloud build and physical-device checklist pass.


