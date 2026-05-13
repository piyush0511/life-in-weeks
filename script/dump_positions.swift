#!/usr/bin/env swift
import Foundation

let bundleIds = ["com.example.LifeInWeeks", "com.piyush.LifeInWeeks"]
let key = "lifeCalendarSettings" as CFString

for id in bundleIds {
    let bundleId = id as CFString
    guard
        let raw = CFPreferencesCopyAppValue(key, bundleId),
        let data = raw as? Data
    else { continue }

    guard
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { continue }

    let activeStyle = json["wallpaperStyle"] as? String ?? "classic"
    print("Bundle: \(id)")
    print("  active wallpaperStyle: \(activeStyle)")

    if let presets = json["stylePresets"] as? [String: Any] {
        for (styleKey, preset) in presets.sorted(by: { $0.key < $1.key }) {
            guard
                let p = preset as? [String: Any],
                let positions = p["positions"] as? [String: [String: Double]]
            else { continue }
            print("  style: \(styleKey)")
            for block in ["title", "facts", "grid", "footer"] {
                if let pos = positions[block] {
                    let x = pos["x"] ?? 0
                    let y = pos["y"] ?? 0
                    let xs = ((x * 10000).rounded() / 10000)
                    let ys = ((y * 10000).rounded() / 10000)
                    print("    \(block): x=\(xs) y=\(ys)")
                }
            }
        }
    }
    print("---")
}
