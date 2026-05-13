import LifeInWeeksCore
import SwiftUI

// MARK: - Connector words for editorial title fading

let connectorWords: Set<String> = [
    "in", "of", "the", "a", "an", "to", "and", "or", "for", "is", "with",
    "at", "by", "on", "as",
]

// MARK: - Backdrop halo fade

/// A soft glow of the canvas background color radiating out from each
/// glyph. Used to fade the typographic backdrop behind readable text
/// without showing a hard rectangular plate.
struct BackdropFadeModifier: ViewModifier {
    let style: ThemeStyle
    var strength: Double = 1.0

    func body(content: Content) -> some View {
        let haloColor = style.background.last ?? (style.isLight ? .white : .black)
        content
            .shadow(color: haloColor.opacity(0.95 * strength), radius: 6, x: 0, y: 0)
            .shadow(color: haloColor.opacity(0.65 * strength), radius: 14, x: 0, y: 0)
            .shadow(color: haloColor.opacity(0.35 * strength), radius: 26, x: 0, y: 0)
    }
}

extension View {
    func backdropFade(style: ThemeStyle, strength: Double = 1.0) -> some View {
        modifier(BackdropFadeModifier(style: style, strength: strength))
    }
}

// MARK: - Stacked editorial title

struct TitleStack: View {
    let title: String
    let style: ThemeStyle
    let canvas: CGSize
    var sizeScale: Double = 1.0
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        let words = title
            .split(separator: " ", omittingEmptySubsequences: true)
            .map(String.init)
        let count = max(1, words.count)
        let baseSize =
            canvas.height
            * (count <= 3 ? 0.115 : count == 4 ? 0.090 : 0.075)
            * sizeScale

        VStack(alignment: alignment, spacing: -baseSize * 0.10) {
            ForEach(0..<words.count, id: \.self) { i in
                let word = words[i]
                let isFaded =
                    words.count >= 3
                    && i > 0
                    && i < words.count - 1
                    && connectorWords.contains(word.lowercased())

                Text(word)
                    .font(.system(size: baseSize, weight: .bold, design: .rounded))
                    .tracking(-baseSize * 0.06)
                    .foregroundStyle(style.foreground.opacity(isFaded ? 0.5 : 1.0))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Year labels column

struct YearLabelColumn: View {
    let years: Int
    let cellSize: CGFloat
    let cellSpacing: CGFloat
    let labelWidth: CGFloat
    let style: ThemeStyle

    var body: some View {
        VStack(spacing: cellSpacing) {
            ForEach(0..<years, id: \.self) { visualRow in
                let year = years - 1 - visualRow
                Text(year.isMultiple(of: 10) ? "\(year)" : "")
                    .font(
                        .system(
                            size: max(9, cellSize * 1.5),
                            weight: .semibold,
                            design: .rounded)
                    )
                    .foregroundStyle(
                        style.foreground.opacity(year.isMultiple(of: 10) ? 0.55 : 0)
                    )
                    .frame(width: labelWidth, height: cellSize, alignment: .leading)
            }
        }
    }
}

// MARK: - Decade dividers

struct DecadeDividers: View {
    let years: Int
    let cellSize: CGFloat
    let cellSpacing: CGFloat
    let gridWidth: CGFloat
    let style: ThemeStyle

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(decadeRows, id: \.self) { year in
                Rectangle()
                    .fill(style.foreground.opacity(0.10))
                    .frame(width: gridWidth, height: 0.6)
                    .offset(y: yOffset(forYear: year))
            }
        }
        .allowsHitTesting(false)
    }

    private var decadeRows: [Int] {
        stride(from: 10, to: years, by: 10).map { $0 }
    }

    private func yOffset(forYear year: Int) -> CGFloat {
        CGFloat(years - year) * (cellSize + cellSpacing) - cellSpacing / 2
    }
}

// MARK: - Grid tint plate

/// A soft, blurred tint plate sized to the grid that hides the typographic
/// backdrop from showing through translucent grid cells.
struct GridTintPlate: View {
    let gridSize: CGSize
    let style: ThemeStyle

