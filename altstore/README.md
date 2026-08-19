# Catch Up SideStore source

SideStore is compatible with the AltSource JSON format, so this directory keeps the protocol-oriented `altstore` name while publishing a SideStore-ready app source.

## Automated publishing

The GitHub workflow builds `CatchUp-SideStore.ipa` without Screen Time shielding, calculates the IPA size and SHA-256, and publishes these release assets:

- `CatchUp-SideStore.ipa`
- `sidestore-source.json`
- `source.json` as a compatibility alias
- `CatchUp-AppIcon-1024.png`

The public SideStore source URL is:

`https://github.com/sarva12/catch-up/releases/download/v1.0.0/sidestore-source.json`

SideStore users can paste that URL under **Sources**, or open this URL scheme after SideStore is installed:

`sidestore://source?url=https%3A%2F%2Fgithub.com%2Fsarva12%2Fcatch-up%2Freleases%2Fdownload%2Fv1.0.0%2Fsidestore-source.json`

## Manual generation

```powershell
node generate-source.mjs `
  --ipa C:\path\to\CatchUp-SideStore.ipa `
  --owner YOUR_GITHUB_USERNAME `
  --repo catch-up `
  --bundle-id com.yourname.CatchUpFree `
  --developer "YOUR NAME"
```

The version, build, permissions, byte size, and SHA-256 in the source must match the IPA. A free Apple Account must refresh SideStore and installed apps every seven days.
