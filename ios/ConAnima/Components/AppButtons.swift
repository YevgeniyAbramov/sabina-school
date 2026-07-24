import SwiftUI
import UIKit

/// Primary CTA — same capsule chrome as `HoldToAction` idle state.
struct AppPrimaryButton: View {
    var title: String
    var systemImage: String? = nil
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var isSuccess: Bool = false
    var successTitle: String = "Готово"
    var successSystemImage: String = "checkmark.circle.fill"
    var action: () -> Void

    private let height: CGFloat = AppTheme.buttonHeight

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                } else if isSuccess {
                    Label(successTitle, systemImage: successSystemImage)
                } else if let systemImage {
                    Label(title, systemImage: systemImage)
                } else {
                    Text(title)
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(fill, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(stroke, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading || isSuccess)
        .opacity(isEnabled ? 1 : 0.55)
        .animation(.snappy, value: isSuccess)
        .accessibilityLabel(isSuccess ? successTitle : title)
    }

    private var foreground: Color {
        if isSuccess { return AppTheme.success }
        return AppTheme.primary.opacity(0.85)
    }

    private var fill: Color {
        if isSuccess { return AppTheme.success.opacity(0.14) }
        return AppTheme.primary.opacity(0.10)
    }

    private var stroke: Color {
        if isSuccess { return AppTheme.success.opacity(0.28) }
        return AppTheme.primary.opacity(isEnabled ? 0.22 : 0)
    }
}

/// Secondary CTA — light bordered capsule (e.g. «Отметить пропуск»).
struct AppSecondaryButton: View {
    var title: String
    var systemImage: String? = nil
    var isEnabled: Bool = true
    var action: () -> Void

    private let height: CGFloat = AppTheme.buttonHeight

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Label(title, systemImage: systemImage)
                } else {
                    Text(title)
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.primary.opacity(0.85))
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Color(.secondarySystemGroupedBackground), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(AppTheme.primary.opacity(0.18), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
        .accessibilityLabel(title)
    }
}

/// Soft capsule segment (presets / days) — same color language as `AppPrimaryButton`.
struct AppSegmentCapsule<T: Hashable>: View {
    let options: [(value: T, title: String)]
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.value) { option in
                let selected = selection == option.value
                Button {
                    withAnimation(.snappy) { selection = option.value }
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    Text(option.title)
                        .font(.subheadline.weight(selected ? .bold : .semibold))
                        .foregroundStyle(selected ? AppTheme.primary.opacity(0.9) : .secondary)
                        .contentTransition(.identity)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selected {
                                Capsule()
                                    .fill(AppTheme.primary.opacity(0.12))
                                    .overlay {
                                        Capsule()
                                            .strokeBorder(AppTheme.primary.opacity(0.22), lineWidth: 1)
                                    }
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.title)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Color(.tertiarySystemFill), in: Capsule())
    }
}
