import SwiftUI

/// Light student row — name + status pills + one meta line (no heavy metric boxes).
struct StudentRowView: View {
    let student: Student

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            avatar

            VStack(alignment: .leading, spacing: 6) {
                Text(student.fullName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

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
                }

                metaRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Color(.systemBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var metaRow: some View {
        HStack(spacing: 12) {
            metaItem(systemImage: "checkmark.circle", text: "\(student.completedLessons)/\(student.totalLessons)")
            metaItem(systemImage: "banknote", text: "\(Formatters.formatNumber(student.paidAmount)) ₸")
        }
    }

    private func metaItem(systemImage: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.caption2)
            Text(text)
                .font(.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(.secondary)
    }

    private var accessibilitySummary: String {
        "\(student.fullName). Осталось \(student.remainingLessons), пройдено \(student.completedLessons) из \(student.totalLessons), сумма \(Formatters.formatNumber(student.paidAmount)) тенге"
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(avatarTint.opacity(0.12))
                .frame(width: 40, height: 40)
            Text(initials)
                .font(.caption.weight(.semibold))
                .foregroundStyle(avatarTint)
        }
        .accessibilityHidden(true)
    }

    private var initials: String {
        let parts = [student.firstName, student.lastName]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let chars = parts.prefix(2).compactMap { $0.first.map(String.init) }
        return chars.joined().uppercased()
    }

    private var avatarTint: Color {
        if !student.isPaid { return AppTheme.danger }
        if student.remainingLessons == 1 { return AppTheme.warning }
        if student.remainingLessons <= 0 { return .secondary }
        return AppTheme.primary
    }
}
