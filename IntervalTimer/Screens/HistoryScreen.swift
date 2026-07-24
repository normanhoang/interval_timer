import SwiftUI
import SwiftData

struct HistoryScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Query(sort: \Session.completedAt, order: .reverse) private var sessions: [Session]
    @Query(sort: \Workout.order) private var workouts: [Workout]

    @State private var selectedDay: String?
    @State private var showClearConfirm = false
    @State private var showMonth = false
    @State private var detailSession: Session?

    /// dayKey → sessions that day, for the week strip's volume dots.
    private var sessionsByDay: [String: Int] {
        sessions.reduce(into: [:]) { counts, session in
            counts[CalendarMath.dayKey(session.completedAt), default: 0] += 1
        }
    }

    private var markedDays: Set<String> {
        Set(sessions.map { CalendarMath.dayKey($0.completedAt) })
    }

    private var visibleSessions: [Session] {
        let day = selectedDay ?? CalendarMath.dayKey(.now)
        return sessions.filter { CalendarMath.dayKey($0.completedAt) == day }
    }

    var body: some View {
        let theme = ThemeColors.for(scheme)
        let weekAgo = Date.now.addingTimeInterval(-7 * 24 * 60 * 60)
        let thisWeek = sessions.filter { $0.completedAt >= weekAgo }.count
        let streak = CalendarMath.streakLength(markedDays)

        NavigationStack {
            VStack(spacing: 0) {
                header(theme)
                List {
                    streakHero(streak: streak, theme: theme).plainRow()
                    statsRow(thisWeek: thisWeek, theme: theme).plainRow()
                    calendarCard(theme).plainRow()

                    if sessions.isEmpty {
                        emptyState(theme).plainRow()
                    } else if visibleSessions.isEmpty {
                        selectDayHint(theme).plainRow()
                    } else {
                        sessionSections(theme)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.defaultMinListRowHeight, 0)
                .contentMargins(.bottom, 72, for: .scrollContent)
            }
            .appBackground()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $detailSession) { session in
                SessionDetailScreen(session: session)
            }
        }
        .onAppear { selectedDay = nil }
        .confirmationDialog("Clear history?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Clear \(clearDayName)") { clearDay() }
            Button("Clear all", role: .destructive) { clearAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Remove sessions for one day, or everything.")
        }
    }

    private func header(_ theme: ThemeColors) -> some View {
        HStack(alignment: .center) {
            Text("History").font(.system(size: 34, weight: .bold)).foregroundStyle(theme.ink)
            Spacer()
            if !sessions.isEmpty {
                Button { showClearConfirm = true } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundStyle(theme.ink)
                        .frame(width: 44, height: 44)
                        .glassChrome(radius: 22)
                }
                .buttonStyle(.pressableScale)
            }
        }
        .padding(.horizontal, 20).padding(.bottom, 14)
    }

    /// Streak hero — the one number the habit tracker is about.
    private func streakHero(streak: Int, theme: ThemeColors) -> some View {
        let best = CalendarMath.bestStreak(markedDays)
        return HStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 30))
                .foregroundStyle(theme.flame)
            VStack(alignment: .leading, spacing: 3) {
                Text("\(streak)-day streak")
                    .font(.system(size: 24, weight: .bold)).foregroundStyle(theme.ink)
                Text("Best: \(best) \(best == 1 ? "day" : "days") · one workout keeps it alive")
                    .font(.system(size: 13)).foregroundStyle(theme.ink.opacity(0.55))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18).padding(.vertical, 18)
        .background(LinearGradient(colors: theme.streakTint, startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
            .strokeBorder(theme.streakBorder, lineWidth: 1))
    }

    private func statsRow(thisWeek: Int, theme: ThemeColors) -> some View {
        HStack(spacing: 10) {
            stat("\(thisWeek)", "this week", theme)
            stat("\(sessions.count)", "workouts", theme)
        }
    }

    private func stat(_ value: String, _ label: String, _ theme: ThemeColors) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 20, weight: .bold)).foregroundStyle(theme.ink)
            Text(label).font(.system(size: 12)).foregroundStyle(theme.inkMuted)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).card(radius: 20)
    }

    /// Week strip, expanding in place to the full month calendar.
    private func calendarCard(_ theme: ThemeColors) -> some View {
        VStack(spacing: 14) {
            WeekStrip(sessionsByDay: sessionsByDay, selectedDay: $selectedDay, showMonth: $showMonth)
            if showMonth {
                MonthCalendar(markedDays: markedDays, selectedDay: $selectedDay)
            }
        }
        .padding(16).card()
    }

    @ViewBuilder
    private func sessionSections(_ theme: ThemeColors) -> some View {
        ForEach(groupByDay(visibleSessions), id: \.label) { group in
            Section {
                ForEach(group.items) { session in
                    Button { detailSession = session } label: {
                        sessionRow(session, theme)
                    }
                    .buttonStyle(.plain)
                    .plainRow()
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { delete(session) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            } header: {
                Text(group.label.uppercased())
                    .font(.system(size: 13, weight: .semibold)).tracking(1)
                    .foregroundStyle(theme.inkMuted)
                    .textCase(nil)
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
            .listRowBackground(Color.clear)
        }
    }

    private func sessionRow(_ session: Session, _ theme: ThemeColors) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(spineColor(session))
                .frame(width: 4, height: 38)
            VStack(alignment: .leading, spacing: 3) {
                Text(session.workoutName)
                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(theme.ink)
                Text(detailLine(session))
                    .font(.system(size: 13)).foregroundStyle(theme.inkMuted)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Text(TimerEngineMath.formatSeconds(session.totalSeconds))
                .font(.system(size: 15, weight: .semibold)).monospacedDigit()
                .foregroundStyle(theme.ink)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.inkFaint)
        }
        .padding(.horizontal, 14).padding(.vertical, 14)
        .card(radius: 18)
    }

    /// `7:30 AM · 16/16 intervals · no pauses` — the suffixes only exist on
    /// sessions recorded from 1.7 on.
    private func detailLine(_ session: Session) -> String {
        var parts = [session.completedAt.formatted(date: .omitted, time: .shortened)]
        if let completed = session.completedIntervals, let total = session.totalIntervals {
            parts.append(completed < total ? "\(completed)/\(total) intervals · ended early"
                                           : "\(completed)/\(total) intervals")
        }
        if let pauses = session.pauseCount {
            parts.append(pauses == 0 ? "no pauses" : "\(pauses) \(pauses == 1 ? "pause" : "pauses")")
        }
        return parts.joined(separator: " · ")
    }

    /// The workout's first interval color; falls back to the accent once the
    /// workout itself has been deleted.
    private func spineColor(_ session: Session) -> Color {
        guard let workout = workouts.first(where: { $0.uuid == session.workoutId }),
              let first = workout.intervals.first else {
            return ThemeColors.for(scheme).accent
        }
        return Color(hex: first.color)
    }

    private func emptyState(_ theme: ThemeColors) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 24)).foregroundStyle(theme.inkMuted)
                .frame(width: 56, height: 56).background(Circle().fill(theme.glassFill))
            Text("Nothing logged yet").font(.body.weight(.medium)).foregroundStyle(theme.ink.opacity(0.6))
            Text("Finish a workout and it will show up here.")
                .font(.subheadline).foregroundStyle(theme.ink.opacity(0.4)).multilineTextAlignment(.center)
        }
        .padding(32).frame(maxWidth: .infinity).panel().padding(.top, 8)
    }

    private func selectDayHint(_ theme: ThemeColors) -> some View {
        Text("Tap a day to see its sessions")
            .font(.subheadline).foregroundStyle(theme.ink.opacity(0.4))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity).padding(.top, 24)
    }

    // MARK: helpers

    private var clearDayName: String {
        if let selectedDay { return prettyDay(selectedDay) }
        return "today"
    }

    // DateFormatter creation is expensive — build once and reuse (main-thread only).
    private static let dayKeyFormatter: DateFormatter = {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"; return fmt
    }()
    private static let monthDayFormatter: DateFormatter = {
        let fmt = DateFormatter(); fmt.dateFormat = "MMMM d"; return fmt
    }()
    private static let weekdayFormatter: DateFormatter = {
        let fmt = DateFormatter(); fmt.dateFormat = "EEEE, MMMM d"; return fmt
    }()

    private func prettyDay(_ key: String) -> String {
        guard let date = Self.dayKeyFormatter.date(from: key) else { return key }
        return Self.monthDayFormatter.string(from: date)
    }

    private func dayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        return Self.weekdayFormatter.string(from: date)
    }

    private func groupByDay(_ items: [Session]) -> [(label: String, items: [Session])] {
        var groups: [(label: String, items: [Session])] = []
        for session in items {
            let label = dayLabel(session.completedAt)
            if var last = groups.last, last.label == label {
                last.items.append(session)
                groups[groups.count - 1] = last
            } else {
                groups.append((label, [session]))
            }
        }
        return groups
    }

    private func delete(_ session: Session) {
        context.delete(session); try? context.save()
    }

    private func clearDay() {
        let day = selectedDay ?? CalendarMath.dayKey(.now)
        for s in sessions where CalendarMath.dayKey(s.completedAt) == day { context.delete(s) }
        try? context.save()
        selectedDay = nil
    }

    private func clearAll() {
        for s in sessions { context.delete(s) }
        try? context.save()
        selectedDay = nil
    }
}
