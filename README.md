# Pulse — Phone Health Scanner

An honest phone health diagnostic app for iOS. Shows only what iOS publicly exposes — storage, thermal state, battery level, charging state, Low Power Mode — weighted into a single Pulse Score (0–100). Everything runs on-device.

## Public website

The `docs/` folder serves the marketing + legal pages via **GitHub Pages**.

### Enable GitHub Pages (one-time)

1. Push this repo to GitHub.
2. In the repo on github.com → **Settings → Pages**.
3. Source: **Deploy from a branch**.
4. Branch: **main**, Folder: **/docs**.
5. Save. After ~1 minute your site is live at:

   ```
   https://<your-username>.github.io/<repo-name>/
   ```

6. Test these URLs:
   - `…/` (landing)
   - `…/privacy.html`
   - `…/terms.html`
   - `…/support.html`

### Use these URLs in App Store Connect

- **Privacy Policy URL:** `https://<your-username>.github.io/<repo-name>/privacy.html`
- **Marketing URL:** `https://<your-username>.github.io/<repo-name>/`
- **Support URL:** `https://<your-username>.github.io/<repo-name>/support.html`

### Custom domain (optional)

If you own `pulseapp.app`:

1. Add a file `docs/CNAME` with single line `pulseapp.app`.
2. In your DNS, add a CNAME record pointing `pulseapp.app` to `<your-username>.github.io`.
3. In GitHub → Settings → Pages → Custom domain: `pulseapp.app`.
4. Enable **Enforce HTTPS**.

Then update the App Store URLs to `https://pulseapp.app/privacy.html` etc.

---

## Building the app

```bash
brew install xcodegen   # one-time
xcodegen generate
open Pulse.xcodeproj
```

⌘R on an iOS 17+ device or simulator. The first launch starts onboarding; once finished, tap **Run Full Scan** on Home.

## Repository map

```
Pulse/                  # iOS app source
PulseWidget/            # Widget extension
docs/                   # Public GitHub Pages site (HTML/CSS)
internal-docs/          # App Store metadata, Privacy Nutrition Label checklist
project.yml             # XcodeGen project config
Pulse.storekit          # Local StoreKit configuration for IAP testing
```

## Honesty by design

iOS does not expose true battery health, per-app storage usage, or precise temperature to third-party apps. Pulse says so directly and links to Apple's own pages where applicable. The Pulse Score is a transparent weighting of two real signals: storage (55%) + thermal state (45%).

No analytics SDK. No third-party tracking. No backend.
