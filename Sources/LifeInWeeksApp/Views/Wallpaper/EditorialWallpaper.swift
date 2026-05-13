import LifeInWeeksCore
import SwiftUI

/// Magazine-spread style wallpaper. A serif display title sits beneath a
/// tripartite masthead, the week grid is woven into the middle as a
/// data figure, and a fact strip with column rules anchors the bottom.
/// Designed to feel closer to a Wallpaper* magazine centerfold or an NYT
/// year-in-review page than to a poster.
///
/// Block positions are read from `preset.position(for:)`. Each position is a
/// (x, y) pair in 0..1 range, where x and y are anchors INTO the canvas.
/// Conventions in this style:
///   - title: x is horizontal center, y is top-of-baseline for the kicker
///   - facts: x is horizontal center, y is top-of-row strip
///   - grid:  x and y are the CENTER of the grid
///   - footer: x is horizontal center, y is top of footer line
struct EditorialWallpaper: View {
    let snapshot: LifeCalendarSnapshot?
    let preset: StylePreset
    @ObservedObject var preferences: PreferencesModel
    let nextDestination: String
    let style: ThemeStyle
    let canvas: CGSize
    let now: Date

    var body: some View {
        ZStack {
            EditorialBackground(style: style, canvas: canvas)

            // Watermark of visited place names. Pulled way back so it reads
            // as paper texture, never as content.
            CountryBackdrop(
                canvas: canvas,
                countries: Countries.placeNames(
                    forCodes: preferences.settings.visitedCountryCodes),
                color: style.foreground,
                opacity: preferences.settings.normalizedBackdropOpacity * 0.35,
                date: now
            )

            // Masthead lives at the very top, outside the per-block layout, so
            // it stays planted on the hairline regardless of how the user
            // re-positions the title block.
            EditorialMasthead(style: style, canvas: canvas, date: now)
                .allowsHitTesting(false)

            if let snapshot {
                EditorialContent(
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

// MARK: - Background

private struct EditorialBackground: View {
    let style: ThemeStyle
    let canvas: CGSize

    var body: some View {
        // Light themes need a slightly stronger rule opacity than dark to
        // read at all over cream/sage paper.
        let ruleOpacity: Double = style.isLight ? 0.22 : 0.16
        let topY = canvas.height * 0.055
        let bottomY = canvas.height * 0.055
        let horizontalInset = canvas.width * 0.055

        ZStack {
            LinearGradient(
                colors: style.background,
                startPoint: .top,
                endPoint: .bottom
            )

            // A whisper of vignette pulls focus to the center. Heavier on
            // dark themes where it adds depth, almost off on light.
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(style.isLight ? 0.05 : 0.20),
                ],
                center: .center,
                startRadius: canvas.width * 0.32,
                endRadius: canvas.width * 0.78
            )

            // Two hairlines — masthead rule up top, signature rule at the
            // bottom. Both inset symmetrically.
            VStack(spacing: 0) {
                Spacer().frame(height: topY)
                Rectangle()
                    .fill(style.foreground.opacity(ruleOpacity))
                    .frame(height: 0.6)
                    .padding(.horizontal, horizontalInset)
                Spacer()
                Rectangle()
                    .fill(style.foreground.opacity(ruleOpacity))
                    .frame(height: 0.6)
                    .padding(.horizontal, horizontalInset)
                Spacer().frame(height: bottomY)
            }
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Masthead

/// Tripartite magazine masthead: date folio left, edition kicker center,
/// publication mark right. Sits on the top hairline.
private struct EditorialMasthead: View {
    let style: ThemeStyle
    let canvas: CGSize
    let date: Date

    var body: some View {
        let inset = canvas.width * 0.055
        let labelSize = canvas.height * 0.0108
        let nameplateSize = canvas.height * 0.0145
        let folioColor = style.foreground.opacity(style.isLight ? 0.55 : 0.5)
        let nameplateColor = style.foreground.opacity(style.isLight ? 0.78 : 0.72)

        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: canvas.width * 0.02) {
                // Left folio — issue date
                Text(formattedDate.uppercased())
                    .editorialLabel(size: labelSize, tracking: 3, color: folioColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Center — publication nameplate, flanked by hairlines
                HStack(spacing: canvas.width * 0.014) {
                    Rectangle()
                        .fill(style.foreground.opacity(style.isLight ? 0.35 : 0.3))
                        .frame(width: canvas.width * 0.03, height: 0.6)
                    Text("LIFE  IN  WEEKS")
                        .font(.system(size: nameplateSize, weight: .semibold, design: .serif))
                        .tracking(6)
                        .foregroundStyle(nameplateColor)
                        .lineLimit(1)
                    Rectangle()
                        .fill(style.foreground.opacity(style.isLight ? 0.35 : 0.3))
                        .frame(width: canvas.width * 0.03, height: 0.6)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                // Right folio — section label
                Text("AN ALMANAC")
                    .editorialLabel(size: labelSize, tracking: 3, color: folioColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, inset)
            .frame(height: canvas.height * 0.04)
            .padding(.top, canvas.height * 0.018)

            Spacer()
        }
        .frame(width: canvas.width, height: canvas.height, alignment: .top)
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, d MMM yyyy"
        return f.string(from: date)
    }
}

// MARK: - Content

private struct EditorialContent: View {
    let snapshot: LifeCalendarSnapshot
    let settings: LifeCalendarSettings
    let preset: StylePreset
    let nextDestination: String
    let style: ThemeStyle
    let canvas: CGSize

    var body: some View {
        let years = snapshot.lifeExpectancyYears

        let outerPadH = canvas.width * 0.07
        let gridMaxW = canvas.width - outerPadH * 2
        let gridMaxH = canvas.height * 0.46

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
            EditorialTitleBlock(
                title: settings.resolvedWallpaperTitle,
                snapshot: snapshot,
                style: style,
                canvas: canvas
            )
            .frame(width: canvas.width * 0.88)
            .position(x: titleCenterX, y: titleY + canvas.height * 0.075)
            .backdropFade(style: style, strength: 0.65)

            EditorialGridBlock(
                snapshot: snapshot,
                sizing: sizing,
                style: style
            )
            .position(x: gridCX, y: gridCY)

            EditorialFactStrip(
                settings: settings,
                nextDestination: nextDestination,
                style: style,
                canvas: canvas
            )
            .frame(width: canvas.width * 0.86)
            .position(x: factsCenterX, y: factsY + canvas.height * 0.03)

            EditorialFooter(snapshot: snapshot, canvas: canvas, style: style)
                .position(x: footerCenterX, y: footerY + canvas.height * 0.005)
                .backdropFade(style: style, strength: 0.6)
        }
        .frame(width: canvas.width, height: canvas.height, alignment: .topLeading)
        .foregroundStyle(style.foreground)
    }
}

// MARK: - Title block (kicker · display · deck)

private struct EditorialTitleBlock: View {
    let title: String
    let snapshot: LifeCalendarSnapshot
    let style: ThemeStyle
    let canvas: CGSize

    var body: some View {
        VStack(spacing: canvas.height * 0.010) {
            // Kicker — quiet, all-caps, sans, generous tracking
            Text(kicker)
                .editorialLabel(
                    size: canvas.height * 0.0125,
                    tracking: 6,
                    color: style.foreground.opacity(style.isLight ? 0.5 : 0.55)
                )

            EditorialDisplayTitle(title: title, style: style, canvas: canvas)

            // Italic serif deck — the sub-headline that makes it feel like
            // an essay opener rather than a poster. Set in the same serif
            // family as the title for tonal continuity.
            Text(deck)
                .font(.system(size: canvas.height * 0.020, weight: .regular, design: .serif))
                .italic()
                .tracking(0.2)
                .multilineTextAlignment(.center)
                .lineSpacing(canvas.height * 0.003)
                .foregroundStyle(style.foreground.opacity(style.isLight ? 0.7 : 0.76))
                .frame(maxWidth: canvas.width * 0.5)
                .lineLimit(2)
                .padding(.top, canvas.height * 0.004)
        }
    }

    private var kicker: String {
        "ENTRY №\(snapshot.ageYears)  ·  AGE \(spelledAge.uppercased())"
    }

    private var deck: String {
        "Each square, one week. A page set every Sunday, lived or yet to be lived."
    }

    private var spelledAge: String {
        let f = NumberFormatter()
        f.numberStyle = .spellOut
        return f.string(from: NSNumber(value: snapshot.ageYears)) ?? "\(snapshot.ageYears)"
    }
}

private struct EditorialDisplayTitle: View {
    let title: String
    let style: ThemeStyle
    let canvas: CGSize

    var body: some View {
        // Title case, semibold serif. No uppercase — feels like a book
        // title, not a billboard. One line, scaling down for longer titles
        // so the block height stays predictable and the layout reads
        // consistently regardless of input length.
        Text(title)
            .font(.system(size: canvas.height * 0.082, weight: .semibold, design: .serif))
            .tracking(-canvas.height * 0.0022)
            .multilineTextAlignment(.center)
            .foregroundStyle(style.foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
    }
}

// MARK: - Grid block

private struct EditorialGridBlock: View {
    let snapshot: LifeCalendarSnapshot
    let sizing: GridSizing
    let style: ThemeStyle

    var body: some View {
        VStack(spacing: max(6, sizing.cellSize * 0.6)) {
            // Tiny label sat just above the figure, like a chart caption
            HStack(spacing: 6) {
                Rectangle()
                    .fill(style.foreground.opacity(style.isLight ? 0.4 : 0.35))
                    .frame(width: 14, height: 0.6)
                Text("FIG. 1  ·  THE WEEKS, ARRAYED")
                    .editorialLabel(
                        size: max(9, sizing.cellSize * 1.05),
                        tracking: 2.5,
                        color: style.foreground.opacity(style.isLight ? 0.55 : 0.55)
                    )
                Rectangle()
                    .fill(style.foreground.opacity(style.isLight ? 0.4 : 0.35))
                    .frame(width: 14, height: 0.6)
            }
            .backdropFade(style: style, strength: 0.5)

            ZStack(alignment: .topLeading) {
                GridTintPlate(
                    gridSize: CGSize(width: sizing.gridWidth, height: sizing.gridHeight),
                    style: style
                )
                DecadeDividers(
                    years: snapshot.lifeExpectancyYears,
                    cellSize: sizing.cellSize,
                    cellSpacing: sizing.cellSpacing,
                    gridWidth: sizing.gridWidth,
                    style: style
                )
                WallpaperGrid(
                    snapshot: snapshot,
                    style: style,
                    cellSize: sizing.cellSize,
                    cellSpacing: sizing.cellSpacing
                )
                if let currentIndex = snapshot.currentWeekIndex {
                    BeaconOverlay(
                        currentIndex: currentIndex,
                        years: snapshot.lifeExpectancyYears,
                        cellSize: sizing.cellSize,
                        cellSpacing: sizing.cellSpacing,
                        style: style
                    )
                }
            }
            .frame(width: sizing.gridWidth, height: sizing.gridHeight, alignment: .topLeading)
        }
    }
}

// MARK: - Fact strip with column rules

private struct EditorialFactStrip: View {
    let settings: LifeCalendarSettings
    let nextDestination: String
    let style: ThemeStyle
    let canvas: CGSize

    var body: some View {
        let items = facts
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    // Vertical column rule — the editorial signature
                    Rectangle()
                        .fill(style.foreground.opacity(style.isLight ? 0.18 : 0.14))
                        .frame(width: 0.6)
                        .padding(.vertical, canvas.height * 0.006)
                }
                stripFact(label: item.label, icon: item.icon, value: item.value)
                    .padding(.horizontal, canvas.width * 0.018)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private struct FactItem {
        let label: String
        let icon: String
        let value: String
    }

    private var facts: [FactItem] {
        var out: [FactItem] = []
        if !nextDestination.isEmpty {
            out.append(.init(label: "Next trip", icon: "airplane", value: nextDestination))
        }
        if settings.countriesVisited > 0 {
            out.append(
                .init(
                    label: "Countries", icon: "globe.europe.africa",
                    value: "\(settings.countriesVisited)"))
        }
        if !settings.currentHobby.isEmpty {
            out.append(.init(label: "Hobby", icon: "sparkles", value: settings.currentHobby))
        }
        if !settings.currentlyLearning.isEmpty {
            out.append(
                .init(
                    label: "Learning", icon: "character.bubble",
                    value: settings.currentlyLearning))
        }
        return out
    }

    private func stripFact(label: String, icon: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: canvas.height * 0.008) {
            HStack(spacing: canvas.width * 0.005) {
                Image(systemName: icon)
                    .font(.system(size: canvas.height * 0.011, weight: .regular))
                    .foregroundStyle(style.accent.opacity(style.isLight ? 0.85 : 0.9))
                Text(label.uppercased())
                    .editorialLabel(
                        size: canvas.height * 0.0105,
                        tracking: 2.5,
                        color: style.foreground.opacity(style.isLight ? 0.55 : 0.55)
                    )
            }

            Text(value)
                .font(.system(size: canvas.height * 0.028, weight: .regular, design: .serif))
                .tracking(-canvas.height * 0.0006)
                .foregroundStyle(style.foreground.opacity(style.isLight ? 0.95 : 0.95))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .backdropFade(style: style, strength: 0.45)
    }
}

// MARK: - Footer caption

private struct EditorialFooter: View {
    let snapshot: LifeCalendarSnapshot
    let canvas: CGSize
    let style: ThemeStyle

    var body: some View {
        let aheadPercent = Int(((1 - snapshot.progress) * 100).rounded())
        let weeks = snapshot.remainingWeeks.formatted()
        let elapsed = (snapshot.lifeExpectancyYears * 52 - snapshot.remainingWeeks).formatted()
        let labelColor = style.foreground.opacity(style.isLight ? 0.55 : 0.5)

        HStack(spacing: canvas.width * 0.014) {
            Rectangle()
                .fill(style.foreground.opacity(style.isLight ? 0.45 : 0.4))
                .frame(width: canvas.width * 0.018, height: 0.6)
            Text("\(elapsed) WEEKS BEHIND  ·  \(weeks) AHEAD  ·  \(aheadPercent)% UNWRITTEN")
                .editorialLabel(
                    size: canvas.height * 0.0108,
                    tracking: 3,
                    color: labelColor
                )
            Rectangle()
                .fill(style.foreground.opacity(style.isLight ? 0.45 : 0.4))
                .frame(width: canvas.width * 0.018, height: 0.6)
        }
    }
}

// MARK: - Editorial label modifier

/// A reusable look for the small tracked sans labels that thread through
/// the design: masthead folios, kicker, fig. caption, fact labels, footer.
/// Sans default design (not rounded) keeps the typographic palette to two
/// faces: serif for prose, system sans for chrome.
private struct EditorialLabelModifier: ViewModifier {
    let size: CGFloat
    let tracking: CGFloat
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: .medium))
            .tracking(tracking)
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

extension View {
    fileprivate func editorialLabel(size: CGFloat, tracking: CGFloat, color: Color) -> some View {
        modifier(EditorialLabelModifier(size: size, tracking: tracking, color: color))
    }
}
