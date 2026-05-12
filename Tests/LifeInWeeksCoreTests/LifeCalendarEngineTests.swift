import Foundation
import Testing

@testable import LifeInWeeksCore

@Suite("Life calendar engine")
struct LifeCalendarEngineTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test("birth date starts at first current week")
    func birthDateStartsAtCurrentWeek() throws {
        let birthDate = try date(year: 1990, month: 1, day: 1)
        let engine = LifeCalendarEngine(calendar: calendar)
        let settings = LifeCalendarSettings(birthDate: birthDate, lifeExpectancyYears: 90)
        let snapshot = try #require(engine.snapshot(for: settings, asOf: birthDate))

        #expect(snapshot.elapsedWeeks == 0)
        #expect(snapshot.currentWeekIndex == 0)
        #expect(snapshot.state(forWeekIndex: 0) == .current)
        #expect(snapshot.totalWeeks == 4_680)
    }

    @Test("elapsed weeks advance in complete seven day blocks")
    func elapsedWeeksAdvanceInSevenDayBlocks() throws {
        let birthDate = try date(year: 1990, month: 1, day: 1)
        let asOfDate = try date(year: 1990, month: 1, day: 9)
        let engine = LifeCalendarEngine(calendar: calendar)
        let settings = LifeCalendarSettings(birthDate: birthDate, lifeExpectancyYears: 90)
        let snapshot = try #require(engine.snapshot(for: settings, asOf: asOfDate))

        #expect(snapshot.elapsedWeeks == 1)
        #expect(snapshot.currentWeekIndex == 1)
        #expect(snapshot.state(forWeekIndex: 0) == .lived)
        #expect(snapshot.state(forWeekIndex: 1) == .current)
    }

    @Test("future birth dates do not mark a current week")
    func futureBirthDateHasNoCurrentWeek() throws {
        let birthDate = try date(year: 2030, month: 1, day: 1)
        let asOfDate = try date(year: 2029, month: 12, day: 20)
        let engine = LifeCalendarEngine(calendar: calendar)
        let settings = LifeCalendarSettings(birthDate: birthDate, lifeExpectancyYears: 90)
        let snapshot = try #require(engine.snapshot(for: settings, asOf: asOfDate))

        #expect(snapshot.elapsedWeeks == 0)
        #expect(snapshot.rawElapsedWeeks == -2)
        #expect(snapshot.currentWeekIndex == nil)
        #expect(snapshot.state(forWeekIndex: 0) == .future)
    }

    @Test("elapsed weeks clamp at total life span")
    func elapsedWeeksClampAtTotalLifeSpan() throws {
        let birthDate = try date(year: 1900, month: 1, day: 1)
        let asOfDate = try date(year: 2020, month: 1, day: 1)
        let engine = LifeCalendarEngine(calendar: calendar)
        let settings = LifeCalendarSettings(birthDate: birthDate, lifeExpectancyYears: 1)
        let snapshot = try #require(engine.snapshot(for: settings, asOf: asOfDate))

        #expect(snapshot.totalWeeks == 52)
        #expect(snapshot.elapsedWeeks == 52)
        #expect(snapshot.remainingWeeks == 0)
        #expect(snapshot.currentWeekIndex == nil)
    }

    @Test("age years grow with calendar years")
    func ageYearsGrowWithCalendarYears() throws {
        let birthDate = try date(year: 1990, month: 6, day: 1)
        let asOfDate = try date(year: 2026, month: 5, day: 11)
        let engine = LifeCalendarEngine(calendar: calendar)
        let settings = LifeCalendarSettings(birthDate: birthDate, lifeExpectancyYears: 90)
        let snapshot = try #require(engine.snapshot(for: settings, asOf: asOfDate))

        #expect(snapshot.ageYears == 35)
        #expect(snapshot.daysIntoCurrentWeek >= 0)
        #expect(snapshot.daysIntoCurrentWeek < 7)
    }

    @Test("days into current week wrap weekly")
    func daysIntoCurrentWeekWrap() throws {
        let birthDate = try date(year: 1990, month: 1, day: 1)
        let asOfDate = try date(year: 1990, month: 1, day: 4)
        let engine = LifeCalendarEngine(calendar: calendar)
        let settings = LifeCalendarSettings(birthDate: birthDate, lifeExpectancyYears: 90)
        let snapshot = try #require(engine.snapshot(for: settings, asOf: asOfDate))

        #expect(snapshot.daysIntoCurrentWeek == 3)
        #expect(snapshot.weekProgressWithinCurrent > 0.4)
        #expect(snapshot.weekProgressWithinCurrent < 0.5)
    }

    @Test("week range maps index to year and week")
    func weekRangeMapsIndexToYearAndWeek() throws {
        let birthDate = try date(year: 1990, month: 1, day: 1)
        let engine = LifeCalendarEngine(calendar: calendar)
        let range = engine.weekRange(birthDate: birthDate, weekIndex: 53)
        let expectedStartDate = try date(year: 1991, month: 1, day: 7)
        let expectedEndDate = try date(year: 1991, month: 1, day: 13)

        #expect(range.yearIndex == 1)
        #expect(range.weekIndex == 1)
        #expect(range.startDate == expectedStartDate)
        #expect(range.endDate == expectedEndDate)
    }

    private func date(year: Int, month: Int, day: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }
}
