import SwiftUI
import UIKit

struct StudentScheduleView: View {
    let student: Student
    let onUnauthorized: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var slots: [ScheduleSlotInput] = []
    @State private var selectedDay = 1
    @State private var time = Date()
    @State private var loading = true
    @State private var saving = false
    @State private var justAdded = false
    @State private var toast: String?
    @State private var toastIsError = false

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    newLessonCard
                    scheduleListCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .background { AppCanvasBackground() }
            .navigationTitle("Расписание")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                addButtonBar
            }
            .overlay(alignment: .top) {
                if let toast {
                    ToastBanner(message: toast, isError: toastIsError)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: toast)
            .task { await load() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(student.fullName)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)
            Text(loading ? "Загрузка…" : scheduleSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    private var scheduleSubtitle: String {
        if slots.isEmpty { return "Занятий пока нет" }
        return Formatters.pluralLessons(slots.count) + " в неделю"
    }

    private var newLessonCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Новое занятие")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            AppSegmentCapsule(
                options: DayNames.weekOrder.map { (value: $0, title: DayNames.short[$0]) },
                selection: $selectedDay
            )

            HStack {
                Label("Время", systemImage: "clock")
                    .font(.body.weight(.medium))
                Spacer()
                DatePicker(
                    "",
                    selection: $time,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .tint(AppTheme.primary)
            }
        }
        .padding(16)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private var scheduleListCard: some View {
        scheduleListContent
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
            )
            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    @ViewBuilder
    private var scheduleListContent: some View {
        if loading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
        } else if sortedSlots.isEmpty {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.plus")
                    .foregroundStyle(AppTheme.primary.opacity(0.7))
                Text("Список пуст — добавьте занятие ниже")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        } else {
            VStack(spacing: 0) {
                Text("В расписании")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 6)

                ForEach(Array(sortedSlots.enumerated()), id: \.element) { index, slot in
                    if index > 0 {
                        Divider().padding(.leading, 16)
                    }
                    scheduleRow(slot)
                }
            }
        }
    }

    private var addButtonBar: some View {
        AppPrimaryButton(
            title: "Добавить в расписание",
            systemImage: "plus",
            isEnabled: !saving,
            isLoading: saving,
            isSuccess: justAdded,
            successTitle: "Добавлено"
        ) {
            Task { await addLesson() }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private func scheduleRow(_ slot: ScheduleSlotInput) -> some View {
        HStack(spacing: 12) {
            Text(DayNames.short[slot.dayOfWeek])
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 34, height: 34)
                .background(AppTheme.primary.opacity(0.12), in: Circle())

            Text(DayNames.full[slot.dayOfWeek])
                .font(.body.weight(.medium))

            Spacer(minLength: 0)

            Text(Formatters.formatTime(slot.timeSlot))
                .font(.body.monospacedDigit().weight(.semibold))
                .foregroundStyle(.secondary)

            Button(role: .destructive) {
                Task { await remove(slot) }
            } label: {
                Image(systemName: "trash")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.danger.opacity(0.8))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Удалить")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(DayNames.full[slot.dayOfWeek]), \(Formatters.formatTime(slot.timeSlot))")
    }

    private var sortedSlots: [ScheduleSlotInput] {
        slots.sorted {
            let a = $0.dayOfWeek == 0 ? 7 : $0.dayOfWeek
            let b = $1.dayOfWeek == 0 ? 7 : $1.dayOfWeek
            if a != b { return a < b }
            return Formatters.normalizeTime($0.timeSlot) < Formatters.normalizeTime($1.timeSlot)
        }
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            let remote = try await API.schedule(studentId: student.id)
            slots = remote.map {
                ScheduleSlotInput(
                    dayOfWeek: $0.dayOfWeek,
                    timeSlot: Formatters.normalizeTime($0.timeSlot)
                )
            }
        } catch is AuthError {
            onUnauthorized()
        } catch {
            slots = []
            showToast("Не удалось загрузить расписание", error: true)
        }
    }

    private func addLesson() async {
        let t = timeFormatter.string(from: time)
        let next = ScheduleSlotInput(dayOfWeek: selectedDay, timeSlot: Formatters.normalizeTime(t))
        if slots.contains(where: {
            $0.dayOfWeek == next.dayOfWeek && Formatters.normalizeTime($0.timeSlot) == next.timeSlot
        }) {
            showToast("Это время уже есть в расписании", error: true)
            return
        }
        let label = "\(DayNames.short[next.dayOfWeek]), \(Formatters.formatTime(next.timeSlot))"
        await persist(slots + [next], success: "Добавлено · \(label)")
    }

    private func remove(_ slot: ScheduleSlotInput) async {
        let next = slots.filter {
            !($0.dayOfWeek == slot.dayOfWeek
                && Formatters.normalizeTime($0.timeSlot) == Formatters.normalizeTime(slot.timeSlot))
        }
        let label = "\(DayNames.short[slot.dayOfWeek]), \(Formatters.formatTime(slot.timeSlot))"
        await persist(next, success: "Удалено · \(label)")
    }

    private func persist(_ next: [ScheduleSlotInput], success: String) async {
        saving = true
        defer { saving = false }
        do {
            try await API.replaceSchedule(studentId: student.id, slots: next)
            withAnimation(.snappy) { slots = next }
            showToast(success, error: false)
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            if success.hasPrefix("Добавлено") {
                justAdded = true
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(1400))
                    withAnimation(.easeOut(duration: 0.2)) { justAdded = false }
                }
            }
        } catch is AuthError {
            onUnauthorized()
        } catch {
            showToast((error as? LocalizedError)?.errorDescription ?? "Ошибка", error: true)
        }
    }

    private func showToast(_ message: String, error: Bool) {
        toastIsError = error
        toast = message
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1800))
            if toast == message { toast = nil }
        }
    }
}
