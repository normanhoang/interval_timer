import SwiftUI

/// This week at a glance: a day circle per column with one dot per session
/// underneath. Tapping a day filters the History list; "Month" swaps in the
/// full calendar.
struct WeekStrip: View {
    /// dayKey → number of sessions that day.
    var sessionsByDay: [String: Int]
    @Binding var selectedDay: String?
    @Binding var showMonth: Bool

    @Environment(\.colorScheme) private var scheme

    private static let letters = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        let theme = ThemeColors.for(scheme)
        let days = CalendarMath.weekDays()
        let todayKey = CalendarMath.dayKey(.now)
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("This week · \(monthTitle(days))")
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(theme.ink)
                Spacer()
                Button { withAnimation(.easeInOut(duration: 0.2)) { showMonth.toggle() } } label: {
                    HStack(spacing: 4) {
                        Text("Month").font(.system(size: 15, weight: .semibold))
                        Image(systemName: showMonth ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(theme.accentText)
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.offset) { i, day in
                    let key = CalendarMath.dayKey(day)
                    dayColumn(letter: Self.letters[i], day: day, key: key,
                              isToday: key == todayKey, theme: theme)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func dayColumn(letter: String, day: Date, key: String, isToday: Bool,
                           theme: ThemeColors) -> some View {
        let count = sessionsByDay[key] ?? 0
        let future = day > Date.now && !isToday
        let selected = selectedDay == key
        return VStack(spacing: 6) {
            Text(letter).font(.system(size: 11)).foregroundStyle(theme.inkLabel)
            Button { selectedDay = selected ? nil : key } label: {
                Text("\(Calendar.current.component(.day, from: day))")
                    .font(.system(size: 15, weight: isToday ? .bold : .regular))
                    .foregroundStyle(isToday ? theme.onAccent
                                     : (future ? theme.ink.opacity(0.4) : theme.ink))
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(isToday ? theme.accent
                                              : (future ? .clear : theme.cardFill)))
                    .overlay(Circle().strokeBorder(selected && !isToday ? theme.accentTintBorder : .clear,
                                                   lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            HStack(spacing: 3) {
                ForEach(0..<min(count, 3), id: \.self) { _ in
                    Circle().fill(theme.accent).frame(width: 5, height: 5)
                }
            }
            .frame(height: 5)
        }
    }

    private func monthTitle(_ days: [Date]) -> String {
        let comps = Calendar.current.dateComponents([.year, .month], from: .now)
        return CalendarMath.monthTitle(year: comps.year ?? 0, month: comps.month ?? 1)
    }
}
