import LifeInWeeksCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: PreferencesModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 14) {
            Text("Open Life in Weeks")
                .font(.system(.title3, design: .rounded).weight(.semibold))
            Text("All settings live in the main window now.")
                .font(.callout)
                .foregroundStyle(.secondary)
            Button("Open") {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(28)
        .frame(width: 320)
    }
}
