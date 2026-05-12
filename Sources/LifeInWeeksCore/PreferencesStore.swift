import Foundation

public struct PreferencesStore {
    public static let defaultSuiteName: String? = nil
    public static let futureAppGroupSuiteName = "group.com.example.LifeInWeeks"

    private let defaults: UserDefaults
    private let key = "lifeCalendarSettings"

    public init(suiteName: String? = Self.defaultSuiteName) {
        if let suiteName, let defaults = UserDefaults(suiteName: suiteName) {
            self.defaults = defaults
        } else {
            self.defaults = .standard
        }
    }

    public func load() -> LifeCalendarSettings {
        guard
            let data = defaults.data(forKey: key),
            let settings = try? JSONDecoder().decode(LifeCalendarSettings.self, from: data)
        else {
            return .defaults
        }

        return settings
    }

    public func save(_ settings: LifeCalendarSettings) {
        guard let data = try? JSONEncoder().encode(settings) else {
            return
        }

        defaults.set(data, forKey: key)
    }

    public func reset() {
        defaults.removeObject(forKey: key)
    }
}
