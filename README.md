# Life in Weeks

A native macOS life calendar that turns each week into a small, quiet marker.

## Current State

- SwiftUI macOS app built with SwiftPM.
- Menu bar glance with current week progress.
- Shared `LifeInWeeksCore` module for date math and future WidgetKit reuse.
- Local `.app` packaging script at `script/build_and_run.sh`.

## Run

```bash
./script/build_and_run.sh
```

Use `./script/build_and_run.sh --verify` to build, launch, and confirm the process is running.

The development bundle identifier defaults to `com.example.LifeInWeeks`. For a signed local build, pass your own reverse-DNS identifier without committing it:

```bash
LIFE_IN_WEEKS_BUNDLE_ID=com.yourname.LifeInWeeks ./script/build_and_run.sh
```

## Open In Xcode

Open `LifeInWeeks.xcworkspace` from this folder. The workspace resolves the Swift package schemes correctly.

If Xcode says it cannot find files in the folder, open `Package.swift` directly instead.

## Widget

The WidgetKit target needs full Xcode. See `docs/WidgetKitNextStep.md`.

## Privacy

The app stores wallpaper preferences, birth date, calendar selection, and travel hints in local macOS application data. Generated app bundles, Swift build output, signing files, local environment files, and personal helper scripts are ignored by git.
