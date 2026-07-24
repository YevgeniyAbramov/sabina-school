import ActivityKit
import WidgetKit
import SwiftUI

struct ConAnimaWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LessonActivityAttributes.self) { context in
            LockScreenLessonView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.78))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.studentName, systemImage: "pawprint.fill")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...context.state.endsAt, countsDown: true)
                        .font(.title3.monospacedDigit())
                        .frame(width: 64)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(timerInterval: context.attributes.startedAt...context.state.endsAt, countsDown: false)
                        .tint(.orange)
                }
            } compactLeading: {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                Text(timerInterval: Date()...context.state.endsAt, countsDown: true)
                    .font(.caption2.monospacedDigit())
                    .frame(width: 40)
            } minimal: {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(.orange)
            }
        }
    }
}

private struct LockScreenLessonView: View {
    let context: ActivityViewContext<LessonActivityAttributes>

    private let paw = Color(red: 0.93, green: 0.62, blue: 0.32)

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "pawprint.fill")
                    .font(.title2)
                    .foregroundStyle(paw)
                    .padding(10)
                    .background(Circle().fill(paw.opacity(0.2)))

                VStack(alignment: .leading, spacing: 3) {
                    Text("УРОК ИДЁТ")
                        .font(.caption2.weight(.bold))
                        .tracking(0.5)
                        .foregroundStyle(Color.white.opacity(0.55))

                    Text(context.attributes.studentName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(timerInterval: Date()...context.state.endsAt, countsDown: true)
                        .font(.title2.monospacedDigit().weight(.semibold))
                        .foregroundStyle(paw)

                    Text("осталось")
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity)

            ProgressView(timerInterval: context.attributes.startedAt...context.state.endsAt, countsDown: false)
                .tint(paw)
        }
        .padding(16)
    }
}

extension LessonActivityAttributes {
    fileprivate static var preview: LessonActivityAttributes {
        LessonActivityAttributes(studentName: "Аня Смирнова", startedAt: .now)
    }
}

extension LessonActivityAttributes.ContentState {
    fileprivate static var running: LessonActivityAttributes.ContentState {
        LessonActivityAttributes.ContentState(endsAt: .now.addingTimeInterval(60 * 60))
    }
}

#Preview("Notification", as: .content, using: LessonActivityAttributes.preview) {
    ConAnimaWidgetLiveActivity()
} contentStates: {
    LessonActivityAttributes.ContentState.running
}
