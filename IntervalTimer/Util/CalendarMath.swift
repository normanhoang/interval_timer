import Foundation

enum CalendarMath {
    private static let calendar = Calendar.current

    private static let monthTitleFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "LLLL yyyy"
        return fmt
    }()

    /// Local calendar-day key, e.g. "2026-06-12".
    static func dayKey(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Weeks (Sunday-first rows of 7) for a month; `month` is 1-based.
    /// Cells outside the month are nil.
    static func monthMatrix(year: Int, month: Int) -> [[Date?]] {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        guard let first = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: first)
        else { return [] }
        // weekday: 1 = Sunday → 0 padding cells before day 1.
        let startPad = calendar.component(.weekday, from: first) - 1
        let daysInMonth = range.count

        var cells: [Date?] = Array(repeating: nil, count: startPad)
        for d in 1...daysInMonth {
            comps.day = d
            cells.append(calendar.date(from: comps))
        }
        while cells.count % 7 != 0 { cells.append(nil) }

        var weeks: [[Date?]] = []
        var i = 0
        while i < cells.count {
            weeks.append(Array(cells[i..<min(i + 7, cells.count)]))
            i += 7
        }
        return weeks
    }

    /// Month arithmetic that handles year wrap. `month` is 1-based.
    static func addMonths(year: Int, month: Int, delta: Int) -> (year: Int, month: Int) {
        let total = year * 12 + (month - 1) + delta
        return (year: total / 12, month: (((total % 12) + 12) % 12) + 1)
    }

    /// Consecutive workout days ending today — or yesterday, so an unbroken run
    /// isn't shown as 0 before today's session happens.
    static func streakLength(_ markedDays: Set<String>, today: Date = .now) -> Int {
        var cursor = today
        if !markedDays.contains(dayKey(cursor)) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        var streak = 0
        while markedDays.contains(dayKey(cursor)) {
            streak += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        return streak
    }

    /// Longest run of consecutive workout days ever recorded ("Best: 7 days").
    static func bestStreak(_ markedDays: Set<String>) -> Int {
        let dates = markedDays.compactMap(date(fromKey:)).sorted()
        guard !dates.isEmpty else { return 0 }
        var best = 1
        var run = 1
        for i in 1..<dates.count {
            let gap = calendar.dateComponents([.day], from: dates[i - 1], to: dates[i]).day ?? 0
            run = gap == 1 ? run + 1 : 1
            best = max(best, run)
        }
        return best
    }

    /// Inverse of `dayKey` — local midnight for a "2026-06-12" key.
    static func date(fromKey key: String) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var comps = DateComponents()
        comps.year = parts[0]
        comps.month = parts[1]
        comps.day = parts[2]
        return calendar.date(from: comps)
    }

    /// The seven days of `date`'s week, Sunday-first (History week strip).
    static func weekDays(containing date: Date = .now) -> [Date] {
        let start = calendar.date(byAdding: .day, value: -(calendar.component(.weekday, from: date) - 1),
                                  to: calendar.startOfDay(for: date)) ?? date
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    static func monthTitle(year: Int, month: Int) -> String {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        guard let date = calendar.date(from: comps) else { return "" }
        return monthTitleFormatter.string(from: date)
    }
}
