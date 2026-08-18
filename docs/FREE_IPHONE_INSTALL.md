# Free iPhone installation from Windows

Catch Up has a free AltStore edition that keeps the AlarmKit alarm, finite briefing, streaks, local progress, and optional live-news backend. It omits Screen Time app shielding because that capability requires Apple-managed provisioning.

## What Codex prepared

- `project.free.yml` creates an entitlement-free `CatchUpFree` target.
- `.github/workflows/build-altstore.yml` builds the unsigned IPA on GitHub's macOS runner.
- The workflow publishes `CatchUp-Free.ipa` as a GitHub Release.
- The workflow publishes `source.json` and the app icon alongside the IPA in a GitHub Release.

## One-time setup

1. Create a free GitHub account if you do not already have one.
2. Create a **public** repository. `catch-up` is a good name.
3. Upload the contents of this `CatchUp` folder to the repository root. The `.github` folder must be included.
4. Open **Settings → Actions → General**. Under **Workflow permissions**, select **Read and write permissions**, then save.
5. Open **Actions → Build and publish AltStore edition → Run workflow**.
6. The workflow is already configured for `com.github.sarva12.CatchUpFree` and developer name `sarva12`. Review those values, then run it.
7. Wait for the green checkmark. The release contains `CatchUp-Free.ipa`, `source.json`, and `CatchUp-AppIcon-1024.png`.

## Put it on the iPhone

1. Install AltServer on Windows and use it to install AltStore Classic on the iPhone.
2. Keep the iPhone and PC on the same Wi-Fi and leave AltServer running.
3. In AltStore Classic, open **Sources**, tap **+**, and paste:

   `https://github.com/sarva12/catch-up/releases/download/v1.0.0/source.json`
4. Open the Catch Up source and install the app. AltStore signs it locally using your free Apple Account.
5. Open Catch Up, allow Alarm access, and set the daily alarm.

Free Apple Account installations expire after seven days. AltStore can refresh them while the iPhone can reach AltServer on the Windows PC. Open AltStore periodically to verify that the refresh succeeded.

## Important behavior

The iPhone always retains its normal Stop alarm control. Apple does not allow a third-party app to force-launch after Stop. Use the alarm's **Start Catch-up** action to stop the alarm and open the briefing.

