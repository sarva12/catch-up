# Install Catch Up with SideStore on Windows

Catch Up's free SideStore edition keeps the AlarmKit alarm, finite briefing, streaks, local progress, and optional live-news backend. It omits Screen Time app shielding because that capability requires Apple-managed provisioning.

Catch Up requires an iPhone running iOS 26 or later. SideStore itself also requires a passcode, an Apple Account, Wi-Fi, and a supported 64-bit Windows computer for its initial installation.

## Install SideStore

1. Follow SideStore's current [Prerequisites](https://docs.sidestore.io/docs/installation/prerequisites) guide.
2. Install **LocalDevVPN** on the iPhone, allow its VPN configuration, and connect it.
3. Install iTunes and **iloader** on Windows as described by SideStore.
4. Connect the unlocked iPhone by USB, trust the computer, open iloader, and sign in with your Apple Account.
5. Select the iPhone and choose **Install SideStore (Stable)**.
6. On the iPhone, trust the developer profile under **Settings → General → VPN & Device Management**.
7. Enable **Developer Mode** under **Settings → Privacy & Security** if requested.
8. Connect LocalDevVPN, open SideStore, sign in with the same Apple Account, open **My Apps**, and refresh SideStore once.

## Add and install Catch Up

1. In SideStore, open **Sources** and tap **+**.
2. Paste this source URL:

   `https://github.com/sarva12/catch-up/releases/download/v1.0.0/sidestore-source.json`

3. Add the source, open **Catch Up**, and tap **Install**.
4. Open Catch Up, allow Alarm access, and configure the daily alarm.

After SideStore is installed, this one-click link can also add the source:

`sidestore://source?url=https%3A%2F%2Fgithub.com%2Fsarva12%2Fcatch-up%2Freleases%2Fdownload%2Fv1.0.0%2Fsidestore-source.json`

## Refreshing

Keep LocalDevVPN connected whenever SideStore installs, updates, or refreshes an app. Free Apple Account signatures expire after seven days, so open SideStore periodically and refresh both SideStore and Catch Up before the counters reach zero. A computer is only required for SideStore's initial installation or recovery.

## Alarm behavior

iOS always retains its normal Stop alarm control. Apple does not allow a third-party app to force-launch after Stop. Use the alarm's **Start Catch-up** action to stop the alarm and open the briefing.
