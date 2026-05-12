# WidgetKit Next Step

The app is currently built as a SwiftPM macOS app because full Xcode was not active when the project was scaffolded. The core date math and preferences live in `LifeInWeeksCore`, so a future WidgetKit target can reuse the same model.

When full Xcode is installed and selected:

1. Open the package in Xcode or create a macOS app project that includes `LifeInWeeksCore`.
2. Add a macOS Widget Extension target named `LifeInWeeksWidget`.
3. Enable the same App Group on the app and widget targets.
4. Replace the placeholder `PreferencesStore.futureAppGroupSuiteName` with your own App Group identifier, then change `PreferencesStore()` to use `PreferencesStore(suiteName: PreferencesStore.futureAppGroupSuiteName)` in both app and widget builds.
5. Render small and medium widgets from `LifeCalendarEngine.snapshot(for:asOf:)`.

macOS supports desktop and Notification Center widgets. A true Mac lock screen widget surface is not exposed like iOS/iPadOS Lock Screen widgets.
