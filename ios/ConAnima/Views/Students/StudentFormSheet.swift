import SwiftUI
import UIKit

enum StudentFormMode {
    case add
    case edit(Student)

    var title: String {
        switch self {
        case .add: return "Новый ученик"
        case .edit: return "Изменить данные"
        }
    }

    var isEdit: Bool {
        if case .edit = self { return true }
        return false
    }
}

struct StudentFormSheet: View {
    let mode: StudentFormMode
    let onSubmit: (StudentInput) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var middleName = ""
    @State private var totalText = "8"
    @State private var remainingText = "8"
    @State private var missedText = "0"
    @State private var paidText = ""
    @State private var isPaid = false
    @State private var saving = false
    @State private var justSaved = false
    @State private var error: String?

    private enum Field: Hashable {
        case lastName, firstName, middleName, total, remaining, missed, paid
    }

    private var totalLessons: Int { Int(totalText.filter(\.isNumber)) ?? 0 }
    private var remainingLessons: Int { Int(remainingText.filter(\.isNumber)) ?? 0 }
    private var missedClasses: Int { Int(missedText.filter(\.isNumber)) ?? 0 }
    private var paidAmount: Int { Int(paidText.filter(\.isNumber)) ?? 0 }

    private var canSave: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
            && totalLessons > 0
            && !saving
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    nameCard
                    lessonsCard
                    paymentCard

                    if let error {
                        Text(error)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(AppTheme.danger)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background { AppCanvasBackground() }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        focusedField = nil
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                AppPrimaryButton(
                    title: "Сохранить",
                    systemImage: "checkmark",
                    isEnabled: canSave,
                    isLoading: saving,
                    isSuccess: justSaved,
                    successTitle: "Готово"
                ) {
                    focusedField = nil
                    Task { await save() }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(.bar)
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear(perform: hydrate)
        }
    }

    private var nameCard: some View {
        VStack(spacing: 8) {
            formTextRow("Фамилия", text: $lastName, field: .lastName, contentType: .familyName)
            formTextRow("Имя", text: $firstName, field: .firstName, contentType: .givenName)
            formTextRow("Отчество", text: $middleName, field: .middleName, contentType: .middleName)
        }
    }

    private var lessonsCard: some View {
        VStack(spacing: 8) {
            formNumberRow("Всего уроков", text: $totalText, field: .total, placeholder: "8")
            if mode.isEdit {
                formNumberRow("Осталось", text: $remainingText, field: .remaining, placeholder: "0")
                formNumberRow("Пропусков", text: $missedText, field: .missed, placeholder: "0")
            }
        }
    }

    private var paymentCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Сумма")
                Spacer()
                HStack(spacing: 4) {
                    TextField("0", text: $paidText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .monospacedDigit()
                        .font(.body.weight(.semibold))
                        .frame(minWidth: 72)
                        .focused($focusedField, equals: .paid)
                        .onChange(of: focusedField) { _, field in
                            if field == .paid, paidText == "0" {
                                paidText = ""
                            }
                        }
                    Text("₸")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
            )
            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)

