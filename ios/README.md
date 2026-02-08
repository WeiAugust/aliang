# iOS Module

This directory contains the iOS SwiftUI module for parallel branch delivery.

## Current Status

- ✅ Track A foundation baseline (Core/Networking/Session)
- ✅ Track B authentication flow (`feat/ios-01-auth` scope)
- ✅ Track C feed module (`feat/ios-02-feed` scope)
- ✅ Track D composer module (`feat/ios-03-compose-media` scope)
- ✅ Track E interactions module (`feat/ios-04-interactions` scope)
- ✅ Track F integration & QA assets (`feat/ios-05-integration-qa` scope)

## Track F Delivered

- Integrated dependency container for Auth + Feed + Composer + Interactions
- Added `TrackFRegressionRunner` for end-to-end regression path:
  - login → feed → publish → like/comment
- Added release checklist and PR summary builders:
  - `TrackFReleaseChecklist.standard()`
  - `TrackFPRSummary`
- Added automated tests for Track F regression and checklist generation

## Run Tests

```bash
cd ios
swift test
```

## Run iOS App in Xcode

```bash
cd ios
open AliangHostApp.xcodeproj
```

### One-command startup (recommended)

```bash
cd ios
./start_ios.sh
```

This script will:
- Start infrastructure services (`make dev` in repo root)
- Start backend in background if not healthy yet
- Wait for backend health endpoint (`/health`)
- Open `AliangHostApp.xcodeproj`

Backend logs/pid:
- `backend/.backend-dev.log`
- `backend/.backend-dev.pid`

Then in Xcode:

1. Select scheme `AliangHostApp`.
2. Select an iOS Simulator device (iPhone 15+ recommended).
3. Press `Cmd+R` to run.

If bundle identifier conflicts on your machine, update target `AliangHostApp` setting `PRODUCT_BUNDLE_IDENTIFIER` in Xcode signing settings.

## Open Swift Package for Library/Test Development

```bash
cd ios
open Package.swift
```

Then select scheme `AliangIOS` / `AliangIOSTests` for package build/test work.

For backend integration, start backend at `http://localhost:8080` first.
