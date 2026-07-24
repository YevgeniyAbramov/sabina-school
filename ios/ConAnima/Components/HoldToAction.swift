import SwiftUI
import UIKit

/// Hold ~1s — compact track, cat runs left→right, then action.
struct HoldToAction: View {
    var title: String = "Провести урок"
    var holdDuration: TimeInterval = 1.0
    var isEnabled: Bool = true
    var onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @State private var isHolding = false
    @State private var isCompleted = false
    @State private var walkPhase: CGFloat = 0
    @State private var holdTask: Task<Void, Never>?
    @State private var trackWidth: CGFloat = 0

    private let height: CGFloat = AppTheme.buttonHeight
    private let thumb: CGFloat = 40
    private let inset: CGFloat = 4

    private var travel: CGFloat {
        max(0, trackWidth - thumb - inset * 2)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(trackFill)
                .overlay {
                    Capsule()
                        .strokeBorder(AppTheme.primary.opacity(isEnabled ? 0.22 : 0), lineWidth: 1)
                }

            Capsule()
                .fill(AppTheme.primary.opacity(0.16))
                .frame(width: inset * 2 + thumb + progress * travel)
                .opacity(isEnabled && (isHolding || isCompleted) ? 1 : 0)

            Text(labelText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(labelColor)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, thumb + 10)
                .opacity(labelOpacity)
                .allowsHitTesting(false)

            ZStack {
                Circle()
                    .fill(isCompleted ? AppTheme.success : AppTheme.primary)
                    .shadow(color: AppTheme.primary.opacity(isEnabled ? 0.28 : 0), radius: 6, y: 2)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    RunningCat(phase: walkPhase, isHappy: false)
                        .scaleEffect(0.62)
                        .offset(y: 1)
                }
            }
            .frame(width: thumb, height: thumb)
            .offset(x: inset + progress * travel)
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isCompleted)
        }
        .frame(height: height)
        .clipped()
        .overlay(alignment: .trailing) {
            if isCompleted {
                PawBurst()
                    .padding(.trailing, thumb / 2 + inset)
            }
        }
        .contentShape(Capsule())
        .gesture(holdGesture)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { trackWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, w in trackWidth = w }
            }
        )
        .opacity(isEnabled ? 1 : 0.55)
        .allowsHitTesting(isEnabled && !isCompleted)
        .accessibilityLabel(title)
        .accessibilityHint("Удерживайте, пока котик добежит до конца")
        .accessibilityAddTraits(.isButton)
        .onDisappear { cancelHold(animated: false) }
    }

    private var trackFill: Color {
        if !isEnabled { return Color(.tertiarySystemFill) }
        if isCompleted { return AppTheme.success.opacity(0.14) }
        return AppTheme.primary.opacity(0.10)
    }

    private var labelText: String {
        if isCompleted { return "Готово" }
        if isHolding { return "Держи…" }
        return title
    }

    private var labelColor: Color {
        if !isEnabled { return .secondary }
        if isCompleted { return AppTheme.success }
        return AppTheme.primary.opacity(0.85)
    }

    private var labelOpacity: Double {
        if isCompleted { return 1 }
        if progress < 0.08 { return 1 }
        return max(0, 1 - Double(progress) * 1.6)
    }

    private var holdGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard isEnabled, !isCompleted else { return }
                if !isHolding { startHold() }
            }
            .onEnded { _ in
                guard isEnabled, !isCompleted else { return }
                if progress < 0.98 {
                    cancelHold(animated: true)
                }
            }
    }

    private func startHold() {
        isHolding = true

        let soft = UIImpactFeedbackGenerator(style: .soft)
        let light = UIImpactFeedbackGenerator(style: .light)
        let rigid = UIImpactFeedbackGenerator(style: .rigid)
        let success = UINotificationFeedbackGenerator()
        soft.prepare()
        light.prepare()
        rigid.prepare()
        success.prepare()
        soft.impactOccurred(intensity: 0.4)

        let started = Date()
        let duration = holdDuration
        var lastHapticAt: TimeInterval = 0

        holdTask = Task { @MainActor in
            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(started)
                let next = CGFloat(min(1, elapsed / duration))
                progress = next
                walkPhase = next * 3

                if next < 1 {
                    let interval = Self.hapticInterval(for: next)
                    if elapsed - lastHapticAt >= interval {
                        lastHapticAt = elapsed
                        let intensity = CGFloat(0.32 + 0.68 * Double(next))
                        if next < 0.35 {
                            soft.impactOccurred(intensity: intensity)
                        } else if next < 0.7 {
                            light.impactOccurred(intensity: intensity)
                        } else {
                            rigid.impactOccurred(intensity: intensity)
                        }
                    }
                }

                if next >= 1 {
                    finish(successHaptic: success)
                    return
                }

                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    /// ~220ms at start → ~40ms near the end.
    private static func hapticInterval(for progress: CGFloat) -> TimeInterval {
        let t = Double(min(1, max(0, progress)))
        return 0.22 * pow(1 - t, 1.55) + 0.038
    }

    private func cancelHold(animated: Bool) {
        holdTask?.cancel()
        holdTask = nil
        isHolding = false
        guard !isCompleted else { return }

        if animated {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.35)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.84)) {
                progress = 0
                walkPhase = 0
            }
        } else {
            progress = 0
            walkPhase = 0
        }
    }

    private func finish(successHaptic: UINotificationFeedbackGenerator = .init()) {
        guard !isCompleted else { return }
        holdTask?.cancel()
        holdTask = nil
        isHolding = false
        isCompleted = true
        progress = 1
        walkPhase = 3
        successHaptic.notificationOccurred(.success)
        onComplete()

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(750))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                isCompleted = false
                progress = 0
                walkPhase = 0
            }
        }
    }
}
