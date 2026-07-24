import ActivityKit
import Foundation

/// Mirrors `ConAnima/LiveActivity/LessonActivityAttributes.swift` from the app target.
/// ActivityKit only needs the two types to be structurally identical (Codable), so a
/// synced copy per target is simpler here than sharing a framework. Keep both in sync.
struct LessonActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var endsAt: Date
    }

    var studentName: String
    var startedAt: Date
}
