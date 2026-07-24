import Foundation

struct Student: Codable, Identifiable, Hashable {
    let id: Int
    var teacherId: Int
    var firstName: String
    var lastName: String
    var middleName: String?
    var totalLessons: Int
    var remainingLessons: Int
    var paidAmount: Int
    var missedClasses: Int
    var isPaid: Bool
    var createdAt: String
    var updatedAt: String
    var deletedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case teacherId = "teacher_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case middleName = "middle_name"
        case totalLessons = "total_lessons"
        case remainingLessons = "remaining_lessons"
        case paidAmount = "paid_amount"
        case missedClasses = "missed_classes"
        case isPaid = "is_paid"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    var completedLessons: Int {
        max(0, totalLessons - remainingLessons)
    }

    var progress: Double {
        guard totalLessons > 0 else { return 0 }
        return min(1, Double(completedLessons) / Double(totalLessons))
    }

    var statusTone: StatusTone? {
        guard totalLessons > 0 else { return nil }
        let pct = progress * 100
        if pct >= 90 { return .danger }
        if pct >= 65 { return .warn }
        return .ok
    }
}

enum StatusTone {
    case ok, warn, danger
}

struct StudentInput: Codable {
    var firstName: String
    var lastName: String
    var middleName: String
    var totalLessons: Int
    var remainingLessons: Int
    var paidAmount: Int
    var missedClasses: Int
    var isPaid: Bool

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case middleName = "middle_name"
        case totalLessons = "total_lessons"
        case remainingLessons = "remaining_lessons"
        case paidAmount = "paid_amount"
        case missedClasses = "missed_classes"
        case isPaid = "is_paid"
    }
}

struct ScheduleSlot: Codable, Identifiable, Hashable {
    var slotId: Int?
    var studentId: Int
    var teacherId: Int?
    var dayOfWeek: Int
    var timeSlot: String

    var id: Int {
        slotId ?? studentId * 10_000 + dayOfWeek * 100 + (Int(Formatters.normalizeTime(timeSlot).replacingOccurrences(of: ":", with: "")) ?? 0)
    }

    /// Stable ForEach identity — ignores optional API `id` flipping nil↔value on refresh.
    var stableKey: String {
        "\(studentId)-\(dayOfWeek)-\(Formatters.normalizeTime(timeSlot))"
    }

    enum CodingKeys: String, CodingKey {
        case slotId = "id"
        case studentId = "student_id"
        case teacherId = "teacher_id"
        case dayOfWeek = "day_of_week"
        case timeSlot = "time_slot"
    }
}

struct ScheduleSlotInput: Codable, Hashable {
    var dayOfWeek: Int
    var timeSlot: String

    enum CodingKeys: String, CodingKey {
        case dayOfWeek = "day_of_week"
        case timeSlot = "time_slot"
    }
}

struct MonthlySummary: Codable {
    let id: Int
    let teacherId: Int
    let year: Int
    let month: Int
    let totalAmount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case teacherId = "teacher_id"
        case year, month
        case totalAmount = "total_amount"
    }
}

enum ActivityKind: String, Codable, CaseIterable {
    case lesson, missed, payment, renew, student
}

struct Activity: Codable, Identifiable, Hashable {
    let id: Int
    let teacherId: Int
    let studentId: Int?
    let kind: ActivityKind
    let title: String
    let detail: String
    let amount: Int?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case teacherId = "teacher_id"
        case studentId = "student_id"
        case kind, title, detail, amount
        case createdAt = "created_at"
    }
}

struct ApiResponse<T: Decodable>: Decodable {
    let status: Bool
    let message: String?
    let data: T?
    let token: String?
    let teacher: TeacherInfo?
}

/// Accepts any JSON payload for mutation responses where `data` shape varies.
struct IgnoredData: Decodable {
    init(from decoder: Decoder) throws {
        if var container = try? decoder.unkeyedContainer() {
            while !container.isAtEnd {
                _ = try? container.decode(IgnoredData.self)
            }
            return
        }
        if let container = try? decoder.container(keyedBy: DynamicKey.self) {
            for key in container.allKeys {
                _ = try? container.decode(IgnoredData.self, forKey: key)
            }
            return
        }
        _ = try? decoder.singleValueContainer()
    }