            Toggle(isOn: $isPaid) {
                Text(isPaid ? Copy.paid : Copy.unpaid)
            }
            .tint(AppTheme.success)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
            )
            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        }
    }

    private func formTextRow(
        _ title: String,
        text: Binding<String>,
        field: Field,
        contentType: UITextContentType?
    ) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            TextField(title, text: text)
                .multilineTextAlignment(.trailing)
                .textContentType(contentType)
                .textInputAutocapitalization(.words)
                .focused($focusedField, equals: field)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func formNumberRow(
        _ title: String,
        text: Binding<String>,
        field: Field,
        placeholder: String
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(placeholder, text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.primary)
                .frame(minWidth: 56)
                .focused($focusedField, equals: field)
                .onChange(of: focusedField) { _, newField in
                    if newField == field, text.wrappedValue == "0" {
                        text.wrappedValue = ""
                    }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func hydrate() {
        guard case .edit(let s) = mode else {
            totalText = "8"
            remainingText = "8"
            missedText = "0"
            paidText = ""
            return
        }
        firstName = s.firstName
        lastName = s.lastName
        middleName = s.middleName ?? ""
        totalText = "\(s.totalLessons)"
        remainingText = "\(s.remainingLessons)"
        missedText = "\(s.missedClasses)"
        paidText = s.paidAmount == 0 ? "" : "\(s.paidAmount)"
        isPaid = s.isPaid
    }

    private func save() async {
        saving = true
        error = nil
        defer { saving = false }
        let input: StudentInput
        switch mode {
        case .add:
            input = StudentInput(
                firstName: firstName.trimmingCharacters(in: .whitespaces),
                lastName: lastName.trimmingCharacters(in: .whitespaces),
                middleName: middleName.trimmingCharacters(in: .whitespaces),
                totalLessons: totalLessons,
                remainingLessons: totalLessons,
                paidAmount: paidAmount,
                missedClasses: 0,
                isPaid: isPaid
            )
        case .edit:
            input = StudentInput(
                firstName: firstName.trimmingCharacters(in: .whitespaces),
                lastName: lastName.trimmingCharacters(in: .whitespaces),
                middleName: middleName.trimmingCharacters(in: .whitespaces),
                totalLessons: totalLessons,
                remainingLessons: remainingLessons,
                paidAmount: paidAmount,
                missedClasses: missedClasses,
                isPaid: isPaid
            )
        }
        do {
            try await onSubmit(input)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            justSaved = true
            try? await Task.sleep(for: .milliseconds(550))
            dismiss()
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? "Ошибка сохранения"
        }
    }
}

struct RenewLessonsSheet: View {
    let student: Student
    let onConfirm: (Int, Int) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var lessonsText = "8"
    @State private var paymentText = ""
    @State private var saving = false
    @State private var justSaved = false
    @State private var error: String?

    private enum Field { case lessons, payment }
    private let presets = [4, 8, 12]

    private var lessons: Int {
        Int(lessonsText.filter(\.isNumber)) ?? 0
    }

    private var payment: Int {
        Int(paymentText.filter(\.isNumber)) ?? 0
    }

    private var lessonsSelection: Binding<Int> {
        Binding(
            get: { presets.contains(lessons) ? lessons : -1 },
            set: { lessonsText = "\($0)" }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(student.fullName)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 4)

                    lessonsCard
                    paymentCard

                    if let error {
                        Text(error)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(AppTheme.danger)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background { AppCanvasBackground() }
            .navigationTitle("Продлить")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        focusedField = nil
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                confirmBar
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var lessonsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Уроков")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            AppSegmentCapsule(
                options: presets.map { (value: $0, title: "\($0)") },
                selection: lessonsSelection
            )

            HStack {
                Text("Своё число")
                Spacer()
                TextField("8", text: $lessonsText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
                    .frame(minWidth: 56)
                    .focused($focusedField, equals: .lessons)
                    .onChange(of: focusedField) { _, field in
                        if field == .lessons, lessonsText == "0" {
                            lessonsText = ""
                        }
                    }
            }
        }
        .padding(16)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private var paymentCard: some View {
        HStack {
            Text("Оплата")
            Spacer()
            HStack(spacing: 4) {
                TextField("0", text: $paymentText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .font(.body.weight(.semibold))
                    .frame(minWidth: 72)
                    .focused($focusedField, equals: .payment)
                    .onChange(of: focusedField) { _, field in
                        if field == .payment, paymentText == "0" {
                            paymentText = ""
                        }
                    }
                Text("₸")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private var confirmBar: some View {
        AppPrimaryButton(
            title: "Продлить",
            systemImage: "arrow.clockwise",
            isEnabled: lessons > 0 && !saving,
            isLoading: saving,
            isSuccess: justSaved,
            successTitle: "Готово"
        ) {
            focusedField = nil
            Task { await save() }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private func save() async {
        saving = true
        error = nil
        defer { saving = false }
        do {
            try await onConfirm(lessons, payment)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            justSaved = true
            try? await Task.sleep(for: .milliseconds(700))
            dismiss()
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? "Ошибка"
        }
    }
}
