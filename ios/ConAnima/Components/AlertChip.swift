import SwiftUI

struct AlertChip: View {
    let value: Int
    let label: String
    let tone: Tone
    var active = false
    let action: () -> Void

    enum Tone { case bad, warn, muted }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text("\(value)")
                    .font(.system(size: 15, weight: .semibold).monospacedDigit())
                    .contentTransition(.numericText())
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(active ? Color.white : foreground)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(active ? fillActive : fillIdle, in: Capsule())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: active)
        .accessibilityLabel("\(label): \(value)")
        .accessibilityAddTraits(active ? .isSelected : [])
    }

    private var foreground: Color {
        switch tone {
        case .bad: return AppTheme.danger
        case .warn: return AppTheme.warning
        case .muted: return .primary
        }
    }

    private var fillActive: Color {
        switch tone {
        case .bad: return AppTheme.danger
        case .warn: return AppTheme.warning
        case .muted: return Color.primary
        }
    }

    private var fillIdle: Color {
        switch tone {
        case .bad: return AppTheme.danger.opacity(0.12)
        case .warn: return AppTheme.warning.opacity(0.14)
        case .muted: return Color(.tertiarySystemFill)
        }
    }
}
