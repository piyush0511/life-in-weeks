import Foundation

// MARK: - Themes

public enum CalendarTheme: String, CaseIterable, Codable, Identifiable, Sendable {
    // Classic palette (original wallpaper)
    case aurora, graphite, sunlit, ocean, paper, midnight
    // Editorial palette
    case editorialLight, editorialDark, editorialSage, editorialClay
    // Minimal palette
    case minimalLight, minimalDark, minimalMono

    public var id: String { rawValue }
}

public enum ThemeMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case custom
    case system

    public var id: String { rawValue }
}

// MARK: - Wallpaper styles

public enum WallpaperStyle: String, CaseIterable, Codable, Identifiable, Sendable {
    case classic
    case editorial
    case minimal

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .classic: return "Classic"
        case .editorial: return "Editorial"
        case .minimal: return "Minimal"
        }
    }

    public var subtitle: String {
        switch self {
        case .classic: return "Side column · grid right · backdrop tint"
        case .editorial: return "Bold header · centered grid · fact strip"
        case .minimal: return "Quiet, monospace, single column"
        }
    }

    public var availableThemes: [CalendarTheme] {
        switch self {
        case .classic:
            return [.aurora, .midnight, .ocean, .paper, .sunlit, .graphite]
        case .editorial:
            return [.editorialDark, .editorialLight, .editorialSage, .editorialClay]
        case .minimal:
            return [.minimalDark, .minimalLight, .minimalMono]
        }
    }

    public var defaultTheme: CalendarTheme {
        switch self {
        case .classic: return .aurora
        case .editorial: return .editorialDark
        case .minimal: return .minimalDark
        }
    }

    public var defaultDayTheme: CalendarTheme {
        switch self {
        case .classic: return .paper
        case .editorial: return .editorialLight
        case .minimal: return .minimalLight
        }
    }

    public var defaultNightTheme: CalendarTheme {
        switch self {
        case .classic: return .aurora
        case .editorial: return .editorialDark
        case .minimal: return .minimalDark
        }
    }
}

// MARK: - Block positions

public enum BlockID: String, CaseIterable, Codable, Sendable {
    case title
    case facts
    case grid
    case footer

    public var displayName: String {
        switch self {
        case .title: return "Title"
        case .facts: return "Fields"
        case .grid: return "Weeks grid"
        case .footer: return "Footer"
        }
    }

    public var icon: String {
        switch self {
        case .title: return "textformat"
        case .facts: return "square.grid.2x2"
        case .grid: return "rectangle.split.3x3"
        case .footer: return "text.alignleft"
        }
    }
}

/// 2-D position of a block, expressed as fractions of canvas size.
/// `x` is anchor X (typically the leading edge) and `y` is the anchor Y
/// (typically the top edge or vertical center, depending on the block).
public struct BlockPosition: Codable, Equatable, Sendable, Hashable {
    public var x: Double
    public var y: Double

    public init(x: Double = 0, y: Double = 0) {
        self.x = x
        self.y = y
    }

    public func clamped() -> BlockPosition {
        BlockPosition(
            x: min(1.0, max(0.0, x)),
            y: min(1.0, max(0.0, y))
        )
    }
}

// MARK: - Style preset (per-style configuration)

public struct StylePreset: Codable, Equatable, Sendable {
    public var themeMode: ThemeMode
    public var theme: CalendarTheme          // used in .custom mode
    public var dayTheme: CalendarTheme       // used in .system mode (light)
    public var nightTheme: CalendarTheme     // used in .system mode (dark)
    public var positions: [String: BlockPosition]  // BlockID.rawValue → position

    public init(
        themeMode: ThemeMode,
        theme: CalendarTheme,
        dayTheme: CalendarTheme,
        nightTheme: CalendarTheme,
        positions: [String: BlockPosition] = [:]
    ) {
        self.themeMode = themeMode
        self.theme = theme
        self.dayTheme = dayTheme
        self.nightTheme = nightTheme
        self.positions = positions
    }

    public func position(for block: BlockID) -> BlockPosition {
        positions[block.rawValue] ?? StylePreset.fallbackPositions[block.rawValue] ?? .init()
    }

    public mutating func setPosition(_ pos: BlockPosition, for block: BlockID) {
        positions[block.rawValue] = pos.clamped()
    }

    public func resolvedTheme(systemIsDark: Bool) -> CalendarTheme {
        switch themeMode {
        case .custom: return theme
        case .system: return systemIsDark ? nightTheme : dayTheme
        }
    }

