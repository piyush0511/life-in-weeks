import LifeInWeeksCore
import SwiftUI

struct ThemeStyle {
    let background: [Color]
    let lived: [Color]
    let current: [Color]
    let future: Color
    let accent: Color
    let foreground: Color
    let isLight: Bool
}

extension CalendarTheme {
    var title: String {
        switch self {
        case .aurora: return "Aurora"
        case .graphite: return "Graphite"
        case .sunlit: return "Sunlit"
        case .ocean: return "Ocean"
        case .paper: return "Paper"
        case .midnight: return "Midnight"
        }
    }

    var subtitle: String {
        switch self {
        case .aurora: return "Soft northern light"
        case .graphite: return "Quiet, neutral, focused"
        case .sunlit: return "Warm afternoon hues"
        case .ocean: return "Cool tidal blues"
        case .paper: return "Bright, like a notebook"
        case .midnight: return "Deep, hushed night"
        }
    }

    var style: ThemeStyle {
        switch self {
        case .aurora:
            return ThemeStyle(
                background: [
                    Color(red: 0.03, green: 0.07, blue: 0.10),
                    Color(red: 0.05, green: 0.17, blue: 0.15),
                    Color(red: 0.09, green: 0.10, blue: 0.18),
                ],
                lived: [
                    Color(red: 0.25, green: 0.86, blue: 0.63),
                    Color(red: 0.08, green: 0.58, blue: 0.48),
                ],
                current: [
                    Color(red: 1.00, green: 0.78, blue: 0.34),
                    Color(red: 1.00, green: 0.46, blue: 0.27),
                ],
                future: Color.white.opacity(0.15),
                accent: Color(red: 0.25, green: 0.86, blue: 0.63),
                foreground: .white,
                isLight: false
            )
        case .graphite:
            return ThemeStyle(
                background: [
                    Color(red: 0.08, green: 0.08, blue: 0.09),
                    Color(red: 0.16, green: 0.17, blue: 0.18),
                    Color(red: 0.04, green: 0.05, blue: 0.06),
                ],
                lived: [
                    Color(red: 0.72, green: 0.75, blue: 0.78),
                    Color(red: 0.40, green: 0.43, blue: 0.46),
                ],
                current: [
                    Color(red: 0.97, green: 0.88, blue: 0.62),
                    Color(red: 0.82, green: 0.61, blue: 0.24),
                ],
                future: Color.white.opacity(0.12),
                accent: Color(red: 0.88, green: 0.79, blue: 0.54),
                foreground: .white,
                isLight: false
            )
        case .sunlit:
            return ThemeStyle(
                background: [
                    Color(red: 0.98, green: 0.80, blue: 0.50),
                    Color(red: 0.99, green: 0.93, blue: 0.78),
                    Color(red: 0.58, green: 0.77, blue: 0.72),
                ],
                lived: [
                    Color(red: 0.16, green: 0.55, blue: 0.48),
                    Color(red: 0.08, green: 0.37, blue: 0.38),
                ],
                current: [
                    Color(red: 0.91, green: 0.25, blue: 0.18),
                    Color(red: 0.99, green: 0.61, blue: 0.24),
                ],
                future: Color.black.opacity(0.11),
                accent: Color(red: 0.08, green: 0.37, blue: 0.38),
                foreground: Color(red: 0.13, green: 0.12, blue: 0.18),
                isLight: true
            )
        case .ocean:
            return ThemeStyle(
                background: [
                    Color(red: 0.02, green: 0.11, blue: 0.20),
                    Color(red: 0.03, green: 0.27, blue: 0.38),
                    Color(red: 0.02, green: 0.05, blue: 0.12),
                ],
                lived: [
                    Color(red: 0.31, green: 0.79, blue: 0.96),
                    Color(red: 0.08, green: 0.45, blue: 0.77),
                ],
                current: [
                    Color(red: 0.71, green: 0.97, blue: 1.00),
                    Color(red: 0.22, green: 0.72, blue: 0.89),
                ],
                future: Color.white.opacity(0.13),
                accent: Color(red: 0.31, green: 0.79, blue: 0.96),
                foreground: .white,
                isLight: false
            )
        case .paper:
            return ThemeStyle(
                background: [
                    Color(red: 0.97, green: 0.96, blue: 0.93),
                    Color(red: 0.94, green: 0.93, blue: 0.89),
                    Color(red: 0.91, green: 0.89, blue: 0.83),
                ],
                lived: [
                    Color(red: 0.18, green: 0.20, blue: 0.24),
                    Color(red: 0.32, green: 0.34, blue: 0.40),
                ],
                current: [
                    Color(red: 0.95, green: 0.43, blue: 0.30),
                    Color(red: 0.86, green: 0.30, blue: 0.21),
                ],
                future: Color.black.opacity(0.09),
                accent: Color(red: 0.86, green: 0.30, blue: 0.21),
                foreground: Color(red: 0.12, green: 0.12, blue: 0.14),
                isLight: true
            )
        case .midnight:
            return ThemeStyle(
                background: [
                    Color(red: 0.04, green: 0.04, blue: 0.08),
                    Color(red: 0.08, green: 0.06, blue: 0.16),
                    Color(red: 0.02, green: 0.02, blue: 0.05),
                ],
                lived: [
                    Color(red: 0.62, green: 0.45, blue: 0.95),
                    Color(red: 0.36, green: 0.24, blue: 0.74),
                ],
                current: [
                    Color(red: 1.00, green: 0.62, blue: 0.85),
                    Color(red: 0.93, green: 0.34, blue: 0.71),
                ],
                future: Color.white.opacity(0.10),
                accent: Color(red: 0.62, green: 0.45, blue: 0.95),
                foreground: .white,
                isLight: false
            )
        }
    }
}
