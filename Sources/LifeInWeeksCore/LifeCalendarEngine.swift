import Foundation

public enum WeekState: Equatable, Sendable {
    case lived
    case current
    case future
}

public struct WeekRange: Equatable, Sendable {
    public let index: Int
    public let yearIndex: Int
    public let weekIndex: Int
    public let startDate: Date
    public let endDate: Date
}

public struct LifeCalendarSnapshot: Equatable, Sendable {
    public let birthDate: Date
    public let asOfDate: Date
    public let lifeExpectancyYears: Int
    public let totalWeeks: Int
    public let elapsedWeeks: Int
    public let rawElapsedWeeks: Int
    public let currentWeekIndex: Int?
    public let ageYears: Int
    public let daysIntoCurrentWeek: Int

    public var remainingWeeks: Int {
        max(0, totalWeeks - elapsedWeeks)
    }

    public var progress: Double {
        guard totalWeeks > 0 else { return 0 }
        return min(1, max(0, Double(elapsedWeeks) / Double(totalWeeks)))
    }

    public var currentDisplayWeek: Int {
        guard let currentWeekIndex else { return min(totalWeeks, elapsedWeeks) }
        return currentWeekIndex + 1
    }

    public var currentYear: Int {
        guard let currentWeekIndex else { return min(lifeExpectancyYears, elapsedWeeks / 52) }
        return currentWeekIndex / 52
    }

    public var weekProgressWithinCurrent: Double {
        min(1, max(0, Double(daysIntoCurrentWeek) / 7.0))
    }

    public func state(forWeekIndex index: Int) -> WeekState {
        if index < elapsedWeeks {
            return .lived
        }

        if currentWeekIndex == index {
            return .current
        }

        return .future
    }
}

public struct LifeCalendarEngine: Sendable {
    public var calendar: Calendar

    public init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    public func snapshot(
        for settings: LifeCalendarSettings,
        asOf asOfDate: Date = Date()
    ) -> LifeCalendarSnapshot? {
        guard let birthDate = settings.birthDate else {
            return nil
        }

        let lifeExpectancyYears = settings.normalizedLifeExpectancyYears
        let totalWeeks = lifeExpectancyYears * 52
        let rawElapsedWeeks = weeksElapsed(from: birthDate, to: asOfDate)
        let elapsedWeeks = min(totalWeeks, max(0, rawElapsedWeeks))
        let currentWeekIndex: Int? =
            rawElapsedWeeks >= 0 && rawElapsedWeeks < totalWeeks ? elapsedWeeks : nil

        let start = calendar.startOfDay(for: birthDate)
        let end = calendar.startOfDay(for: asOfDate)
        let daysSinceBirth = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        let daysIntoCurrentWeek = max(0, daysSinceBirth % 7)
        let ageYears = max(0, calendar.dateComponents([.year], from: start, to: end).year ?? 0)

        return LifeCalendarSnapshot(
            birthDate: birthDate,
            asOfDate: asOfDate,
            lifeExpectancyYears: lifeExpectancyYears,
            totalWeeks: totalWeeks,
            elapsedWeeks: elapsedWeeks,
            rawElapsedWeeks: rawElapsedWeeks,
            currentWeekIndex: currentWeekIndex,
            ageYears: ageYears,
            daysIntoCurrentWeek: daysIntoCurrentWeek
        )
    }

    public func weekRange(
        birthDate: Date,
        weekIndex index: Int
    ) -> WeekRange {
        let normalizedBirthDate = calendar.startOfDay(for: birthDate)
        let startDate =
            calendar.date(byAdding: .day, value: index * 7, to: normalizedBirthDate)
            ?? normalizedBirthDate
        let endDate =
            calendar.date(byAdding: .day, value: 6, to: startDate)
            ?? startDate

        return WeekRange(
            index: index,
            yearIndex: index / 52,
            weekIndex: index % 52,
            startDate: startDate,
            endDate: endDate
        )
    }

    public func weeksElapsed(from birthDate: Date, to asOfDate: Date) -> Int {
        let start = calendar.startOfDay(for: birthDate)
        let end = calendar.startOfDay(for: asOfDate)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0

        if days >= 0 {
            return days / 7
        }

        return -Int(ceil(Double(abs(days)) / 7.0))
    }
}
