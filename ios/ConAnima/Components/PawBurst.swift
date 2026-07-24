import SwiftUI

/// Small "paw-print" celebration burst — same fur palette as `RunningCat`, used as a
/// lightweight, on-theme substitute for confetti after a successful `HoldToAction` hold.
struct PawBurst: View {
    private struct Paw {
        let dx: CGFloat
        let dy: CGFloat
        let rotation: Double
        let delay: Double
        let scale: CGFloat
    }

    private let paws: [Paw] = [
        Paw(dx: -28, dy: -12, rotation: -22, delay: 0.00, scale: 0.85),
        Paw(dx: -11, dy: -30, rotation: 8, delay: 0.05, scale: 1.0),
        Paw(dx: 9, dy: -32, rotation: -6, delay: 0.03, scale: 0.9),
        Paw(dx: 25, dy: -14, rotation: 20, delay: 0.08, scale: 0.8),
        Paw(dx: 0, dy: -20, rotation: 2, delay: 0.11, scale: 0.7),
    ]

    private let tint = Color(red: 0.93, green: 0.62, blue: 0.32)

    @State private var scattered = false
    @State private var faded = false

    var body: some View {
        ZStack {
            ForEach(paws.indices, id: \.self) { i in
                let paw = paws[i]
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(tint)
                    .symbolEffect(.bounce, value: scattered)
                    .rotationEffect(.degrees(paw.rotation))
                    .scaleEffect(scattered ? paw.scale : 0.2)
                    .offset(x: scattered ? paw.dx : 0, y: scattered ? paw.dy : 0)
                    .opacity(faded ? 0 : (scattered ? 1 : 0))
                    .animation(
                        .spring(response: 0.42, dampingFraction: 0.62).delay(paw.delay),
                        value: scattered
                    )
                    .animation(.easeOut(duration: 0.3), value: faded)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            scattered = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(420))
                faded = true
            }
        }
    }
}
