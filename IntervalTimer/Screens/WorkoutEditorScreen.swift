import SwiftUI
import SwiftData

struct WorkoutEditorScreen: View {
    let target: EditorTarget

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Query(sort: \Workout.order) private var allWorkouts: [Workout]

    @State private var name: String
    @State private var repeats: Int
    @State private var intervals: [Interval]
    @State private var warmupSeconds: Int
    @State private var cooldownSeconds: Int
    @State private var durationEditing: Interval.ID?
    @State private var colorEditing: Interval.ID?
    @State private var extraEditing: ExtraSegment?
    @State private var showDeleteConfirm = false
    @State private var editMode: EditMode = .inactive

    private var existing: Workout? {
        if case .edit(let w) = target { return w }
        return nil
    }
    private var isNew: Bool { existing == nil }

    init(target: EditorTarget) {
        self.target = target
        switch target {
        case .edit(let w):
            _name = State(initialValue: w.name)
            _repeats = State(initialValue: w.repeats)
            _intervals = State(initialValue: w.intervals)
            _warmupSeconds = State(initialValue: w.warmupSeconds)
            _cooldownSeconds = State(initialValue: w.cooldownSeconds)
        case .new:
            _name = State(initialValue: "")
            _repeats = State(initialValue: 4)
            _intervals = State(initialValue: [
                Interval(label: "Work", seconds: 30, color: Palette.work),
                Interval(label: "Rest", seconds: 15, color: Palette.rest),
            ])
            _warmupSeconds = State(initialValue: 0)
            _cooldownSeconds = State(initialValue: 0)
        }
    }

    var body: some View {
        let theme = ThemeColors.for(scheme)
        VStack(spacing: 0) {
            header(theme)
            List {
                nameRow(theme)
                roundsRow(theme)
                extraRow(.warmup, seconds: $warmupSeconds, theme: theme)
                intervalsHeader(theme)
                ForEach($intervals) { $interval in
                    intervalRow($interval, theme: theme)
                }
                .onMove { intervals.move(fromOffsets: $0, toOffset: $1) }
                addButton(theme)
                extraRow(.cooldown, seconds: $cooldownSeconds, theme: theme)
                footer(theme)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 0)
            .environment(\.editMode, $editMode)
        }
        .appBackground()
        .sheet(item: durationBinding) { interval in
            durationSheet(interval, theme: theme)
        }
        .sheet(item: colorBinding) { interval in
            colorSheet(interval, theme: theme)
        }
        .sheet(item: $extraEditing) { segment in
            extraDurationSheet(segment, theme: theme)
        }
        .confirmationDialog("Delete workout?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteWorkout() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("“\(existing?.name ?? "")” will be removed.")
        }
    }

    // MARK: header

