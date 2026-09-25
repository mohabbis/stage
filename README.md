# Stage

Stage is a native macOS app that saves a workspace and reconstructs it later. A workspace is the desk as you left it: which apps are open, where their windows sit, which display they are on, and the tabs, folders, directories, and documents macOS will actually give up.

It is not a launcher that only opens a list of apps.

## What a restore does

- Launches apps that are not running
- Reopens browser tabs for Safari and Chromium browsers (Chrome, Brave, Edge, Arc, Vivaldi, Opera)
- Reopens Finder folders
- Opens Terminal or iTerm windows in the saved working directories
- Reopens project folders for Visual Studio Code and Cursor
- Reopens documents when an app exposes a file path
- Moves windows back to the saved frames, including across displays
- Scales those frames if the display arrangement changed
- Hides unrelated apps and can minimize windows that are not part of the snapshot

Stage does not quit anything. Hidden apps are still running.

Each app is marked **Full**, **Partial**, or **Unsupported**. Firefox tabs, Notes contents, unsaved editor state, and windows on other Spaces are called out instead of being faked. Capture records the current Space only.

## Requirements

- macOS 15 or later
- Apple Silicon or Intel, built with Xcode 16 or later
- Accessibility permission, required to read and move windows
- Automation permission the first time Stage scripts Safari, Finder, or Terminal
- Screen Recording is optional and only helps when a window title is missing

## Build

```bash
xcodegen generate
xcodebuild -project Stage.xcodeproj -scheme Stage -destination 'platform=macOS,arch=arm64' -configuration Debug build
xcodebuild -project Stage.xcodeproj -scheme Stage -destination 'platform=macOS,arch=arm64' test
```

Open `Stage.xcodeproj` and run Stage. Saved workspaces live in `~/Library/Application Support/Stage`.

The project is ad-hoc signed so it builds without a Developer ID. Hardened Runtime and the Apple Events entitlement are already set for a later notarized build.

## Notarized download

The landing page in `web/` is the product demo. The Download button calls `/download`, which redirects to the `DOWNLOAD_URL` environment variable. Until that variable is set, the page says the notarized build is not linked.

When the signing secrets are available:

```bash
export APPLE_ID="..."
export APPLE_APP_SPECIFIC_PASSWORD="..."
export APPLE_TEAM_ID="..."
export DEVELOPER_ID="Developer ID Application: Name (TEAM)"
./scripts/notarize.sh
```

Upload the disk image and set `DOWNLOAD_URL` on the Vercel project, then redeploy. `DOWNLOAD_URL` is read on the server at request time.

## Landing page

```bash
cd web
npm install
npm run dev
```

Vercel should use `web` as the project root. The preview on the homepage is a browser demo of the interaction. The Mac app performs the real capture.

## Layout

```text
StageApp/          SwiftUI app, capture, restore, and integrations
StageTests/        Geometry, mapping, matching, and snapshot tests
web/               Next.js demo and download redirect
scripts/notarize.sh
```

Window frames are stored in Quartz global coordinates: origin at the top-left of the primary display, y increasing downward. Accessibility and `CGWindowList` already use that space, so restore can place windows without flipping axes. `NSScreen` frames are converted on the way in.
