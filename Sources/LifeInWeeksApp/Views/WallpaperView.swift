import LifeInWeeksCore
import SwiftUI

/// Top-level wallpaper view. Dispatches to one of three style-specific
/// renderers based on `preferences.settings.wallpaperStyle`. Each style
/// reads its own theme and per-block positions from its `StylePreset`.
struct WallpaperView: View {
    @ObservedObject var preferences: PreferencesModel
    @Environment(\.colorScheme) private var colorScheme

    private let engine = LifeCalendarEngine()

    var body: some View {
        let preset = preferences.settings.activePreset
        let theme = preset.resolvedTheme(systemIsDark: colorScheme == .dark)
        let style = theme.style
        let snapshot = engine.snapshot(
            for: preferences.settings, asOf: preferences.now)
        let opacity = preferences.settings.normalizedWallpaperOpacity

        GeometryReader { proxy in
            Group {
                switch preferences.settings.wallpaperStyle {
                case .classic:
                    ClassicWallpaper(
                        snapshot: snapshot,
                        preset: preset,
                        preferences: preferences,
                        nextDestination: preferences.effectiveNextDestination,
                        style: style,
                        canvas: proxy.size,
                        now: preferences.now
                    )
                case .editorial:
                    EditorialWallpaper(
                        snapshot: snapshot,
                        preset: preset,
                        preferences: preferences,
                        nextDestination: preferences.effectiveNextDestination,
                        style: style,
                        canvas: proxy.size,
                        now: preferences.now
                    )
                case .minimal:
                    MinimalWallpaper(
                        snapshot: snapshot,
                        preset: preset,
                        preferences: preferences,
                        nextDestination: preferences.effectiveNextDestination,
                        style: style,
                        canvas: proxy.size,
                        now: preferences.now
                    )
                }
            }
            .opacity(opacity)
        }
        .ignoresSafeArea()
    }
}
