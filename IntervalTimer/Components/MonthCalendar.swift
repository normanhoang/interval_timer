import SwiftUI

/// Habit-tracker month grid: highlights workout days, tap a marked day to filter.
struct MonthCalendar: View {
    /// dayKey()s that have at least one session.
    var markedDays: Set<String>
    @Binding var selectedDay: String?

    @Environment(\.colorScheme) private var scheme
    @State private var visible: (year: Int, month: Int)
    /// Cached grid for the visible month — rebuilding it every body evaluation
    /// creates ~35 Dates via Calendar for no reason.
    @State private var weeks: [[Date?]]

    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    private let primary = Color(hex: Palette.primary)

    init(markedDays: Set<String>, selectedDay: Binding<String?>) {
        self.markedDays = markedDays
        self._selectedDay = selectedDay
        let c = Calendar.current.dateComponents([.year, .month], from: .now)
        let initial = (year: c.year ?? 2026, month: c.month ?? 1)
        _visible = State(initialValue: initial)
        _weeks = State(initialValue: CalendarMath.monthMatrix(year: initial.year, month: initial.month))
    }

    var body: some View {
        let theme = ThemeColors.for(scheme)
        let today = Date.now
        let nowComps = Calendar.current.dateComponents([.year, .month], from: today)
        let atCurrentMonth = visible.year == nowComps.year && visible.month == nowComps.month

        VStack(spacing: 0) {
            HStack {
                navButton("chevron.left", disabled: false) { page(-1) }
                Spacer()
                Text(CalendarMath.monthTitle(year: visible.year, month: visible.month))
                    .font(.headline)
                    .foregroundStyle(theme.ink)
                Spacer()
                navButton("chevron.right", disabled: atCurrentMonth) { if !atCurrentMonth { page(1) } }
            }

            HStack {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.ink.opacity(0.45))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 12)

            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                HStack {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, date in
                        dayCell(date, today: today, theme: theme)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 6)
            }
        }
        .padding(16)
        .panel()
    }

    @ViewBuilder
    private func dayCell(_ date: Date?, today: Date, theme: ThemeColors) -> some View {
        if let date {
            let key = CalendarMath.dayKey(date)
            let marked = markedDays.contains(key)
            let isToday = key == CalendarMath.dayKey(today)
            // nil selection means "today" (matches HistoryScreen.visibleSessions).
            let selected = selectedDay == key || (selectedDay == nil && isToday)
            let future = date > today && !isToday
            let day = Calendar.current.component(.day, from: date)

            Button {
                selectedDay = selected ? nil : key
            } label: {
                VStack(spacing: 2) {
                    Text("\(day)")
                        .font(.subheadline.weight(marked ? .bold : .medium))
                        .foregroundStyle(marked ? theme.ink : (future ? theme.ink.opacity(0.4) : theme.ink.opacity(0.75)))
                        .frame(width: 36, height: 36)
                        .background {
                            if selected {
                                Circle().fill(primary.opacity(0.3))
                            }
                            if isToday {
                                Circle().strokeBorder(primary, lineWidth: 2)
                            }
                        }
                    Circle().fill(primary).frame(width: 5, height: 5).opacity(marked ? 1 : 0)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        } else {
            Color.clear.frame(height: 43).padding(.vertical, 4)
        }
    }

    private func navButton(_ icon: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        let theme = ThemeColors.for(scheme)
        return Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(disabled ? theme.inkFaint : theme.ink)
                .frame(width: 32, height: 32)
                .background(Circle().fill(theme.glassFill))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private func page(_ delta: Int) {
        visible = CalendarMath.addMonths(year: visible.year, month: visible.month, delta: delta)
        weeks = CalendarMath.monthMatrix(year: visible.year, month: visible.month)
    }
}
