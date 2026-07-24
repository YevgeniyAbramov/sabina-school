import ActivityKit
import Foundation

/// Shared between the app and the Widget Extension target — after creating the
/// extension in Xcode, add this file to its target membership too (File Inspector →
/// Target Membership → check the widget extension), otherwise it won't compile there.
struct LessonActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var endsAt: Date
    }

    var studentName: String
    var startedAt: Date
}