    /// Fallback positions used when a preset doesn't explicitly set a block.
    public static let fallbackPositions: [String: BlockPosition] = [
        BlockID.title.rawValue: BlockPosition(x: 0.05, y: 0.15),
        BlockID.facts.rawValue: BlockPosition(x: 0.05, y: 0.45),
        BlockID.grid.rawValue: BlockPosition(x: 0.50, y: 0.50),
        BlockID.footer.rawValue: BlockPosition(x: 0.05, y: 0.96),
    ]

    public static func makeDefault(for style: WallpaperStyle) -> StylePreset {
        StylePreset(
            themeMode: .custom,
            theme: style.defaultTheme,
            dayTheme: style.defaultDayTheme,
            nightTheme: style.defaultNightTheme,
            positions: defaultPositions(for: style)
        )
    }

    /// Each style's visually-tuned default block positions.
    /// Updated from user's preferred layouts (May 2026).
    public static func defaultPositions(for style: WallpaperStyle) -> [String: BlockPosition] {
        switch style {
        case .classic:
            return [
                BlockID.title.rawValue: BlockPosition(x: 0.05, y: 0.33),
                BlockID.facts.rawValue: BlockPosition(x: 0.05, y: 0.76),
                BlockID.grid.rawValue: BlockPosition(x: 0.95, y: 0.47),
                BlockID.footer.rawValue: BlockPosition(x: 0.74, y: 0.97),
            ]
        case .editorial:
            return [
                BlockID.title.rawValue: BlockPosition(x: 0.50, y: 0.10),
                BlockID.facts.rawValue: BlockPosition(x: 0.50, y: 0.86),
                BlockID.grid.rawValue: BlockPosition(x: 0.50, y: 0.48),
                BlockID.footer.rawValue: BlockPosition(x: 0.50, y: 0.97),
            ]
        case .minimal:
            return [
                BlockID.title.rawValue: BlockPosition(x: 0.50, y: 0.12),
                BlockID.facts.rawValue: BlockPosition(x: 0.65, y: 0.78),
                BlockID.grid.rawValue: BlockPosition(x: 0.50, y: 0.45),
                BlockID.footer.rawValue: BlockPosition(x: 0.87, y: 0.96),
            ]
        }
    }
}

// MARK: - Settings root

public struct LifeCalendarSettings: Codable, Equatable, Sendable {
    public var birthDate: Date?
    public var lifeExpectancyYears: Int

    public var wallpaperStyle: WallpaperStyle
    public var stylePresets: [String: StylePreset]   // WallpaperStyle.rawValue → preset

    public var wallpaperEnabled: Bool
    public var wallpaperOpacity: Double
    public var backdropOpacity: Double

    public var visitedCountryCodes: Set<String>
    public var nextDestination: String
    public var autoDetectNextDestination: Bool
    public var enabledCalendarIdentifiers: Set<String>
    public var currentHobby: String
    public var currentlyLearning: String
    public var wallpaperTitle: String

    public init(
        birthDate: Date? = nil,
        lifeExpectancyYears: Int = 90,
        wallpaperStyle: WallpaperStyle = .classic,
        stylePresets: [String: StylePreset] = LifeCalendarSettings.allDefaultPresets(),
        wallpaperEnabled: Bool = false,
        wallpaperOpacity: Double = 0.85,
        backdropOpacity: Double = 0.04,
        visitedCountryCodes: Set<String> = [],
        nextDestination: String = "",
        autoDetectNextDestination: Bool = false,
        enabledCalendarIdentifiers: Set<String> = [],
        currentHobby: String = "",
        currentlyLearning: String = "",
        wallpaperTitle: String = ""
    ) {
        self.birthDate = birthDate
        self.lifeExpectancyYears = lifeExpectancyYears
        self.wallpaperStyle = wallpaperStyle
        self.stylePresets = stylePresets
        self.wallpaperEnabled = wallpaperEnabled
        self.wallpaperOpacity = wallpaperOpacity
        self.backdropOpacity = backdropOpacity
        self.visitedCountryCodes = visitedCountryCodes
        self.nextDestination = nextDestination
        self.autoDetectNextDestination = autoDetectNextDestination
        self.enabledCalendarIdentifiers = enabledCalendarIdentifiers
        self.currentHobby = currentHobby
        self.currentlyLearning = currentlyLearning
        self.wallpaperTitle = wallpaperTitle
    }

    public static func allDefaultPresets() -> [String: StylePreset] {
        WallpaperStyle.allCases.reduce(into: [:]) { dict, style in
            dict[style.rawValue] = StylePreset.makeDefault(for: style)
        }
    }

    public var activePreset: StylePreset {
        stylePresets[wallpaperStyle.rawValue] ?? StylePreset.makeDefault(for: wallpaperStyle)
    }

