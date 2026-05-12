import AppKit
import LifeInWeeksCore
import SwiftUI

struct MenuBarContent: View {
    @ObservedObject var preferences: PreferencesModel
    @Environment(\.openWindow) private var openWindow

    private let engine = LifeCalendarEngine()

    var body: some View {
        let snapshot = engine.snapshot(for: preferences.settings, asOf: preferences.now)

        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Life in Weeks")
                    .font(.system(.headline, design: .rounded))
                if let snapshot {
                    Text("\(snapshot.remainingWeeks.formatted()) weeks left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Set your birth date in the app.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Toggle(
                isOn: Binding(
                    get: { preferences.settings.wallpaperEnabled },
                    set: { preferences.settings.wallpaperEnabled = $0 }
                )
            ) {
                Text("Wallpaper")
                    .font(.system(.body, design: .rounded))
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            Divider()

            MenuBarRow(label: "Open Life in Weeks", icon: "macwindow") {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }

            MenuBarRow(label: "Quit", icon: "power") {
                NSApp.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 240)
    }
}

private struct MenuBarRow: View {
    let label: String
    let icon: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .frame(width: 16)
                Text(label)
                Spacer()
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6).fill(isHovered ? Color.primary.opacity(0.08) : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
