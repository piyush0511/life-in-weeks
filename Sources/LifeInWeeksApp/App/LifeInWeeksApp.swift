import AppKit
import LifeInWeeksCore
import SwiftUI

@main
struct LifeInWeeksApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("Life in Weeks", id: "main") {
            ContentView(preferences: appDelegate.preferences)
                .frame(minWidth: 560, idealWidth: 640, maxWidth: 720,
                       minHeight: 640, idealHeight: 820)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandMenu("Wallpaper") {
                Button("Toggle Wallpaper") {
                    appDelegate.preferences.settings.wallpaperEnabled.toggle()
                }
                .keyboardShortcut("w", modifiers: [.command, .shift])
            }
        }

        MenuBarExtra {
            MenuBarContent(preferences: appDelegate.preferences)
        } label: {
            Label("Life in Weeks", systemImage: "calendar.badge.clock")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(preferences: appDelegate.preferences)
        }
    }
}