    public mutating func updateActivePreset(_ mutate: (inout StylePreset) -> Void) {
        var preset = activePreset
        mutate(&preset)
        stylePresets[wallpaperStyle.rawValue] = preset
    }

    public func position(for block: BlockID, in style: WallpaperStyle? = nil) -> BlockPosition {
        let s = style ?? wallpaperStyle
        let preset =
            stylePresets[s.rawValue] ?? StylePreset.makeDefault(for: s)
        return preset.position(for: block)
    }

    public func resolvedTheme(systemIsDark: Bool) -> CalendarTheme {
        activePreset.resolvedTheme(systemIsDark: systemIsDark)
    }

    public var countriesVisited: Int { visitedCountryCodes.count }

    public var resolvedWallpaperTitle: String {
        let trimmed = wallpaperTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Life in Weeks" : trimmed
    }

    public static let defaultLifeExpectancyYears = 90
    public static let minimumLifeExpectancyYears = 1
    public static let maximumLifeExpectancyYears = 130

    public static var defaults: LifeCalendarSettings {
        LifeCalendarSettings()
    }

    public var normalizedLifeExpectancyYears: Int {
        min(
            Self.maximumLifeExpectancyYears,
            max(Self.minimumLifeExpectancyYears, lifeExpectancyYears)
        )
    }

    public var normalizedWallpaperOpacity: Double {
        min(1.0, max(0.2, wallpaperOpacity))
    }

    public var normalizedBackdropOpacity: Double {
        min(0.25, max(0.0, backdropOpacity))
    }

    // MARK: - Backwards-compat shims (write through to active preset)

    public var theme: CalendarTheme {
        get { activePreset.theme }
        set { updateActivePreset { $0.theme = newValue } }
    }

    public var themeMode: ThemeMode {
        get { activePreset.themeMode }
        set { updateActivePreset { $0.themeMode = newValue } }
    }

    public var dayTheme: CalendarTheme {
        get { activePreset.dayTheme }
        set { updateActivePreset { $0.dayTheme = newValue } }
    }

    public var nightTheme: CalendarTheme {
        get { activePreset.nightTheme }
        set { updateActivePreset { $0.nightTheme = newValue } }
    }

    public var layoutTitleYRatio: Double {
        get { activePreset.position(for: .title).y }
        set {
            updateActivePreset { p in
                var pos = p.position(for: .title)
                pos.y = newValue
                p.setPosition(pos, for: .title)
            }
        }
    }

    public var layoutFactsYRatio: Double {
        get { activePreset.position(for: .facts).y }
        set {
            updateActivePreset { p in
                var pos = p.position(for: .facts)
                pos.y = newValue
                p.setPosition(pos, for: .facts)
            }
        }
    }

    public var layoutGridYRatio: Double {
        get { activePreset.position(for: .grid).y }
        set {
            updateActivePreset { p in
                var pos = p.position(for: .grid)
                pos.y = newValue
                p.setPosition(pos, for: .grid)
            }
        }
    }

    public var layoutFooterBottomRatio: Double {
        get { max(0.0, 1.0 - activePreset.position(for: .footer).y) }
        set {
            updateActivePreset { p in
                var pos = p.position(for: .footer)
                pos.y = 1.0 - newValue
                p.setPosition(pos, for: .footer)
            }
        }
    }

    public var clampedLayoutTitleYRatio: Double {
        min(0.85, max(0.0, layoutTitleYRatio))
    }
    public var clampedLayoutFactsYRatio: Double {
        min(0.95, max(0.0, layoutFactsYRatio))
    }
    public var clampedLayoutGridYRatio: Double {
        min(1.0, max(0.0, layoutGridYRatio))
    }
    public var clampedLayoutFooterBottomRatio: Double {
        min(0.30, max(0.0, layoutFooterBottomRatio))
    }

    // MARK: - Codable with legacy migration

    private enum CodingKeys: String, CodingKey {
        case birthDate
        case lifeExpectancyYears
        case wallpaperStyle
        case stylePresets
        case wallpaperEnabled
        case wallpaperOpacity
        case backdropOpacity
        case visitedCountryCodes
        case nextDestination
        case autoDetectNextDestination
        case enabledCalendarIdentifiers
        case currentHobby
        case currentlyLearning
        case wallpaperTitle
    }

    /// Legacy keys from the pre-redesign single-classic data model.
    /// Read-only — only used to migrate into the new presets dict on decode.
    private enum LegacyCodingKeys: String, CodingKey {
        case theme
        case themeMode
        case dayTheme
        case nightTheme
        case layoutTitleYRatio
        case layoutFactsYRatio
        case layoutGridYRatio
        case layoutFooterBottomRatio
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacy = try? decoder.container(keyedBy: LegacyCodingKeys.self)

