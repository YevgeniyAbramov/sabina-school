import SwiftUI

/// Compact procedural running cat for the hold control.
struct RunningCat: View {
    var phase: CGFloat
    var isHappy: Bool = false

    private var bounce: CGFloat { abs(sin(phase * .pi * 2)) * 2 }
    private var legA: CGFloat { sin(phase * .pi * 2) * 8 }
    private var legB: CGFloat { sin(phase * .pi * 2 + .pi) * 8 }
    private var tailSwing: CGFloat { sin(phase * .pi * 2) * 10 }

    private let fur = Color(red: 0.93, green: 0.62, blue: 0.32)
    private let furDark = Color(red: 0.82, green: 0.48, blue: 0.22)
    private let belly = Color(red: 0.98, green: 0.90, blue: 0.78)
    private let earInner = Color(red: 0.95, green: 0.72, blue: 0.68)
    private let nose = Color(red: 0.86, green: 0.42, blue: 0.45)
    private let eye = Color(red: 0.18, green: 0.14, blue: 0.12)

    var body: some View {
        ZStack {
            Capsule()
                .fill(fur)
                .frame(width: 5, height: 16)
                .rotationEffect(.degrees(-38 + Double(tailSwing)), anchor: .bottom)
                .offset(x: -15, y: -4 - bounce * 0.2)

            Capsule()
                .fill(furDark)
                .frame(width: 5, height: 11)
                .rotationEffect(.degrees(Double(legA) * 0.55), anchor: .top)
                .offset(x: -7, y: 10)

            Capsule()
                .fill(furDark)
                .frame(width: 5, height: 11)
                .rotationEffect(.degrees(Double(legB) * 0.55), anchor: .top)
                .offset(x: -2, y: 10)

            Capsule()
                .fill(fur)
                .frame(width: 24, height: 14)
                .offset(y: -bounce)

            Capsule()
                .fill(belly)
                .frame(width: 12, height: 7)
                .offset(x: 1, y: 1 - bounce)

            Capsule()
                .fill(furDark)
                .frame(width: 5, height: 11)
                .rotationEffect(.degrees(Double(legB) * 0.65), anchor: .top)
                .offset(x: 6, y: 10)

            Capsule()
                .fill(furDark)
                .frame(width: 5, height: 11)
                .rotationEffect(.degrees(Double(legA) * 0.65), anchor: .top)
                .offset(x: 11, y: 10)

            Circle()
                .fill(fur)
                .frame(width: 15, height: 15)
                .overlay {
                    HStack(spacing: 3) {
                        Capsule()
                            .fill(eye)
                            .frame(width: isHappy ? 3.5 : 2.2, height: isHappy ? 1.5 : 3.5)
                        Capsule()
                            .fill(eye)
                            .frame(width: isHappy ? 3.5 : 2.2, height: isHappy ? 1.5 : 3.5)
                    }
                }
                .overlay(alignment: .bottom) {
                    Circle()
                        .fill(nose)
                        .frame(width: 3, height: 2.5)
                        .offset(y: -3.5)
                }
                .offset(x: 13, y: -7 - bounce)

            Triangle()
                .fill(fur)
                .frame(width: 7, height: 8)
                .offset(x: 9, y: -16 - bounce)
            Triangle()
                .fill(fur)
                .frame(width: 7, height: 8)
                .offset(x: 16, y: -16 - bounce)

            Triangle()
                .fill(earInner)
                .frame(width: 3.5, height: 4.5)
                .offset(x: 9, y: -14.5 - bounce)
            Triangle()
                .fill(earInner)
                .frame(width: 3.5, height: 4.5)
                .offset(x: 16, y: -14.5 - bounce)
        }
        .frame(width: 40, height: 32)
        .clipped()
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
