import AppKit
import Combine
import LifeInWeeksCore
import SwiftUI

@MainActor
final class WallpaperRenderer {
    private let directory: URL
    private let originalBookmarkKey = "originalDesktopWallpaperBookmark"

    init() {
        let appSupport =
            (try? FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )) ?? URL(fileURLWithPath: NSTemporaryDirectory())

        self.directory = appSupport.appendingPathComponent(
            "LifeInWeeks", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true)
    }

    func saveOriginalWallpaperIfNeeded() {
        guard UserDefaults.standard.data(forKey: originalBookmarkKey) == nil else { return }
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        guard let url = NSWorkspace.shared.desktopImageURL(for: screen) else { return }
        if let bookmark = try? url.bookmarkData() {
            UserDefaults.standard.set(bookmark, forKey: originalBookmarkKey)
        }
    }

    func restoreOriginalWallpaper() {
        guard let bookmark = UserDefaults.standard.data(forKey: originalBookmarkKey) else {
            return
        }

        var stale = false
        guard
            let url = try? URL(
                resolvingBookmarkData: bookmark,
                bookmarkDataIsStale: &stale
            )
        else { return }

        for screen in NSScreen.screens {
            try? NSWorkspace.shared.setDesktopImageURL(
                url, for: screen, options: [:])
        }
    }

    func applyCurrent(preferences: PreferencesModel) {
        saveOriginalWallpaperIfNeeded()

        guard let primary = NSScreen.main ?? NSScreen.screens.first else { return }
        let scale = primary.backingScaleFactor

        let isDark =
            NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua])
            == .darkAqua

        for screen in NSScreen.screens {
            let pixelSize = CGSize(
                width: screen.frame.width,
                height: screen.frame.height
            )

            let view = WallpaperView(preferences: preferences)
                .environment(\.colorScheme, isDark ? .dark : .light)
                .frame(width: pixelSize.width, height: pixelSize.height)

            let renderer = ImageRenderer(content: view)
            renderer.scale = scale

            guard let nsImage = renderer.nsImage,
                let tiff = nsImage.tiffRepresentation,
                let rep = NSBitmapImageRep(data: tiff),
                let data = rep.representation(using: .png, properties: [:])
            else { continue }

            let filename =
                "wallpaper-\(Int(pixelSize.width))x\(Int(pixelSize.height))-\(Int(Date().timeIntervalSince1970)).png"
            let url = directory.appendingPathComponent(filename)

            do {
                try data.write(to: url, options: .atomic)
                try NSWorkspace.shared.setDesktopImageURL(
                    url, for: screen, options: [:])
            } catch {
                NSLog("LifeInWeeks: wallpaper write failed: \(error.localizedDescription)")
            }
        }

        cleanupOldRenders()
    }

    private func cleanupOldRenders() {
        guard
            let files = try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
        else { return }

        let renders = files.filter { $0.lastPathComponent.hasPrefix("wallpaper-") }
        let sorted = renders.sorted { lhs, rhs in
            let lDate =
                (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let rDate =
                (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return lDate > rDate
        }

        let keep = max(16, NSScreen.screens.count * 8)
        for stale in sorted.dropFirst(keep) {
            try? FileManager.default.removeItem(at: stale)
        }
    }
}
