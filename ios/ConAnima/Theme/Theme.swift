import SwiftUI

enum AppTheme {
    static let brand = "CON ANIMA"
    static let primary = Color("AccentColor")
    static let success = Color(red: 0.22, green: 0.55, blue: 0.42)
    static let warning = Color(red: 0.85, green: 0.55, blue: 0.15)
    static let danger = Color(red: 0.78, green: 0.28, blue: 0.28)
    static let cardRadius: CGFloat = 16
    static let controlRadius: CGFloat = 12
    /// Shared CTA height — `HoldToAction`, `AppPrimaryButton`, `AppSecondaryButton`.
    static let buttonHeight: CGFloat = 52

    /// App canvas — cool near-white (less gray than systemGroupedBackground).
    static let canvas = Color(red: 0.975, green: 0.978, blue: 0.992)
    /// Soft indigo wash for depth without gray wash.
    static let canvasWash = Color(red: 0.91, green: 0.93, blue: 0.99)

    static func toneColor(_ tone: StatusTone?) -> Color {
        switch tone {
        case .ok: return success
        case .warn: return warning
        case .danger: return danger
        case nil: return .clear
        }
    }
}

/// Shared status pill — fixed size so «Не оплачено» / «Закончился» match optically.
struct StatusCapsule: View {
    let text: String
    var tint: Color = .secondary

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

struct Chip: View {
    let text: String
    var tone: Tone = .soft

    enum Tone {
        case ok, bad, warn, soft
    }

    var body: some View {
        StatusCapsule(text: text, tint: foreground)
    }

    private var foreground: Color {
        switch tone {
        case .ok: return AppTheme.success
        case .bad: return AppTheme.danger
        case .warn: return AppTheme.warning
        case .soft: return .secondary
        }
    }
}

/// Soft page background used across tabs.
struct AppCanvasBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                AppTheme.canvasWash.opacity(0.55),
                AppTheme.canvas,
                AppTheme.canvas,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
