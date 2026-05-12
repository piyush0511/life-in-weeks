import AppKit
import Combine
import LifeInWeeksCore
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let preferences = PreferencesModel()

    private lazy var wallpaperRenderer = WallpaperRenderer()

    private var settingsCancellable: AnyCancellable?
    private var tickCancellable: AnyCancellable?
    private var screenObserver: NSObjectProtocol?
    private var spaceObserver: NSObjectProtocol?
    private var appearanceObserver: NSObjectProtocol?
    private var lastAppliedFingerprint: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        settingsCancellable =
            preferences.$settings
            .receive(on: RunLoop.main)
            .sink { [weak self] settings in
                self?.applyWallpaperState(for: settings, force: false)
            }

        tickCancellable =
            preferences.$now
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.applyWallpaperState(for: self.preferences.settings, force: false)
            }

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.applyWallpaperState(for: self.preferences.settings, force: true)
            }
        }

        spaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.applyWallpaperState(for: self.preferences.settings, force: true)
            }
        }

        // macOS posts this distributed notification when the system appearance
        // (light/dark) flips. Observing it lets us re-render the wallpaper
        // immediately when the user (or automatic schedule) switches mode.
        appearanceObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.applyWallpaperState(for: self.preferences.settings, force: true)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep the app running when the main window is closed so the menu bar
        // extra stays alive and the wallpaper keeps updating in the
        // background (e.g. on system appearance change).
        return false
    }

    private func applyWallpaperState(for settings: LifeCalendarSettings, force: Bool) {
        if settings.wallpaperEnabled {
            let fingerprint = renderFingerprint(settings: settings)
            if force || fingerprint != lastAppliedFingerprint {
                wallpaperRenderer.applyCurrent(preferences: preferences)
                lastAppliedFingerprint = fingerprint
            }
        } else if lastAppliedFingerprint != nil {
            wallpaperRenderer.restoreOriginalWallpaper()
            lastAppliedFingerprint = nil
        }
    }

    private func renderFingerprint(settings: LifeCalendarSettings) -> String {
        let snapshot =
            LifeCalendarEngine().snapshot(for: settings, asOf: preferences.now)
        let weekKey = snapshot?.elapsedWeeks ?? -1
        let dateKey = settings.birthDate?.timeIntervalSince1970 ?? 0
        let cal = Calendar.current
        let today = cal.dateComponents([.year, .month, .day], from: preferences.now)
        let dayKey =
            "\(today.year ?? 0)-\(today.month ?? 0)-\(today.day ?? 0)"
        let isDark =
            NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua])
            == .darkAqua
        return [
            settings.theme.rawValue,
            settings.themeMode.rawValue,
            settings.dayTheme.rawValue,
            settings.nightTheme.rawValue,
            isDark ? "dark" : "light",
            String(settings.normalizedLifeExpectancyYears),
            String(Int(dateKey)),
            String(weekKey),
            dayKey,
            String(Int(settings.normalizedWallpaperOpacity * 100)),
            String(Int(settings.normalizedBackdropOpacity * 1000)),
            String(settings.countriesVisited),
            settings.visitedCountryCodes.sorted().joined(separator: ","),
            settings.nextDestination,
            settings.currentHobby,
            settings.currentlyLearning,
            settings.wallpaperTitle,
            String(settings.clampedLayoutTitleYRatio),
            String(settings.clampedLayoutFactsYRatio),
            String(settings.clampedLayoutGridYRatio),
            String(settings.clampedLayoutFooterBottomRatio),
        ].joined(separator: "|")
    }
}
