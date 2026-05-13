import LifeInWeeksCore
import SwiftUI

/// Minimal/monospace wallpaper. Single column, ultra restrained, monospaced
/// labels. Pure typography over a solid surface, in the Swiss / Dieter Rams
/// tradition: every element earns its place, whitespace does the work.
///
/// Block position conventions:
///   - title: x = horizontal center, y = top of title baseline
///   - facts: x = horizontal center, y = top of fact list
///   - grid:  x and y = CENTER of the grid
///   - footer: x = horizontal center, y = top of footer line
struct MinimalWallpaper: View {
    let snapshot: LifeCalendarSnapshot?
    let preset: StylePreset
    @ObservedObject var preferences: PreferencesModel
    let nextDestination: String
    let style: ThemeStyle
    let canvas: CGSize
    let now: Date

    var body: some View {
        ZStack {
            // Flat, single-color background. No gradient, no watermark.
            (style.background.first ?? Color.black)
                .ignoresSafeArea()

            // The one concession to depth: a 4% soft-light overlay so a true
            // black or true white background does not feel synthetic on a
            // physical display.
            LinearGradient(
                colors: [
                    Color.clear,
                    (style.isLight ? Color.black : Color.white).opacity(0.04),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.softLight)
            .ignoresSafeArea()

            if let snapshot {
                MinimalContent(
                    snapshot: snapshot,
                    settings: preferences.settings,
                    preset: preset,
                    nextDestination: nextDestination,
                    style: style,
                    canvas: canvas
                )
            } else {
                EmptyWallpaper(style: style, canvas: canvas)
            }
        }
    }
}

// MARK: - Content

private struct MinimalContent: View {
    let snapshot: LifeCalendarSnapshot
    let settings: LifeCalendarSettings
    let preset: StylePreset
    let nextDestination: String
    let style: ThemeStyle
    let canvas: CGSize

    var body: some View {
        let years = snapshot.lifeExpectancyYears

        // Generous side margins so the grid stays smaller than other styles.
        // The grid is intentionally quieter; typography is the focal point.
        let outerPadH = canvas.width * 0.20
        let gridMaxW = canvas.width - outerPadH * 2
        let gridMaxH = canvas.height * 0.34

        let sizing = GridSizing(
            years: years,
            maxWidth: gridMaxW,
            maxHeight: gridMaxH,
            canvas: canvas
        )

        let titlePos = preset.position(for: .title)
        let factsPos = preset.position(for: .facts)
        let gridPos = preset.position(for: .grid)
        let footerPos = preset.position(for: .footer)

        let titleCenterX = canvas.width * titlePos.x
        let titleY = canvas.height * titlePos.y
        let factsCenterX = canvas.width * factsPos.x
        let factsY = canvas.height * factsPos.y
        let gridCX = canvas.width * gridPos.x
        let gridCY = canvas.height * gridPos.y
        let footerCenterX = canvas.width * footerPos.x
        let footerY = canvas.height * footerPos.y

        ZStack(alignment: .topLeading) {
            MinimalTitleBlock(
                title: settings.resolvedWallpaperTitle,
                snapshot: snapshot,
                style: style,
                canvas: canvas
            )
            .frame(width: canvas.width * 0.86)
            .position(x: titleCenterX, y: titleY + canvas.height * 0.04)

            MinimalGridBlock(
                snapshot: snapshot,
                sizing: sizing,
                style: style
            )
            .position(x: gridCX, y: gridCY)

            MinimalFactsList(
                settings: settings,
                nextDestination: nextDestination,
                style: style,
                canvas: canvas
            )
            .frame(width: canvas.width * 0.46)
            .position(x: factsCenterX, y: factsY + canvas.height * 0.04)

            MinimalFooter(snapshot: snapshot, canvas: canvas, style: style)
                .position(x: footerCenterX, y: footerY + canvas.height * 0.005)
        }
        .frame(width: canvas.width, height: canvas.height, alignment: .topLeading)
        .foregroundStyle(style.foreground)
    }
}

// MARK: - Title

/// Eyebrow (week index / age) → serif title → hairline rule → accent dot.
/// The eyebrow carries information, not decoration: it tells you which week
/// of which year you are looking at. The hairline + accent dot is the only
/// non-typographic mark on the canvas above the grid.
private struct MinimalTitleBlock: View {
    let title: String
    let snapshot: LifeCalendarSnapshot
    let style: ThemeStyle
    let canvas: CGSize

