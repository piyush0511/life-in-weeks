import Foundation

public enum CalendarTheme: String, CaseIterable, Codable, Identifiable, Sendable {
    case aurora
    case graphite
    case sunlit
    case ocean
    case paper
    case midnight

    public var id: String { rawValue }
}

public enum ThemeMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case custom
    case system

    public var id: String { rawValue }
}

public struct LifeCalendarSettings: Codable, Equatable, Sendable {
    public var birthDate: Date?
    public var lifeExpectancyYears: Int
    public var theme: CalendarTheme
    public var themeMode: ThemeMode
    public var dayTheme: CalendarTheme
    public var nightTheme: CalendarTheme
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
    public var layoutTitleYRatio: Double
    public var layoutFactsYRatio: Double
    public var layoutGridYRatio: Double
    public var layoutFooterBottomRatio: Double

    public init(
        birthDate: Date? = nil,
        lifeExpectancyYears: Int = 90,
        theme: CalendarTheme = .aurora,
        themeMode: ThemeMode = .custom,
        dayTheme: CalendarTheme = .paper,
        nightTheme: CalendarTheme = .aurora,
        wallpaperEnabled: Bool = false,
        wallpaperOpacity: Double = 0.85,
        backdropOpacity: Double = 0.04,
        visitedCountryCodes: Set<String> = [],
        nextDestination: String = "",
        autoDetectNextDestination: Bool = false,
        enabledCalendarIdentifiers: Set<String> = [],
        currentHobby: String = "",
        currentlyLearning: String = "",
        wallpaperTitle: String = "",
        layoutTitleYRatio: Double = 0.15,
        layoutFactsYRatio: Double = 0.45,
        layoutGridYRatio: Double = 0.50,
        layoutFooterBottomRatio: Double = 0.04
    ) {
        self.birthDate = birthDate
        self.lifeExpectancyYears = lifeExpectancyYears
        self.theme = theme
        self.themeMode = themeMode
        self.dayTheme = dayTheme
        self.nightTheme = nightTheme
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
        self.layoutTitleYRatio = layoutTitleYRatio
        self.layoutFactsYRatio = layoutFactsYRatio
        self.layoutGridYRatio = layoutGridYRatio
        self.layoutFooterBottomRatio = layoutFooterBottomRatio
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

    public func resolvedTheme(systemIsDark: Bool) -> CalendarTheme {
        switch themeMode {
        case .custom: return theme
        case .system: return systemIsDark ? nightTheme : dayTheme
        }
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

    private enum CodingKeys: String, CodingKey {
        case birthDate
        case lifeExpectancyYears
        case theme
        case themeMode
        case dayTheme
        case nightTheme
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
        case layoutTitleYRatio
        case layoutFactsYRatio
        case layoutGridYRatio
        case layoutFooterBottomRatio
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.birthDate = try container.decodeIfPresent(Date.self, forKey: .birthDate)
        self.lifeExpectancyYears =
            try container.decodeIfPresent(Int.self, forKey: .lifeExpectancyYears)
            ?? Self.defaultLifeExpectancyYears
        self.theme = try container.decodeIfPresent(CalendarTheme.self, forKey: .theme) ?? .aurora
        self.themeMode =
            try container.decodeIfPresent(ThemeMode.self, forKey: .themeMode) ?? .custom
        self.dayTheme =
            try container.decodeIfPresent(CalendarTheme.self, forKey: .dayTheme) ?? .paper
        self.nightTheme =
            try container.decodeIfPresent(CalendarTheme.self, forKey: .nightTheme) ?? .aurora
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
        self.layoutTitleYRatio =
            try container.decodeIfPresent(Double.self, forKey: .layoutTitleYRatio) ?? 0.15
        self.layoutFactsYRatio =
            try container.decodeIfPresent(Double.self, forKey: .layoutFactsYRatio) ?? 0.45
        self.layoutGridYRatio =
            try container.decodeIfPresent(Double.self, forKey: .layoutGridYRatio) ?? 0.50
        self.layoutFooterBottomRatio =
            try container.decodeIfPresent(Double.self, forKey: .layoutFooterBottomRatio) ?? 0.04
    }
}