    var body: some View {
        let bleed: CGFloat = max(gridSize.width, gridSize.height) * 0.04
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(
                LinearGradient(
                    colors: style.background,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(
                width: gridSize.width + bleed * 2,
                height: gridSize.height + bleed * 2
            )
            .offset(x: -bleed, y: -bleed)
            .blur(radius: bleed * 0.6)
            .opacity(0.9)
            .allowsHitTesting(false)
    }
}

// MARK: - Week grid

struct WallpaperGrid: View {
    let snapshot: LifeCalendarSnapshot
    let style: ThemeStyle
    let cellSize: CGFloat
    let cellSpacing: CGFloat

    var body: some View {
        VStack(spacing: cellSpacing) {
            ForEach(0..<snapshot.lifeExpectancyYears, id: \.self) { visualRow in
                let year = snapshot.lifeExpectancyYears - 1 - visualRow
                HStack(spacing: cellSpacing) {
                    ForEach(0..<52, id: \.self) { week in
                        let index = year * 52 + week
                        cell(for: snapshot.state(forWeekIndex: index))
                    }
                }
            }
        }
    }

    private func cell(for state: WeekState) -> some View {
        let corner = max(1, cellSize * 0.24)
        return Group {
            switch state {
            case .lived:
                RoundedRectangle(cornerRadius: corner)
                    .fill(
                        LinearGradient(
                            colors: style.lived,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
            case .current:
                RoundedRectangle(cornerRadius: corner)
                    .fill(
                        LinearGradient(
                            colors: style.current,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
            case .future:
                RoundedRectangle(cornerRadius: corner)
                    .fill(style.future)
            }
        }
        .frame(width: cellSize, height: cellSize)
    }
}

// MARK: - Beacon overlay (current week marker)

struct BeaconOverlay: View {
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

        let unit = cellSize
        let haloSize = unit * 14
        let ringSize = unit * 3.6

        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            style.accent.opacity(0.65),
                            style.accent.opacity(0.0),
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: haloSize / 2
                    )
                )
                .frame(width: haloSize, height: haloSize)
                .blur(radius: unit * 1.6)

            Circle()
                .stroke(
                    style.foreground.opacity(0.85),
                    lineWidth: max(0.8, unit * 0.10)
                )
                .frame(width: ringSize, height: ringSize)

            Circle()
                .stroke(
                    style.accent.opacity(0.55),
                    lineWidth: max(0.5, unit * 0.06)
                )
                .frame(width: ringSize * 1.7, height: ringSize * 1.7)
        }
        .frame(width: haloSize, height: haloSize)
        .position(x: cx, y: cy)
        .allowsHitTesting(false)
    }
}

// MARK: - 2x2 facts grid

struct FactsGrid2x2: View {
    let settings: LifeCalendarSettings
    let nextDestination: String
    let canvas: CGSize
    let style: ThemeStyle
    var horizontalAlignment: HorizontalAlignment = .leading

    var body: some View {
        let factColSpacing = canvas.width * 0.020
        let factRowSpacing = canvas.height * 0.030

        VStack(alignment: horizontalAlignment, spacing: factRowSpacing) {
            HStack(alignment: .top, spacing: factColSpacing) {
                factCell {
                    if !nextDestination.isEmpty {
                        FactBlock(
                            value: nextDestination,
                            label: "Next trip",
                            icon: "airplane",
                            canvas: canvas,
                            style: style
                        )
                    }
                }
                factCell {
                    if settings.countriesVisited > 0 {
                        FactBlock(
                            value: "\(settings.countriesVisited)",
                            label: "Countries visited",
                            icon: "globe.europe.africa",
                            canvas: canvas,
                            style: style
                        )
                    }
                }
            }
            HStack(alignment: .top, spacing: factColSpacing) {
                factCell {
                    if !settings.currentHobby.isEmpty {
                        FactBlock(
                            value: settings.currentHobby,
                            label: "Hobby",
                            icon: "sparkles",
                            canvas: canvas,
                            style: style
                        )
                    }
                }
                factCell {
                    if !settings.currentlyLearning.isEmpty {
                        FactBlock(
                            value: settings.currentlyLearning,
                            label: "Learning",
                            icon: "character.bubble",
                            canvas: canvas,
                            style: style
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func factCell<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Single fact block (label + value)

struct FactBlock: View {
    let value: String
    let label: String
    let icon: String
    let canvas: CGSize
    let style: ThemeStyle
    var valueSizeScale: Double = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: canvas.height * 0.006) {
            HStack(spacing: canvas.width * 0.006) {
                Image(systemName: icon)
                    .font(.system(size: canvas.height * 0.013, weight: .semibold))
                    .foregroundStyle(style.accent.opacity(0.9))
                Text(label.uppercased())
                    .font(
                        .system(
                            size: canvas.height * 0.012,
                            weight: .semibold,
                            design: .rounded)
                    )
                    .tracking(2.5)
                    .foregroundStyle(style.foreground.opacity(0.55))
            }
            .backdropFade(style: style, strength: 0.7)

            Text(value)
                .font(
                    .system(
                        size: canvas.height * 0.045 * valueSizeScale,
                        weight: .bold,
                        design: .rounded)
                )
                .tracking(-canvas.height * 0.002)
                .foregroundStyle(style.foreground.opacity(0.95))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .backdropFade(style: style)
        }
    }
}

// MARK: - Footer caption

struct FooterCaption: View {
    let snapshot: LifeCalendarSnapshot
    let canvas: CGSize
    let style: ThemeStyle

    var body: some View {
        let aheadPercent = Int(((1 - snapshot.progress) * 100).rounded())
        let weeks = snapshot.remainingWeeks.formatted()

        HStack(spacing: canvas.width * 0.006) {
            Rectangle()
                .fill(style.foreground.opacity(0.4))
                .frame(width: canvas.width * 0.012, height: 1)
            Text("\(weeks) WEEKS LEFT   ·   \(aheadPercent)% AHEAD")
                .font(
                    .system(
                        size: canvas.height * 0.0105,
                        weight: .semibold,
                        design: .rounded)
                )
                .tracking(2)
                .foregroundStyle(style.foreground.opacity(0.50))
        }
    }
}

// MARK: - Empty state

struct EmptyWallpaper: View {
    let style: ThemeStyle
    let canvas: CGSize

    var body: some View {
        VStack(spacing: canvas.height * 0.015) {
            Text("Life in Weeks")
                .font(
                    .system(
                        size: canvas.height * 0.07, weight: .bold,
                        design: .rounded)
                )
                .tracking(-3)
            Text("Open the app to set your birth date.")
                .font(
                    .system(
                        size: canvas.height * 0.018, weight: .medium,
                        design: .rounded)
                )
                .foregroundStyle(style.foreground.opacity(0.65))
        }
        .foregroundStyle(style.foreground)
    }
}

// MARK: - Grid size helper

/// Computes square cell size for a 52-week × N-year grid that fits within
/// (maxWidth × maxHeight) bounds while keeping cells square.
struct GridSizing {
    let cellSize: CGFloat
    let cellSpacing: CGFloat
    let gridWidth: CGFloat
    let gridHeight: CGFloat

    init(years: Int, maxWidth: CGFloat, maxHeight: CGFloat, canvas: CGSize) {
        let cols = 52
        let spacing: CGFloat = max(2, canvas.height * 0.0020)
        let cellByHeight = (maxHeight - spacing * CGFloat(years - 1)) / CGFloat(years)
        let cellByWidth = (maxWidth - spacing * CGFloat(cols - 1)) / CGFloat(cols)
        let cell = max(4, min(cellByHeight, cellByWidth))
        self.cellSize = cell
        self.cellSpacing = spacing
        self.gridWidth = cell * CGFloat(cols) + spacing * CGFloat(cols - 1)
        self.gridHeight = cell * CGFloat(years) + spacing * CGFloat(years - 1)
    }
}
