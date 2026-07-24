import SwiftUI
import UIKit

/// Slide-right to confirm — haptic + action at the end.
struct SlideToAction: View {
    var title: String = "Провести урок"
    var systemImage: String = "checkmark"
    var isEnabled: Bool = true
    var onComplete: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var isCompleted = false
    @State private var trackWidth: CGFloat = 0
    @State private var didTickNearEnd = false

    private let thumbSize: CGFloat = 52
    private let inset: CGFloat = 4

    private var maxOffset: CGFloat {
        max(0, trackWidth - thumbSize - inset * 2)
    }

    private var progress: CGFloat {
        guard maxOffset > 0 else { return 0 }
        return min(1, max(0, dragOffset / maxOffset))
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(isEnabled ? AppTheme.primary.opacity(0.18) : Color(.tertiarySystemFill))

            Capsule()
                .fill(AppTheme.primary.opacity(0.28))
                .frame(width: thumbSize + inset * 2 + dragOffset)
                .opacity(isEnabled ? 1 : 0)

            HStack(spacing: 8) {
                Spacer(minLength: thumbSize)
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                Text(isCompleted ? "Готово" : title)
                    .font(.body.weight(.semibold))
                Spacer()
            }
            .foregroundStyle(isEnabled ? AppTheme.primary.opacity(0.55 + 0.45 * (1 - progress)) : .secondary)
            .opacity(isCompleted ? 0.9 : 1)
            .allowsHitTesting(false)

            Circle()
                .fill(isEnabled ? AppTheme.primary : Color(.tertiarySystemFill))
                .frame(width: thumbSize, height: thumbSize)
                .overlay {
                    Image(systemName: isCompleted ? "checkmark" : "chevron.right.2")
                        .font(.body.weight(.bold))
                        .foregroundStyle(isEnabled ? .white : .secondary)
                }
                .shadow(color: AppTheme.primary.opacity(isEnabled ? 0.35 : 0), radius: 8, y: 2)
                .offset(x: inset + dragOffset)
                .gesture(dragGesture)
                .accessibilityLabel(title)
                .accessibilityHint("Проведите вправо, чтобы подтвердить")
                .accessibilityAddTraits(.isButton)
        }
        .frame(height: thumbSize + inset * 2)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { trackWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, w in trackWidth = w }
            }
        )
        .opacity(isEnabled ? 1 : 0.55)
        .allowsHitTesting(isEnabled && !isCompleted)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: dragOffset)
        .animation(.easeOut(duration: 0.2), value: isCompleted)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard isEnabled, !isCompleted else { return }
                dragOffset = min(maxOffset, max(0, value.translation.width))
                if progress >= 0.85, !didTickNearEnd {
                    didTickNearEnd = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } else if progress < 0.7 {
                    didTickNearEnd = false
                }
            }
            .onEnded { _ in
                guard isEnabled, !isCompleted else { return }
                if progress >= 0.85 {
                    finish()
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        dragOffset = 0
                    }
                    didTickNearEnd = false
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }

    private func finish() {
        isCompleted = true
        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
            dragOffset = maxOffset
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onComplete()
        // Reset after brief success state so it can be used again if lessons remain
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                isCompleted = false
                dragOffset = 0
            }
        }
    }
}
