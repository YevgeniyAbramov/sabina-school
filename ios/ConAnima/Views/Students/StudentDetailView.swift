import SwiftUI

/// Detail — list content + sticky bottom CTAs (no duplicate menu actions).
struct StudentDetailView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: StudentsViewModel

    let studentId: Int

    @State private var showDeleteConfirm = false
    @State private var showMissedConfirm = false
    @State private var showRenew = false
    @State private var showSchedule = false
    @State private var editPayload: Student?

    private var student: Student? {
        vm.students.first { $0.id == studentId }
    }

    var body: some View {
        Group {
            if let student {
                detailBody(student)
            } else {
                ContentUnavailableView("Ученик не найден", systemImage: "person.slash")
            }
        }
        .background { AppCanvasBackground() }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Удалить", systemImage: "trash", role: .destructive) {
                    showDeleteConfirm = true
                }
                .accessibilityLabel("Удалить ученика")
            }
        }
        .sheet(item: $editPayload) { payload in
            StudentFormSheet(mode: .edit(payload)) { input in
                try await vm.update(payload.id, input, onUnauthorized: auth.handleUnauthorized)
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showRenew) {
            if let student {
                RenewLessonsSheet(student: student) { lessons, payment in
                    try await vm.renew(student, lessons: lessons, payment: payment, onUnauthorized: auth.handleUnauthorized)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showSchedule) {
            if let student {
                StudentScheduleView(student: student, onUnauthorized: auth.handleUnauthorized)
                    .presentationDragIndicator(.visible)
            }
        }
        .alert("Отметить пропуск?", isPresented: $showMissedConfirm) {
            Button("Пропуск") {
                Task { await vm.missed(studentId, onUnauthorized: auth.handleUnauthorized) }
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            if let student { Text(student.fullName) }
        }
        .alert("Удалить ученика?", isPresented: $showDeleteConfirm) {
            Button("Удалить", role: .destructive) {
                Task {
                    await vm.delete(studentId, onUnauthorized: auth.handleUnauthorized)
                    dismiss()
                }
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            if let student { Text(student.fullName) }
        }
    }

    private func detailBody(_ student: Student) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header(student)
                metricsStrip(student)
                progressBlock(student)
                secondaryActions
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .navigationTitle(student.lastName.isEmpty ? student.firstName : student.lastName)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar(student)
        }
    }

    private func header(_ student: Student) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.primary.opacity(0.14))
                    .frame(width: 64, height: 64)
                Text(initials(student))
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(student.fullName)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                HStack(spacing: 6) {
                    StatusCapsule(
                        text: student.isPaid ? Copy.paid : Copy.unpaid,
                        tint: student.isPaid ? AppTheme.success : AppTheme.danger
                    )
                    if student.remainingLessons == 1 {
                        StatusCapsule(text: Copy.endingSoon, tint: AppTheme.warning)
                    } else if student.remainingLessons <= 0 {
                        StatusCapsule(text: Copy.finished, tint: .secondary)
                    }
                    if student.missedClasses > 0 {
                        StatusCapsule(text: "Пропусков: \(student.missedClasses)", tint: .secondary)
                    }
                }
            }
        }
    }

    private func metricsStrip(_ student: Student) -> some View {
        HStack(spacing: 8) {
            metricCell(
                label: "Осталось",
                value: "\(student.remainingLessons)",
                valueColor: remainingColor(student),
                fill: remainingFill(student)
            )
            metricCell(
                label: "Пройдено",
                value: "\(student.completedLessons) из \(student.totalLessons)",
                valueColor: .primary,
                fill: Color(.secondarySystemGroupedBackground)
            )
            metricCell(
                label: "Сумма",
                value: "\(Formatters.formatNumber(student.paidAmount)) ₸",
                valueColor: .primary,
                fill: Color(.secondarySystemGroupedBackground)
            )
        }
    }

    private func metricCell(label: String, value: String, valueColor: Color, fill: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func progressBlock(_ student: Student) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Прогресс")
                    .font(.headline)
                Spacer()
                Text("\(Int(student.progress * 100))%")
                    .font(.subheadline.monospacedDigit().weight(.medium))
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: student.progress)
                .tint(AppTheme.primary)
        }
        .padding(14)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private var secondaryActions: some View {
        VStack(spacing: 8) {
            detailLink(title: "Расписание", systemImage: "calendar") {
                showSchedule = true
            }
            detailLink(title: "Продлить", systemImage: "arrow.clockwise") {
                showRenew = true
            }
            detailLink(title: "Изменить данные", systemImage: "pencil") {
                Task { await openEdit() }
            }
        }
    }

    private func bottomBar(_ student: Student) -> some View {
        VStack(spacing: 10) {
            HoldToAction(
                title: "Провести урок",
                holdDuration: 1.0,
                isEnabled: student.remainingLessons > 0
            ) {
                LessonLiveActivity.start(studentName: student.fullName)
                Task {
                    await vm.complete(studentId, onUnauthorized: auth.handleUnauthorized)
                }
            }

            AppSecondaryButton(
                title: "Отметить пропуск",
                systemImage: "person.slash"
            ) {
                showMissedConfirm = true
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private func detailLink(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .frame(width: 28)
                    .foregroundStyle(AppTheme.primary)
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func remainingColor(_ student: Student) -> Color {
        if student.remainingLessons <= 0 { return .secondary }
        if student.remainingLessons == 1 { return AppTheme.danger }
        return AppTheme.primary
    }

    private func remainingFill(_ student: Student) -> Color {
        if student.remainingLessons <= 0 { return Color(.secondarySystemGroupedBackground) }
        if student.remainingLessons == 1 { return AppTheme.danger.opacity(0.1) }
        return AppTheme.primary.opacity(0.08)
    }

    private func initials(_ student: Student) -> String {
        let parts = [student.firstName, student.lastName]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return parts.prefix(2).compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    private func openEdit() async {
        do {
            editPayload = try await API.student(studentId)
        } catch is AuthError {
            auth.handleUnauthorized()
        } catch {
            // Fallback to list data so sheet still opens
            if let student {
                editPayload = student
            } else {
                vm.toast = "Не удалось загрузить данные"
                vm.toastIsError = true
            }
        }
    }
}