    var body: some View {
        VStack(alignment: .center, spacing: canvas.height * 0.013) {
            Text(eyebrow)
                .font(.system(
                    size: canvas.height * 0.0115,
                    weight: .medium,
                    design: .monospaced))
                .tracking(4)
                .foregroundStyle(style.foreground.opacity(secondaryOpacity))

            Text(title)
                .font(.system(
                    size: canvas.height * 0.075,
                    weight: .regular,
                    design: .serif))
                .tracking(-canvas.height * 0.0014)
                .foregroundStyle(style.foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .multilineTextAlignment(.center)

            // A short hairline + single accent dot. The dot is the lone
            // touch of accent above the grid, the line is the lone non-type
            // mark. Together they read as a typographic ornament.
            HStack(spacing: canvas.width * 0.006) {
                Rectangle()
                    .fill(style.foreground.opacity(0.25))
                    .frame(width: canvas.width * 0.04, height: 1)
                Circle()
                    .fill(style.accent)
                    .frame(
                        width: canvas.height * 0.0055,
                        height: canvas.height * 0.0055)
                Rectangle()
                    .fill(style.foreground.opacity(0.25))
                    .frame(width: canvas.width * 0.04, height: 1)
            }
            .padding(.top, canvas.height * 0.004)
        }
    }

    private var eyebrow: String {
        // Week within the user's current life-year (1..52) paired with age.
        // Both anchored to the birthday — internally coherent, no
        // calendar/birth mismatch. Maps directly to the row in the grid the
        // current-week marker sits on.
        let weekOfLifeYear: Int = {
            if let idx = snapshot.currentWeekIndex {
                return (idx % 52) + 1
            }
            return min(52, snapshot.elapsedWeeks % 52 + 1)
        }()
        return "WEEK \(weekOfLifeYear) / 52   ·   AGE \(snapshot.ageYears)"
    }

    /// Mid-gray backgrounds need a touch more contrast than near-black /
    /// near-white ones.
    private var secondaryOpacity: Double {
        style.isLight ? 0.62 : 0.58
    }
}

// MARK: - Grid

/// Custom flat grid for the minimal style. We deliberately skip the shared
/// `WallpaperGrid` to avoid its `LinearGradient` cell fills, and we replace
/// `BeaconOverlay` with a tiny solid ring (no halo, no blur).
private struct MinimalGridBlock: View {
    let snapshot: LifeCalendarSnapshot
    let sizing: GridSizing
    let style: ThemeStyle

    var body: some View {
        ZStack(alignment: .topLeading) {
            grid
            if let currentIndex = snapshot.currentWeekIndex {
                MinimalBeacon(
                    currentIndex: currentIndex,
                    years: snapshot.lifeExpectancyYears,
                    cellSize: sizing.cellSize,
                    cellSpacing: sizing.cellSpacing,
                    style: style
                )
            }
        }
        .frame(
            width: sizing.gridWidth,
            height: sizing.gridHeight,
            alignment: .topLeading)
    }

    private var grid: some View {
        VStack(spacing: sizing.cellSpacing) {
            ForEach(0..<snapshot.lifeExpectancyYears, id: \.self) { visualRow in
                let year = snapshot.lifeExpectancyYears - 1 - visualRow
                HStack(spacing: sizing.cellSpacing) {
                    ForEach(0..<52, id: \.self) { week in
                        let index = year * 52 + week
                        cell(for: snapshot.state(forWeekIndex: index))
                    }
                }
            }
        }
    }

    private func cell(for state: WeekState) -> some View {
        let corner = max(0.5, sizing.cellSize * 0.18)
        return Group {
            switch state {
            case .lived:
                // Solid flat fill. No gradient — Rams would not stand for it.
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(style.lived.first ?? style.foreground)
            case .current:
                // The current cell uses the accent so the live week is
                // visible even without the beacon ring.
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(style.accent)
            case .future:
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(style.future)
            }
        }
        .frame(width: sizing.cellSize, height: sizing.cellSize)
    }
}

/// A single hairline-stroked ring around the current week. No halo, no
/// gradient, no soft glow. Smaller and quieter than the shared beacon.
private struct MinimalBeacon: View {
    let currentIndex: Int
    let years: Int
    let cellSize: CGFloat
    let cellSpacing: CGFloat
    let style: ThemeStyle

