import XCTest
@testable import IntervalTimer

final class CalendarTests: XCTestCase {
    /// Build a local Date from a 1-based month.
    func date(_ y: Int, _ m: Int, _ d: Int, _ hh: Int = 12, _ mm: Int = 0) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = hh; c.minute = mm
        return Calendar.current.date(from: c)!
    }

    // MARK: dayKey

    func testDayKeyZeroPadded() {
        XCTAssertEqual(CalendarMath.dayKey(date(2026, 6, 12)), "2026-06-12")
        XCTAssertEqual(CalendarMath.dayKey(date(2026, 1, 3)), "2026-01-03")
    }

    func testDayKeyUsesLocalDay() {
        XCTAssertEqual(CalendarMath.dayKey(date(2026, 6, 12, 23, 30)), "2026-06-12")
    }

    // MARK: monthMatrix (1-based month)

    func testRowsOfSeven() {
        for week in CalendarMath.monthMatrix(year: 2026, month: 6) {
            XCTAssertEqual(week.count, 7)
        }
    }

    func testFebruary2026StartsOnSunday() {
        let weeks = CalendarMath.monthMatrix(year: 2026, month: 2) // Feb 1 2026 is a Sunday
        XCTAssertEqual(Calendar.current.component(.day, from: weeks[0][0]!), 1)
        XCTAssertEqual(weeks.flatMap { $0 }.compactMap { $0 }.count, 28)
    }

    func testPadsMonthsStartingMidWeek() {
        let weeks = CalendarMath.monthMatrix(year: 2026, month: 6) // Jun 1 2026 is a Monday
        XCTAssertNil(weeks[0][0])
        XCTAssertEqual(Calendar.current.component(.day, from: weeks[0][1]!), 1)
        XCTAssertEqual(weeks.flatMap { $0 }.compactMap { $0 }.count, 30)
    }

    func testLeapYear() {
        let weeks = CalendarMath.monthMatrix(year: 2024, month: 2)
        XCTAssertEqual(weeks.flatMap { $0 }.compactMap { $0 }.count, 29)
    }

    // MARK: streakLength

    func testCountsConsecutiveDaysEndingToday() {
        let today = date(2026, 6, 12)
        let days: Set = ["2026-06-10", "2026-06-11", "2026-06-12"]
        XCTAssertEqual(CalendarMath.streakLength(days, today: today), 3)
    }

    func testKeepsYesterdayStreakAlive() {
        let today = date(2026, 6, 12)
        let days: Set = ["2026-06-10", "2026-06-11"]
        XCTAssertEqual(CalendarMath.streakLength(days, today: today), 2)
    }

    func testBreaksOnGap() {
        let today = date(2026, 6, 12)
        let days: Set = ["2026-06-08", "2026-06-09", "2026-06-11", "2026-06-12"]
        XCTAssertEqual(CalendarMath.streakLength(days, today: today), 2)
    }

    func testZeroWithNoRecentSessions() {
        let today = date(2026, 6, 12)
        XCTAssertEqual(CalendarMath.streakLength([], today: today), 0)
        XCTAssertEqual(CalendarMath.streakLength(["2026-06-01"], today: today), 0)
    }

    func testCrossesMonthBoundaries() {
        let days: Set = ["2026-05-30", "2026-05-31", "2026-06-01"]
        XCTAssertEqual(CalendarMath.streakLength(days, today: date(2026, 6, 1)), 3)
    }

    // MARK: bestStreak

    func testBestStreakFindsLongestRunAnywhere() {
        let days: Set = ["2026-05-01", "2026-05-02", "2026-05-03",
                         "2026-06-10", "2026-06-11"]
        XCTAssertEqual(CalendarMath.bestStreak(days), 3)
    }

    func testBestStreakCrossesMonthBoundary() {
        let days: Set = ["2026-05-30", "2026-05-31", "2026-06-01", "2026-06-02"]
        XCTAssertEqual(CalendarMath.bestStreak(days), 4)
    }

    func testBestStreakEdgeCases() {
        XCTAssertEqual(CalendarMath.bestStreak([]), 0)
        XCTAssertEqual(CalendarMath.bestStreak(["2026-06-12"]), 1)
        XCTAssertEqual(CalendarMath.bestStreak(["2026-06-12", "2026-06-14"]), 1)
    }

    // MARK: weekDays

    func testWeekDaysAreSundayFirstSeven() {
        let week = CalendarMath.weekDays(containing: date(2026, 6, 12)) // Friday
        XCTAssertEqual(week.count, 7)
        XCTAssertEqual(Calendar.current.component(.weekday, from: week[0]), 1)
        XCTAssertEqual(CalendarMath.dayKey(week[0]), "2026-06-07")
        XCTAssertEqual(CalendarMath.dayKey(week[6]), "2026-06-13")
    }

    /// Must agree with `weekDays` (Sunday-first), not the locale's firstWeekday.
    func testThisWeekUsesTheSameSundayFirstWeekAsTheStrip() {
        let calendar = Calendar.current
        let now = calendar.date(from: DateComponents(
            year: 2026, month: 6, day: 10, hour: 12))! // Wednesday
        let week = CalendarMath.weekDays(containing: now)
        let dates = [
            week[0].addingTimeInterval(60),                     // Sunday, in week
            week[6].addingTimeInterval(23 * 60 * 60),           // Saturday, in week
            week[0].addingTimeInterval(-60),                    // Saturday of prior week
            week[6].addingTimeInterval(24 * 60 * 60),           // Sunday of next week
        ]

        XCTAssertEqual(CalendarMath.countInCurrentWeek(dates, now: now), 2)
    }

    // MARK: addMonths (1-based month)

    func testAddMonthsWraps() {
        var r = CalendarMath.addMonths(year: 2026, month: 12, delta: 1)
        XCTAssertEqual(r.year, 2027); XCTAssertEqual(r.month, 1)
        r = CalendarMath.addMonths(year: 2026, month: 1, delta: -1)
        XCTAssertEqual(r.year, 2025); XCTAssertEqual(r.month, 12)
        r = CalendarMath.addMonths(year: 2026, month: 6, delta: -7)
        XCTAssertEqual(r.year, 2025); XCTAssertEqual(r.month, 11)
    }
}
