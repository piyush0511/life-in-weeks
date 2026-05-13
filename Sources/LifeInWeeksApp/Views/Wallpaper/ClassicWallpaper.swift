import LifeInWeeksCore
import SwiftUI

/// The original "side column / right grid / backdrop tint" wallpaper.
struct ClassicWallpaper: View {
    let snapshot: LifeCalendarSnapshot?
    let preset: StylePreset
    @ObservedObject var preferences: PreferencesModel
    let nextDestination: String
    let style: ThemeStyle
    let canvas: CGSize
    let now: Date

    var body: some View {
        ZStack {
            // Atmospheric background
            LinearGradient(
                colors: style.background,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(style.accent.opacity(style.isLight ? 0.12 : 0.16))
                .frame(width: canvas.width * 0.6, height: canvas.width * 0.6)
                .blur(radius: 220)
                .offset(x: -canvas.width * 0.30, y: -canvas.height * 0.32)
            Circle()
                .fill(
                    (style.isLight ? Color.black : Color.white)
                        .opacity(style.isLight ? 0.04 : 0.07)
                )
                .frame(width: canvas.width * 0.65, height: canvas.width * 0.65)
                .blur(radius: 260)
                .offset(x: canvas.width * 0.32, y: canvas.height * 0.34)

            // Typographic backdrop of visited countries/cities
            CountryBackdrop(
                canvas: canvas,
                countries: Countries.placeNames(
                    forCodes: preferences.settings.visitedCountryCodes),
                color: style.foreground,
                opacity: preferences.settings.normalizedBackdropOpacity,
                date: now
            )

            if let snapshot {
                ClassicContent(
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

private struct ClassicContent: View {
    let snapshot: LifeCalendarSnapshot
    let settings: LifeCalendarSettings
    let preset: StylePreset
    let nextDestination: String
    let style: ThemeStyle
    let canvas: CGSize

    var body: some View {
        let years = snapshot.lifeExpectancyYears

        let outerPadH = canvas.width * 0.05
        let outerPadV = canvas.height * 0.045
        let innerH = canvas.height - outerPadV * 2

        let leftColumnWidth = max(canvas.width * 0.32, 540)
        let columnGap = canvas.width * 0.025
        let labelWidth = canvas.width * 0.020
        let labelGap = canvas.width * 0.008
        let gridAreaW =
            canvas.width - outerPadH * 2 - leftColumnWidth - columnGap
            - labelWidth - labelGap

        let sizing = GridSizing(
            years: years,
            maxWidth: gridAreaW,
            maxHeight: innerH,
            canvas: canvas
        )
        let gridFullWidth = sizing.gridWidth + labelGap + labelWidth

        // Positions: title/facts/footer use x as left offset; grid x is its
        // anchor (right edge offset from canvas width); y is vertical anchor.
        let titlePos = preset.position(for: .title)
        let factsPos = preset.position(for: .facts)
        let gridPos = preset.position(for: .grid)
        let footerPos = preset.position(for: .footer)

        // For classic style, x ratios for left-column items map directly to
        // canvas width. Grid x ratio indicates desired horizontal CENTER of
        // the grid+labels group (default 0.70 puts it on the right side).
        let titleX = canvas.width * titlePos.x
        let factsX = canvas.width * factsPos.x
        let footerX = canvas.width * footerPos.x

        let titleY = canvas.height * titlePos.y
        let factsY = canvas.height * factsPos.y
        let gridCenterX = canvas.width * gridPos.x
        let gridCenterY = canvas.height * gridPos.y
        let footerY = canvas.height * footerPos.y

        let gridX = min(
            max(outerPadH, gridCenterX - gridFullWidth / 2),
            canvas.width - outerPadH - gridFullWidth
        )
        let gridTop = min(
            max(outerPadV, canvas.height - outerPadV - sizing.gridHeight),
            max(outerPadV, gridCenterY - sizing.gridHeight / 2)
        )

        ZStack(alignment: .topLeading) {
            // Title block
            TitleStack(
                title: settings.resolvedWallpaperTitle,
                style: style,
                canvas: canvas
            )
            .backdropFade(style: style)
            .frame(width: leftColumnWidth, alignment: .leading)
            .offset(x: titleX, y: titleY)

            // Accent rule above the facts grid
            Rectangle()
                .fill(style.accent.opacity(0.85))
                .frame(width: canvas.width * 0.04, height: 2)
                .offset(x: factsX, y: factsY - canvas.height * 0.025)

            // 2x2 facts grid
            FactsGrid2x2(
                settings: settings,
                nextDestination: nextDestination,
                canvas: canvas,
                style: style
            )
            .frame(width: leftColumnWidth, alignment: .leading)
            .offset(x: factsX, y: factsY)

            // Grid + year labels
            HStack(alignment: .top, spacing: labelGap) {
                ZStack(alignment: .topLeading) {
                    GridTintPlate(
                        gridSize: CGSize(
                            width: sizing.gridWidth, height: sizing.gridHeight),
                        style: style
                    )
                    DecadeDividers(
                        years: years,
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
                            years: years,
                            cellSize: sizing.cellSize,
                            cellSpacing: sizing.cellSpacing,
                            style: style
                        )
                    }
                }
                .frame(
                    width: sizing.gridWidth, height: sizing.gridHeight,
                    alignment: .topLeading)

                YearLabelColumn(
                    years: years,
                    cellSize: sizing.cellSize,
                    cellSpacing: sizing.cellSpacing,
                    labelWidth: labelWidth,
                    style: style
                )
            }
            .frame(
                width: gridFullWidth, height: sizing.gridHeight,
                alignment: .topLeading
            )
            .offset(x: gridX, y: gridTop)

            // Footer
            FooterCaption(snapshot: snapshot, canvas: canvas, style: style)
                .offset(x: footerX, y: footerY)
        }
        .frame(width: canvas.width, height: canvas.height, alignment: .topLeading)
        .foregroundStyle(style.foreground)
    }
}