    var body: some View {
        let col = currentIndex % 52
        let row = years - 1 - (currentIndex / 52)
        let cx = CGFloat(col) * (cellSize + cellSpacing) + cellSize / 2
        let cy = CGFloat(row) * (cellSize + cellSpacing) + cellSize / 2
        let ringSize = cellSize * 2.4

        Circle()
            .stroke(
                style.foreground.opacity(0.85),
                lineWidth: max(0.6, cellSize * 0.10)
            )
            .frame(width: ringSize, height: ringSize)
            .position(x: cx, y: cy)
            .allowsHitTesting(false)
    }
}

// MARK: - Facts list

/// One column of small-caps monospaced labels paired with serif values.
/// Each row is one fact, ordered by recency / relevance. No icons, no rules.
private struct MinimalFactsList: View {
    let settings: LifeCalendarSettings
    let nextDestination: String
    let style: ThemeStyle
    let canvas: CGSize

    private struct Row: Identifiable {
        var id: String { label }
        let label: String
        let value: String
    }

    private var rows: [Row] {
        var r: [Row] = []
        if !nextDestination.isEmpty {
            r.append(Row(label: "next", value: nextDestination))
        }
        if settings.countriesVisited > 0 {
            let plural = settings.countriesVisited == 1 ? "country" : "countries"
            r.append(Row(
                label: "visited",
                value: "\(settings.countriesVisited) \(plural)"))
        }
        if !settings.currentHobby.isEmpty {
            r.append(Row(label: "hobby", value: settings.currentHobby))
        }
        if !settings.currentlyLearning.isEmpty {
            r.append(Row(label: "learning", value: settings.currentlyLearning))
        }
        return r
    }

    private var secondaryOpacity: Double {
        style.isLight ? 0.55 : 0.50
    }

    var body: some View {
        // Wider label gutter so monospace + tracking does not collide with
        // longer labels like LEARNING.
        let labelW = canvas.width * 0.10
        let gutter = canvas.width * 0.016
        let labelSize = canvas.height * 0.0115
        let valueSize = canvas.height * 0.0225

        VStack(alignment: .leading, spacing: canvas.height * 0.018) {
            ForEach(rows) { row in
                HStack(alignment: .firstTextBaseline, spacing: gutter) {
                    Text(row.label.uppercased())
                        .font(.system(
                            size: labelSize,
                            weight: .medium,
                            design: .monospaced))
                        .tracking(2.5)
                        .foregroundStyle(
                            style.foreground.opacity(secondaryOpacity))
                        .frame(width: labelW, alignment: .leading)

                    Text(row.value)
                        .font(.system(
                            size: valueSize,
                            weight: .regular,
                            design: .serif))
                        .foregroundStyle(style.foreground)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Footer

/// A single monospaced line. The remaining-weeks number is the only piece
/// rendered in the accent color — a second, deliberate touch point so the
/// accent reads as a system element rather than a decoration on the grid.
private struct MinimalFooter: View {
    let snapshot: LifeCalendarSnapshot
    let canvas: CGSize
    let style: ThemeStyle

    var body: some View {
        let aheadPercent = Int(((1 - snapshot.progress) * 100).rounded())
        let weeks = snapshot.remainingWeeks.formatted()
        let secondary = style.foreground.opacity(style.isLight ? 0.55 : 0.50)
        let labelFont = Font.system(
            size: canvas.height * 0.0115,
            weight: .medium,
            design: .monospaced)

        HStack(spacing: 0) {
            Text(weeks)
                .font(labelFont)
                .tracking(3)
                .foregroundStyle(style.accent)
            Text("  WEEKS LEFT   ·   \(aheadPercent)%  AHEAD")
                .font(labelFont)
                .tracking(3)
                .foregroundStyle(secondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }
}
