import SwiftUI
import UIKit

struct AddLinkSheet: View {
    let onConfirm: (_ title: String, _ url: String, _ note: String) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var title = ""
    @State private var url = ""
    @State private var note = ""
    @State private var saving = false
    @State private var justSaved = false
    @State private var error: String?

    private enum Field { case title, url, note }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
            && (url.hasPrefix("http://") || url.hasPrefix("https://"))
            && !saving
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    fieldsCard

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
            .navigationTitle("Новая ссылка")
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
                    title: "Добавить",
                    systemImage: "link",
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
        }
    }

    private var fieldsCard: some View {
        VStack(spacing: 8) {
            row("Название", text: $title, field: .title, placeholder: "Например, «Этюд №3»", keyboard: .default)
            row("Ссылка", text: $url, field: .url, placeholder: "https://youtube.com/...", keyboard: .URL)
            row("Заметка", text: $note, field: .note, placeholder: "Необязательно", keyboard: .default)
        }
    }

    private func row(
        _ label: String,
        text: Binding<String>,
        field: Field,
        placeholder: String,
        keyboard: UIKeyboardType
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(field == .url ? .never : .sentences)
                .autocorrectionDisabled(field == .url)
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

    private func save() async {
        saving = true
        error = nil
        defer { saving = false }
        do {
            try await onConfirm(
                title.trimmingCharacters(in: .whitespaces),
                url.trimmingCharacters(in: .whitespaces),
                note.trimmingCharacters(in: .whitespaces)
            )
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            justSaved = true
            try? await Task.sleep(for: .milliseconds(550))
            dismiss()
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? "Не удалось добавить"
        }
    }
}

struct AddFileDetailsSheet: View {
    let fileName: String
    let onConfirm: (_ title: String, _ note: String) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var title: String
    @State private var note = ""
    @State private var saving = false
    @State private var justSaved = false
    @State private var error: String?

    private enum Field { case title, note }

    init(fileName: String, onConfirm: @escaping (String, String) async throws -> Void) {
        self.fileName = fileName
        self.onConfirm = onConfirm
        _title = State(initialValue: (fileName as NSString).deletingPathExtension)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && !saving
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    fieldsCard

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
            .navigationTitle("Новый файл")
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
                    title: "Загрузить",
                    systemImage: "arrow.up.doc",
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
        }
    }

    private var fieldsCard: some View {
        VStack(spacing: 8) {
            row("Название", text: $title, field: .title, placeholder: "Например, «Ноты — Гаммы»")
            row("Заметка", text: $note, field: .note, placeholder: "Необязательно")
        }
    }

    private func row(_ label: String, text: Binding<String>, field: Field, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
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

    private func save() async {
        saving = true
        error = nil
        defer { saving = false }
        do {
            try await onConfirm(
                title.trimmingCharacters(in: .whitespaces),
                note.trimmingCharacters(in: .whitespaces)
            )
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            justSaved = true
            try? await Task.sleep(for: .milliseconds(550))
            dismiss()
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? "Не удалось загрузить"
        }
    }
}
