import SwiftUI

/// Shared labeled text field used across auth and forms.
struct AppTextField<FocusValue: Hashable>: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure = false
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType?
    var submitLabel: SubmitLabel = .next
    var focusValue: FocusValue
    var focused: FocusState<FocusValue?>.Binding
    var onSubmit: (() -> Void)?

    private var isFocused: Bool {
        focused.wrappedValue == focusValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textContentType(contentType)
                } else {
                    TextField(placeholder, text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(keyboard)
                        .textContentType(contentType)
                }
            }
            .focused(focused, equals: focusValue)
            .submitLabel(submitLabel)
            .onSubmit { onSubmit?() }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                    .fill(Color.primary.opacity(0.035))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous)
                    .strokeBorder(
                        isFocused ? AppTheme.primary.opacity(0.5) : Color.primary.opacity(0.09),
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
    }
}

struct ErrorCallout: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(AppTheme.danger)
                .font(.body)
            Text(message)
                .font(.footnote)
                .foregroundStyle(AppTheme.danger)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(AppTheme.danger.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityLabel("Ошибка: \(message)")
    }
}
