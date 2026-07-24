import ActivityKit
import Foundation

private let lessonLiveActivityDefaultDuration: TimeInterval = 60 * 60

/// Temporary kill switch — flip to `true` to re-enable the Dynamic Island / Lock Screen
/// timer without touching any call sites.
private let lessonLiveActivityFeatureEnabled = false

/// Starts/stops the "lesson in progress" Live Activity (Dynamic Island + Lock Screen).
/// App-target only — the actual UI lives in the Widget Extension target.
@MainActor
enum LessonLiveActivity {
    static let defaultDuration = lessonLiveActivityDefaultDuration

    private static var current: ActivityKit.Activity<LessonActivityAttributes>?

    static func start(studentName: String, duration: TimeInterval = lessonLiveActivityDefaultDuration) {
        guard lessonLiveActivityFeatureEnabled else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        end()

        let now = Date()
        let endsAt = now.addingTimeInterval(duration)
        let attributes = LessonActivityAttributes(studentName: studentName, startedAt: now)
        let state = LessonActivityAttributes.ContentState(endsAt: endsAt)

        do {
            let activity = try ActivityKit.Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: endsAt),
                pushType: nil
            )
            current = activity

            Task {
                try? await Task.sleep(for: .seconds(duration))
                if current?.id == activity.id {
                    end()
                }
            }
        } catch {
            current = nil
        }
    }

    static func end() {
        guard let activity = current else { return }
        current = nil
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