        self.birthDate = try container.decodeIfPresent(Date.self, forKey: .birthDate)
        self.lifeExpectancyYears =
            try container.decodeIfPresent(Int.self, forKey: .lifeExpectancyYears)
            ?? Self.defaultLifeExpectancyYears

        self.wallpaperStyle =
            try container.decodeIfPresent(WallpaperStyle.self, forKey: .wallpaperStyle) ?? .classic

        self.wallpaperEnabled =
            try container.decodeIfPresent(Bool.self, forKey: .wallpaperEnabled) ?? false
        self.wallpaperOpacity =
            try container.decodeIfPresent(Double.self, forKey: .wallpaperOpacity) ?? 0.85
        self.backdropOpacity =
            try container.decodeIfPresent(Double.self, forKey: .backdropOpacity) ?? 0.04

        self.visitedCountryCodes =
            try container.decodeIfPresent(Set<String>.self, forKey: .visitedCountryCodes) ?? []
        self.nextDestination =
            try container.decodeIfPresent(String.self, forKey: .nextDestination) ?? ""
        self.autoDetectNextDestination =
            try container.decodeIfPresent(Bool.self, forKey: .autoDetectNextDestination) ?? false
        self.enabledCalendarIdentifiers =
            try container.decodeIfPresent(Set<String>.self, forKey: .enabledCalendarIdentifiers) ?? []
        self.currentHobby =
            try container.decodeIfPresent(String.self, forKey: .currentHobby) ?? ""
        self.currentlyLearning =
            try container.decodeIfPresent(String.self, forKey: .currentlyLearning) ?? ""
        self.wallpaperTitle =
            try container.decodeIfPresent(String.self, forKey: .wallpaperTitle) ?? ""

        // Start with full default presets, then merge in:
        //  - new-format stored presets (preferred)
        //  - legacy single-classic theme/positions (migrate into classic slot)
        var presets = LifeCalendarSettings.allDefaultPresets()

        if let stored =
            try container.decodeIfPresent([String: StylePreset].self, forKey: .stylePresets)
        {
            for (key, value) in stored {
                presets[key] = value
            }
        } else {
            // Legacy migration: fold the old flat fields into the classic preset.
            var classic =
                presets[WallpaperStyle.classic.rawValue]
                ?? StylePreset.makeDefault(for: .classic)
            if let mode = try legacy?.decodeIfPresent(ThemeMode.self, forKey: .themeMode) {
                classic.themeMode = mode
            }
            if let t = try legacy?.decodeIfPresent(CalendarTheme.self, forKey: .theme) {
                classic.theme = t
            }
            if let t = try legacy?.decodeIfPresent(CalendarTheme.self, forKey: .dayTheme) {
                classic.dayTheme = t
            }
            if let t = try legacy?.decodeIfPresent(CalendarTheme.self, forKey: .nightTheme) {
                classic.nightTheme = t
            }
            let legacyTitleY =
                try legacy?.decodeIfPresent(Double.self, forKey: .layoutTitleYRatio)
            let legacyFactsY =
                try legacy?.decodeIfPresent(Double.self, forKey: .layoutFactsYRatio)
            let legacyGridY =
                try legacy?.decodeIfPresent(Double.self, forKey: .layoutGridYRatio)
            let legacyFooterBottom =
                try legacy?.decodeIfPresent(Double.self, forKey: .layoutFooterBottomRatio)
            let defaults = StylePreset.defaultPositions(for: .classic)
            classic.positions = [
                BlockID.title.rawValue: BlockPosition(
                    x: defaults[BlockID.title.rawValue]?.x ?? 0.05,
                    y: legacyTitleY ?? defaults[BlockID.title.rawValue]?.y ?? 0.18
                ),
                BlockID.facts.rawValue: BlockPosition(
                    x: defaults[BlockID.facts.rawValue]?.x ?? 0.05,
                    y: legacyFactsY ?? defaults[BlockID.facts.rawValue]?.y ?? 0.50
                ),
                BlockID.grid.rawValue: BlockPosition(
                    x: defaults[BlockID.grid.rawValue]?.x ?? 0.70,
                    y: legacyGridY ?? defaults[BlockID.grid.rawValue]?.y ?? 0.50
                ),
                BlockID.footer.rawValue: BlockPosition(
                    x: defaults[BlockID.footer.rawValue]?.x ?? 0.05,
                    y: legacyFooterBottom.map { 1.0 - $0 }
                        ?? defaults[BlockID.footer.rawValue]?.y ?? 0.96
                ),
            ]
            presets[WallpaperStyle.classic.rawValue] = classic
        }

        self.stylePresets = presets
    }
}