    private struct DynamicKey: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { nil }
    }
}

struct TeacherInfo: Decodable {
    let firstName: String
    let lastName: String?

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

enum MaterialKind: String, Codable {
    case link
    case file
}

enum PieceStatus: String, Codable, CaseIterable, Identifiable {
    case learning
    case polished
    case paused
    case learned

    var id: String { rawValue }

    var title: String {
        switch self {
        case .learning: return "Учит"
        case .polished: return "Шлифует"
        case .paused: return "Пауза"
        case .learned: return "Выучил"
        }
    }
}

/// Repertoire piece — container for notes, links and readiness.
struct StudentPiece: Codable, Identifiable, Hashable {
    let id: Int
    var teacherId: Int
    var studentId: Int
    var title: String
    var composer: String
    var readiness: Int
    var status: PieceStatus
    var createdAt: String
    var updatedAt: String
    var notesCount: Int?
    var materialsCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case teacherId = "teacher_id"
        case studentId = "student_id"
        case title, composer, readiness, status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case notesCount = "notes_count"
        case materialsCount = "materials_count"
    }
}

struct StudentPieceNote: Codable, Identifiable, Hashable {
    let id: Int
    var pieceId: Int
    var teacherId: Int
    var studentId: Int
    var body: String
    var createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case pieceId = "piece_id"
        case teacherId = "teacher_id"
        case studentId = "student_id"
        case body
        case createdAt = "created_at"
    }
}

struct PieceDetail: Codable, Identifiable, Hashable {
    let id: Int
    var teacherId: Int
    var studentId: Int
    var title: String
    var composer: String
    var readiness: Int
    var status: PieceStatus
    var createdAt: String
    var updatedAt: String
    var materials: [StudentMaterial]
    var notes: [StudentPieceNote]

    enum CodingKeys: String, CodingKey {
        case id
        case teacherId = "teacher_id"
        case studentId = "student_id"
        case title, composer, readiness, status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case materials, notes
    }

    var asPiece: StudentPiece {
        StudentPiece(
            id: id,
            teacherId: teacherId,
            studentId: studentId,
            title: title,
            composer: composer,
            readiness: readiness,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            notesCount: notes.count,
            materialsCount: materials.count
        )
    }
}

struct PieceInput: Codable {
    var title: String
    var composer: String
    var readiness: Int?
    var status: PieceStatus
}

struct PieceNoteInput: Codable {
    var body: String
}

struct DiaryShareCreateResult: Codable, Hashable {
    var token: String
    var url: String
    var expiresAt: String

    enum CodingKeys: String, CodingKey {
        case token, url
        case expiresAt = "expires_at"
    }
}

/// One entry under a piece — link or uploaded file (sheet music).
struct StudentMaterial: Codable, Identifiable, Hashable {
    let id: Int
    var teacherId: Int
    var studentId: Int
    var pieceId: Int?
    var kind: MaterialKind
    var title: String
    var url: String
    var fileName: String?
    var note: String
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case teacherId = "teacher_id"
        case studentId = "student_id"
        case pieceId = "piece_id"
        case kind, title, url
        case fileName = "file_name"
        case note
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var fileExtension: String {
        let name = fileName ?? url
        return (name as NSString).pathExtension.lowercased()
    }

    var isImage: Bool {
        ["jpg", "jpeg", "png", "heic"].contains(fileExtension)
    }
}

struct MaterialLinkInput: Codable {
    var title: String
    var url: String
    var note: String
    var pieceId: Int?

    enum CodingKeys: String, CodingKey {
        case title, url, note
        case pieceId = "piece_id"
    }
}

struct MaterialUpdateInput: Codable {
    var title: String
    var note: String
}

enum StudentFilter: String, CaseIterable, Identifiable {
    case all, paid, unpaid, endingSoon, finished

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return Copy.filterAll
        case .paid: return Copy.filterPaid
        case .unpaid: return Copy.filterUnpaid
        case .endingSoon: return Copy.endingSoon
        case .finished: return Copy.finished
        }
    }
}