    private func header(_ theme: ThemeColors) -> some View {
        ZStack {
            Text(isNew ? "New Workout" : "Edit Workout")
                .font(.headline).foregroundStyle(theme.ink)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 18))
                        .foregroundStyle(theme.ink).frame(width: 40, height: 40).glassChrome(radius: 20)
                }
                Spacer()
                Button { save() } label: {
                    Text("Save").fontWeight(.semibold).foregroundStyle(theme.ink)
                        .padding(.horizontal, 16).padding(.vertical, 9).glassChrome(radius: 20)
                }
            }
            .buttonStyle(.pressableScale)
        }
        .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 8)
    }

    // MARK: rows

    private func intervalsHeader(_ theme: ThemeColors) -> some View {
        let editing = editMode == .active
        return HStack {
            Text(editing ? "DRAG ☰ TO REORDER" : "INTERVALS")
                .font(.caption.weight(.semibold)).tracking(1.5)
                .foregroundStyle(theme.ink.opacity(0.4))
            Spacer()
            if intervals.count > 1 {
                Button {
                    withAnimation { editMode = editing ? .inactive : .active }
                } label: {
                    Text(editing ? "Done" : "Reorder")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: Palette.primary))
                }
                .buttonStyle(.plain)
            }
        }
        .plainRow()
    }

    private func nameRow(_ theme: ThemeColors) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NAME").font(.caption.weight(.semibold)).tracking(1.5)
                .foregroundStyle(theme.ink.opacity(0.4))
            TextField("e.g. Morning HIIT", text: $name)
                .font(.title3.weight(.semibold)).foregroundStyle(theme.ink)
        }
        .padding(16).panel().plainRow()
    }

    private func roundsRow(_ theme: ThemeColors) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ROUNDS").font(.caption.weight(.semibold)).tracking(1.5)
                    .foregroundStyle(theme.ink.opacity(0.4))
                Text("Repeat the sequence").font(.subheadline).foregroundStyle(theme.ink.opacity(0.5))
            }
            Spacer()
            HStack(spacing: 12) {
                stepper("minus", theme) { repeats = max(1, repeats - 1) }
                Text("\(repeats)").font(.title3.weight(.bold)).monospacedDigit()
                    .foregroundStyle(theme.ink).frame(width: 32)
                stepper("plus", theme) { repeats = min(99, repeats + 1) }
            }
        }
        .padding(16).panel().plainRow()
    }

    private func intervalRow(_ interval: Binding<Interval>, theme: ThemeColors) -> some View {
        HStack(spacing: 10) {
            Button { colorEditing = interval.wrappedValue.id } label: {
                Circle().fill(Color(hex: interval.wrappedValue.color))
                    .frame(width: 28, height: 28)
                    .overlay(Circle().strokeBorder(.white.opacity(0.8), lineWidth: 2))
            }
            .buttonStyle(.plain)
            TextField("Label", text: interval.label)
                .font(.body.weight(.semibold)).foregroundStyle(theme.ink)
            Spacer()
            Button { durationEditing = interval.wrappedValue.id } label: {
                Text(TimerEngineMath.formatSeconds(interval.wrappedValue.seconds))
                    .font(.subheadline.weight(.semibold)).monospacedDigit()
                    .foregroundStyle(theme.ink)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill(theme.glassFill))
                    .overlay(Capsule().strokeBorder(theme.glassBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .panel(radius: 24)
        .plainRow()
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { removeInterval(interval.wrappedValue.id) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func extraRow(_ segment: ExtraSegment, seconds: Binding<Int>, theme: ThemeColors) -> some View {
        let enabled = Binding(
            get: { seconds.wrappedValue > 0 },
            set: { seconds.wrappedValue = $0 ? ExtraSegment.defaultSeconds : 0 }
        )
        return HStack(spacing: 10) {
            Circle().fill(Color(hex: segment.color))
                .frame(width: 28, height: 28)
                .overlay(Circle().strokeBorder(.white.opacity(0.8), lineWidth: 2))
                .opacity(enabled.wrappedValue ? 1 : 0.35)
            Text(segment.label)
                .font(.body.weight(.semibold))
                .foregroundStyle(enabled.wrappedValue ? theme.ink : theme.ink.opacity(0.4))
            Spacer()
            if enabled.wrappedValue {
                Button { extraEditing = segment } label: {
                    Text(TimerEngineMath.formatSeconds(seconds.wrappedValue))
                        .font(.subheadline.weight(.semibold)).monospacedDigit()
                        .foregroundStyle(theme.ink)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(theme.glassFill))
                        .overlay(Capsule().strokeBorder(theme.glassBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            Toggle("", isOn: enabled)
                .labelsHidden()
                .tint(Color(hex: Palette.primary))
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .panel(radius: 24)
        .plainRow()
    }

    private func addButton(_ theme: ThemeColors) -> some View {
        Button(action: addInterval) {
            Text("+ Add interval").font(.body.weight(.semibold))
                .foregroundStyle(theme.ink.opacity(0.5))
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(theme.ink.opacity(0.15), style: StrokeStyle(lineWidth: 2, dash: [6])))
        }
        .buttonStyle(.plain)
        .plainRow()
    }

    private func footer(_ theme: ThemeColors) -> some View {
        let total = TimerEngineMath.totalDuration(
            intervals: intervals, repeats: repeats,
            warmupSeconds: warmupSeconds, cooldownSeconds: cooldownSeconds)
        return VStack(spacing: 8) {
            IntervalMixBar(intervals: intervals, height: 8)
            Text("Total: \(TimerEngineMath.formatSeconds(total)) · \(repeats) \(repeats == 1 ? "round" : "rounds")")
                .font(.subheadline.weight(.medium)).foregroundStyle(theme.ink.opacity(0.5))
            if existing != nil {
                Button(role: .destructive) { showDeleteConfirm = true } label: {
                    Text("Delete workout").font(.subheadline.weight(.semibold))
                        .foregroundStyle(.pink)
                }
                .buttonStyle(.plain).padding(.top, 8)
            }
        }
        .padding(.top, 8)
        .plainRow()
    }

    private func stepper(_ icon: String, _ theme: ThemeColors, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 15, weight: .semibold))
                .foregroundStyle(theme.ink).frame(width: 36, height: 36)
                .background(Circle().fill(theme.glassFill))
                .overlay(Circle().strokeBorder(theme.glassBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: sheets

    private var durationBinding: Binding<Interval?> {
        Binding(get: { intervals.first { $0.id == durationEditing } },
                set: { _ in })
    }
    private var colorBinding: Binding<Interval?> {
        Binding(get: { intervals.first { $0.id == colorEditing } },
                set: { _ in })
    }

    private func durationSheet(_ interval: Interval, theme: ThemeColors) -> some View {
        let idx = intervals.firstIndex { $0.id == interval.id } ?? 0
        return VStack(spacing: 8) {
            Text(intervals[idx].label.isEmpty ? "Duration" : intervals[idx].label)
                .font(.headline).foregroundStyle(theme.ink).padding(.top, 16)
            DurationWheel(seconds: Binding(
                get: { intervals[idx].seconds },
                set: { intervals[idx].seconds = $0 }
            ))
        }
        .appBackground()
        .presentationDetents([.height(280)])
        .onDisappear {
            if intervals[idx].seconds == 0 { intervals[idx].seconds = 1 }
            durationEditing = nil
        }
    }

    private func extraDurationSheet(_ segment: ExtraSegment, theme: ThemeColors) -> some View {
        let seconds = segment == .warmup ? $warmupSeconds : $cooldownSeconds
        return VStack(spacing: 8) {
            Text(segment.label)
                .font(.headline).foregroundStyle(theme.ink).padding(.top, 16)
            DurationWheel(seconds: seconds)
        }
        .appBackground()
        .presentationDetents([.height(280)])
        .onDisappear {
            // Dialing to 0 means "off" — the toggle reflects it.
            extraEditing = nil
        }
    }

    private func colorSheet(_ interval: Interval, theme: ThemeColors) -> some View {
        let idx = intervals.firstIndex { $0.id == interval.id } ?? 0
        return VStack(spacing: 16) {
            Text("\(intervals[idx].label.isEmpty ? "Interval" : intervals[idx].label) color")
                .font(.headline).foregroundStyle(theme.ink).padding(.top, 16)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(48), spacing: 10), count: 6), spacing: 10) {
                ForEach(Palette.intervalColors, id: \.self) { color in
                    let active = intervals[idx].color == color
                    Button {
                        intervals[idx].color = color
                        colorEditing = nil
                    } label: {
                        Circle().fill(Color(hex: color)).frame(width: 48, height: 48)
                            .overlay(Circle().strokeBorder(active ? Color(hex: Palette.primary) : .white.opacity(0.8),
                                                           lineWidth: active ? 3 : 2))
                            .overlay {
                                if active {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Palette.isLight(color) ? Color(hex: Palette.ink) : .white)
                                }
                            }
                    }
                    .buttonStyle(.pressableScale)
                }
            }
            .padding(.bottom, 24)
        }
        .appBackground()
        .presentationDetents([.height(240)])
        .onDisappear { colorEditing = nil }
    }

    // MARK: actions

    private func addInterval() {
        let work = intervals.count % 2 == 0
        intervals.append(Interval(label: work ? "Work" : "Rest",
                                  seconds: work ? 30 : 15,
                                  color: work ? Palette.work : Palette.rest))
    }

    private func removeInterval(_ id: Interval.ID) {
        intervals.removeAll { $0.id == id }
    }

    private func save() {
        guard !intervals.isEmpty else { dismiss(); return }
        let finalName = name.trimmingCharacters(in: .whitespaces).isEmpty ? "Workout" : name.trimmingCharacters(in: .whitespaces)
        if let existing {
            existing.name = finalName
            existing.intervals = intervals
            existing.repeats = repeats
            existing.warmupSeconds = warmupSeconds
            existing.cooldownSeconds = cooldownSeconds
        } else {
            let order = (allWorkouts.map(\.order).max() ?? -1) + 1
            context.insert(Workout(name: finalName, intervals: intervals, repeats: repeats,
                                   warmupSeconds: warmupSeconds, cooldownSeconds: cooldownSeconds,
                                   order: order))
        }
        try? context.save()
        dismiss()
    }

    private func deleteWorkout() {
        if let existing { context.delete(existing); try? context.save() }
        dismiss()
    }
}

/// The once-only segments editable outside the repeated interval list.
enum ExtraSegment: String, Identifiable {
    case warmup, cooldown

    static let defaultSeconds = 60

    var id: String { rawValue }
    var label: String { self == .warmup ? "Warm up" : "Cool down" }
    var color: String { self == .warmup ? Palette.warmup : Palette.cooldown }
}

extension View {
    /// List row with no background, no separator, edge-to-edge horizontal insets.
    func plainRow() -> some View {
        self.listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
    }
}
