import SwiftUI
import UIKit

/// Journal tab — same scroll chrome as Students: List + large title, controls scroll away.
struct JournalView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(StudentsViewModel.self) private var studentsVM

    @State private var section: JournalSection = .today

    // Today
    @State private var day: Int?
    @State private var isToday = true
    @State private var slots: [ScheduleSlot] = []
    @State private var loadingToday = false
    @State private var handled: [Int: SlotOutcome] = [:]
    @State private var missedConfirmSlot: ScheduleSlot?

    // Week
    @State private var weekDays: [(day: Int, slots: [ScheduleSlot])] = []
    @State private var loadingWeek = false
    @State private var weekError = false
    @State private var expandedDay: Int?

    private enum JournalSection: Hashable {
        case today, week
    }

    private enum SlotOutcome: String {
        case completed, missed
    }

    /// Persists today's marked outcomes so they survive app relaunch — scoped to
    /// the calendar date, since `ScheduleSlot.id` is stable across weeks.
    private static let handledStorageKey = "journal.handledOutcomes.v1"

    private var todayDateKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f.string(from: .now)
    }

    var body: some View {
        NavigationStack {
            Group {
                if showInitialSpinner {
                    ProgressView("Загрузка…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    journalList
                }
            }
            .background { AppCanvasBackground() }
            .navigationTitle("Журнал")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { await refresh() }
            .task {
                loadHandledFromStorage()
                await loadToday(isRefresh: false)
            }
            .task(id: section) {
                guard section == .week else { return }
                await loadWeek()
            }
            .alert(
                "Отметить пропуск?",
                isPresented: Binding(
                    get: { missedConfirmSlot != nil },
                    set: { if !$0 { missedConfirmSlot = nil } }
                )
            ) {
                Button("Пропуск") {
                    if let slot = missedConfirmSlot {
                        Task { await markMissed(slot) }
                    }
                }
                Button("Отмена", role: .cancel) {
                    missedConfirmSlot = nil
                }
            } message: {
                if let slot = missedConfirmSlot {
                    Text(studentName(slot.studentId))
                }
            }
        }
    }

    private var showInitialSpinner: Bool {
        switch section {
        case .today: return loadingToday && slots.isEmpty
        case .week: return loadingWeek && weekDays.isEmpty
        }
    }

    private var journalList: some View {
        List {
            Section {
                AppSegmentCapsule(
                    options: [
                        (value: JournalSection.today, title: "Сегодня"),
                        (value: JournalSection.week, title: "Неделя"),
                    ],
                    selection: $section
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            switch section {
            case .today:
                todaySections
            case .week:
                weekSections
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background { AppCanvasBackground() }
    }

    // MARK: - Today sections

    @ViewBuilder
    private var todaySections: some View {
        if slots.isEmpty {
            Section {
                ContentUnavailableView(
                    "Свободный день",
                    systemImage: "sun.max",
                    description: Text("На ближайшие дни занятий нет.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        } else {
            if let day, !isToday {
                Section {
                    Text("Ближайший день: \(DayNames.full[day])")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }

            Section {
                ForEach(Array(slots.enumerated()), id: \.element.stableKey) { index, slot in
                    agendaCard(slot, index: index)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
        }
    }

    // MARK: - Week sections

    @ViewBuilder
    private var weekSections: some View {
        if weekError && weekDays.isEmpty {
            Section {
                ContentUnavailableView("Не удалось загрузить", systemImage: "wifi.slash")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        } else if !weekDays.contains(where: { !$0.slots.isEmpty }) {
            Section {
                ContentUnavailableView(
                    "Пока пусто",
                    systemImage: "book.closed",
                    description: Text("Занятия задаются в карточке ученика → Расписание.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        } else {
            Section {
                ForEach(DayNames.weekOrder, id: \.self) { day in
                    weekDayCard(day)
                        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
        }
    }

    // MARK: - Cards

    private func agendaCard(_ slot: ScheduleSlot, index: Int) -> some View {
        let student = studentsVM.students.first(where: { $0.id == slot.studentId })
        let minutes = timeToMinutes(slot.timeSlot)
        let now = Calendar.current.component(.hour, from: .now) * 60
            + Calendar.current.component(.minute, from: .now)
        let next = isNext(slot, index: index)
        let isPast = minutes < now && isToday
        let outcome = handled[slot.id]
        let timeColor: Color = {
            if outcome != nil || isPast { return .secondary }
            return AppTheme.primary
        }()

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(Formatters.formatTime(slot.timeSlot))
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(timeColor)
                    .lineLimit(1)
                    .layoutPriority(1)

                if next, outcome == nil {
                    Text("Сейчас")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.primary.opacity(0.12), in: Capsule())
                        .overlay {
                            Capsule()
                                .strokeBorder(AppTheme.primary.opacity(0.22), lineWidth: 1)
                        }
                        .fixedSize()
                }

                Spacer(minLength: 8)

                statusLabel(outcome: outcome, isPast: isPast)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(student?.fullName ?? "#\(slot.studentId)")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let student {
                    Text(remainingLabel(student.remainingLessons))
                        .font(.subheadline)
                        .foregroundStyle(
                            student.remainingLessons <= 0
                                ? AppTheme.danger
                                : (student.remainingLessons == 1 ? AppTheme.warning : .secondary)
                        )
                        .lineLimit(1)
                }
            }

            if outcome == nil, let student {
                VStack(spacing: 10) {
                    HoldToAction(
                        title: "Провести урок",
                        holdDuration: 1.0,
                        isEnabled: student.remainingLessons > 0
                    ) {
                        LessonLiveActivity.start(studentName: student.fullName)
                        Task { await markCompleted(slot) }
                    }

                    AppSecondaryButton(
                        title: "Отметить пропуск",
                        systemImage: "person.slash"
                    ) {
                        missedConfirmSlot = slot
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(.systemBackground),
            in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
        )
        .overlay {
            if next, outcome == nil {
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .strokeBorder(AppTheme.primary.opacity(0.28), lineWidth: 1.5)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func weekDayCard(_ day: Int) -> some View {
        let slots = (weekDays.first(where: { $0.day == day })?.slots ?? [])
            .sorted {
                Formatters.normalizeTime($0.timeSlot) < Formatters.normalizeTime($1.timeSlot)
            }
        let isExpanded = expandedDay == day
        let isCalendarToday = day == Calendar.current.component(.weekday, from: .now) - 1
        let hasSlots = !slots.isEmpty

        return VStack(spacing: 0) {
            Button {
                expandedDay = isExpanded ? nil : day
                UISelectionFeedbackGenerator().selectionChanged()
            } label: {
                HStack(spacing: 10) {
                    Text(DayNames.full[day])
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if isCalendarToday {
                        Text("Сегодня")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AppTheme.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.primary.opacity(0.12), in: Capsule())
                            .fixedSize()
                    }

                    Spacer(minLength: 0)

                    if hasSlots {
                        Text("\(slots.count)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.primary.opacity(0.12), in: Capsule())
                            .fixedSize()
                    }

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().padding(.leading, 16)
                if slots.isEmpty {
                    Text("Нет занятий")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                } else {
                    ForEach(Array(slots.enumerated()), id: \.element.stableKey) { index, slot in
                        if index > 0 {
                            Divider().padding(.leading, 16)
                        }
                        HStack(spacing: 12) {
                            Text(Formatters.formatTime(slot.timeSlot))
                                .font(.subheadline.monospacedDigit().weight(.semibold))
                                .foregroundStyle(AppTheme.primary)
                                .frame(width: 52, alignment: .leading)
                            Text(studentName(slot.studentId))
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
        }
        .background(
            Color(.systemBackground),
            in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
        )
    }

    @ViewBuilder
    private func statusLabel(outcome: SlotOutcome?, isPast: Bool) -> some View {
        ZStack(alignment: .trailing) {
            Text("Проведён")
                .opacity(outcome == .completed ? 1 : 0)
                .foregroundStyle(AppTheme.success)
            Text("Пропуск")
                .opacity(outcome == .missed ? 1 : 0)
                .foregroundStyle(.secondary)
            Text("Прошло")
                .opacity(outcome == nil && isPast ? 1 : 0)
                .foregroundStyle(.tertiary)
        }
        .font(.caption.weight(.semibold))
        .lineLimit(1)
        .fixedSize()
        .animation(nil, value: outcome == nil)
    }

    // MARK: - Logic

    private func isNext(_ slot: ScheduleSlot, index: Int) -> Bool {
        guard isToday else { return false }
        let now = Calendar.current.component(.hour, from: .now) * 60
            + Calendar.current.component(.minute, from: .now)
        return index == slots.firstIndex(where: { timeToMinutes($0.timeSlot) >= now })
            && handled[slot.id] == nil
    }

    private func remainingLabel(_ n: Int) -> String {
        if n <= 0 { return "Уроки закончились" }
        let mod10 = n % 10
        let mod100 = n % 100
        if mod10 == 1 && mod100 != 11 { return "Остался \(n) урок" }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) {
            return "Осталось \(n) урока"
        }
        return "Осталось \(n) уроков"
    }

    private func studentName(_ id: Int) -> String {
        studentsVM.students.first(where: { $0.id == id })?.fullName ?? "#\(id)"
    }

    private func markCompleted(_ slot: ScheduleSlot) async {
        let ok = await studentsVM.complete(slot.studentId, onUnauthorized: auth.handleUnauthorized)
        guard ok else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            handled[slot.id] = .completed
        }
        persistHandled(slot.id, outcome: .completed)
    }

    private func markMissed(_ slot: ScheduleSlot) async {
        let ok = await studentsVM.missed(slot.studentId, onUnauthorized: auth.handleUnauthorized)
        missedConfirmSlot = nil
        guard ok else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            handled[slot.id] = .missed
        }
        persistHandled(slot.id, outcome: .missed)
    }

    /// Loads today's persisted outcomes into `handled` — call before/alongside `loadToday`.
    private func loadHandledFromStorage() {
        guard
            let stored = UserDefaults.standard.dictionary(forKey: Self.handledStorageKey) as? [String: [String: String]],
            let todayDict = stored[todayDateKey]
        else { return }
        var result: [Int: SlotOutcome] = [:]
        for (key, value) in todayDict {
            if let slotId = Int(key), let outcome = SlotOutcome(rawValue: value) {
                result[slotId] = outcome
            }
        }
        handled = result
    }

    /// Saves one outcome for today's date, pruning any stale (older-day) entries.
    private func persistHandled(_ slotId: Int, outcome: SlotOutcome) {
        let stored = UserDefaults.standard.dictionary(forKey: Self.handledStorageKey) as? [String: [String: String]] ?? [:]
        var todayDict = stored[todayDateKey] ?? [:]
        todayDict[String(slotId)] = outcome.rawValue
        UserDefaults.standard.set([todayDateKey: todayDict], forKey: Self.handledStorageKey)
    }

    private func timeToMinutes(_ slot: String) -> Int {
        let parts = Formatters.normalizeTime(slot).split(separator: ":").compactMap { Int($0) }
        return (parts.first ?? 0) * 60 + (parts.dropFirst().first ?? 0)
    }

    private func refresh() async {
        switch section {
        case .today: await loadToday(isRefresh: true)
        case .week: await loadWeek()
        }
    }

    private func loadToday(isRefresh: Bool) async {
        let showSpinner = !isRefresh && slots.isEmpty
        if showSpinner { loadingToday = true }
        defer { loadingToday = false }
        let today = Calendar.current.component(.weekday, from: .now) - 1
        do {
            for offset in 0..<7 {
                let d = (today + offset) % 7
                let list = try await API.schedule(day: d).sorted {
                    Formatters.normalizeTime($0.timeSlot) < Formatters.normalizeTime($1.timeSlot)
                }
                if !list.isEmpty {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        day = d
                        isToday = offset == 0
                        slots = list
                    }
                    return
                }
            }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { slots = [] }
        } catch is AuthError {
            auth.handleUnauthorized()
        } catch {
            if !isRefresh { slots = [] }
        }
    }

    private func loadWeek() async {
        let showSpinner = weekDays.isEmpty
        if showSpinner { loadingWeek = true }
        weekError = false
        defer { loadingWeek = false }
        do {
            var result: [(day: Int, slots: [ScheduleSlot])] = []
            for day in 0..<7 {
                let slots = try await API.schedule(day: day)
                result.append((day, slots))
            }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                weekDays = result
                if expandedDay == nil {
                    let today = Calendar.current.component(.weekday, from: .now) - 1
                    if result.contains(where: { $0.day == today && !$0.slots.isEmpty }) {
                        expandedDay = today
                    } else {
                        expandedDay = DayNames.weekOrder.first { day in
                            result.first(where: { $0.day == day })?.slots.isEmpty == false
                        }
                    }
                }
            }
        } catch is AuthError {
            auth.handleUnauthorized()
        } catch {
            weekError = true
        }
    }
}
