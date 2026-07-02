import SwiftUI
import SwiftData

struct HistoryScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Query(sort: \Session.completedAt, order: .reverse) private var sessions: [Session]

    @State private var selectedDay: String?
    @State private var showClearConfirm = false

    private var markedDays: Set<String> {
        Set(sessions.map { CalendarMath.dayKey($0.completedAt) })
    }

    private var visibleSessions: [Session] {
        guard let selectedDay else { return sessions }
        return sessions.filter { CalendarMath.dayKey($0.completedAt) == selectedDay }
    }

    var body: some View {
        let theme = ThemeColors.for(scheme)
        let total = sessions.reduce(0) { $0 + $1.totalSeconds }
        let weekAgo = Date.now.addingTimeInterval(-7 * 24 * 60 * 60)
        let thisWeek = sessions.filter { $0.completedAt >= weekAgo }.count
        let streak = CalendarMath.streakLength(markedDays)

        NavigationStack {
            VStack(spacing: 0) {
                header(theme)
                List {
                    statsGrid(streak: streak, thisWeek: thisWeek, total: total, theme: theme).plainRow()
                    MonthCalendar(markedDays: markedDays, selectedDay: $selectedDay).plainRow()
                    if let selectedDay { showAllPill(selectedDay, theme).plainRow() }

                    if sessions.isEmpty {
                        emptyState(theme).plainRow()
                    } else {
                        sessionSections(theme)
                        clearButton(theme).plainRow()
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.defaultMinListRowHeight, 0)
                .contentMargins(.bottom, 72, for: .scrollContent)
            }
            .appBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
        .confirmationDialog("Clear history?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Clear \(clearDayName)") { clearDay() }
            Button("Clear all", role: .destructive) { clearAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Remove sessions for one day, or everything.")
        }
    }

    private func header(_ theme: ThemeColors) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("INTERVAL PULSE TIMER").font(.caption.weight(.semibold)).tracking(2)
                .foregroundStyle(theme.ink.opacity(0.4))
            Text("History").font(.system(size: 34, weight: .bold)).foregroundStyle(theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24).padding(.bottom, 12)
    }

    private func statsGrid(streak: Int, thisWeek: Int, total: Int, theme: ThemeColors) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                stat("\(streak)", "Day streak", "flame", theme)
                stat("\(thisWeek)", "This week", "calendar", theme)
            }
            HStack(spacing: 12) {
                stat("\(sessions.count)", "Workouts", "dumbbell", theme)
                stat(TimerEngineMath.formatSeconds(total), "Total time", "clock", theme)
            }
        }
    }

    private func stat(_ value: String, _ label: String, _ icon: String, _ theme: ThemeColors) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top) {
                Text(value).font(.title2.weight(.bold)).foregroundStyle(theme.ink)
                Spacer()
                Image(systemName: icon).font(.system(size: 14)).foregroundStyle(theme.inkMuted)
            }
            Text(label).font(.caption.weight(.medium)).foregroundStyle(theme.ink.opacity(0.5))
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).panel()
    }

    private func showAllPill(_ day: String, _ theme: ThemeColors) -> some View {
        Button { selectedDay = nil } label: {
            HStack(spacing: 6) {
                Text("Showing \(prettyDay(day)) · Show all")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(theme.ink.opacity(0.7))
                Image(systemName: "xmark.circle.fill").foregroundStyle(theme.inkMuted)
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Capsule().fill(theme.glassFill))
            .overlay(Capsule().strokeBorder(theme.glassBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func sessionSections(_ theme: ThemeColors) -> some View {
        ForEach(groupByDay(visibleSessions), id: \.label) { group in
            Section {
                ForEach(group.items) { session in
                    sessionRow(session, theme)
                        .plainRow()
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { delete(session) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            } header: {
                Text(group.label).font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.ink.opacity(0.5))
                    .textCase(nil)
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 24, bottom: 4, trailing: 24))
            .listRowBackground(Color.clear)
        }
    }

    private func sessionRow(_ session: Session, _ theme: ThemeColors) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.workoutName).font(.body.weight(.semibold)).foregroundStyle(theme.ink)
                Text(session.completedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption).foregroundStyle(theme.ink.opacity(0.4))
            }
            Spacer()
            Text(TimerEngineMath.formatSeconds(session.totalSeconds))
                .font(.body.weight(.semibold)).monospacedDigit()
                .foregroundStyle(theme.ink.opacity(0.6))
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .panel(radius: 16)
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

    private func clearButton(_ theme: ThemeColors) -> some View {
        Button { showClearConfirm = true } label: {
            Text("Clear history").font(.subheadline.weight(.semibold)).foregroundStyle(.pink)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain).padding(.top, 16)
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
