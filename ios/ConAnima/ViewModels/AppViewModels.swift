import Foundation
import Observation

@Observable
final class AuthViewModel {
    var isAuthenticated = AuthStore.isAuthenticated
    var teacherName = AuthStore.teacherName
    var username = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?

    func login() async {
        errorMessage = nil
        let u = username.trimmingCharacters(in: .whitespaces)
        guard !u.isEmpty, !password.isEmpty else {
            errorMessage = "Заполните логин и пароль"
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let res = try await APIClient.shared.login(username: u, password: password)
            guard res.status, let token = res.token else {
                errorMessage = res.message ?? "Неверный логин или пароль"
                return
            }
            AuthStore.set(token: token, teacherName: res.teacher?.firstName)
            teacherName = res.teacher?.firstName
            isAuthenticated = true
            password = ""
        } catch let e as APIError {
            switch e {
            case .network:
                errorMessage = "\(e.errorDescription ?? "Нет связи")\n\(APIClient.shared.baseURL.host ?? "")"
            default:
                errorMessage = e.errorDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() {
        AuthStore.clear()
        isAuthenticated = false
        teacherName = nil
    }

    func handleUnauthorized() {
        logout()
    }
}

@Observable
final class StudentsViewModel {
    var students: [Student] = []
    var filter: StudentFilter = .all
    var query = ""
    var isLoading = true
    var toast: String?
    var toastIsError = false

    var unpaidCount: Int { students.filter { !$0.isPaid }.count }
    var endingSoonCount: Int { students.filter { $0.remainingLessons == 1 }.count }
    var finishedCount: Int { students.filter { $0.remainingLessons <= 0 }.count }

    var filtered: [Student] {
        var result = students
        switch filter {
        case .all: break
        case .paid: result = result.filter(\.isPaid)
        case .unpaid: result = result.filter { !$0.isPaid }
        case .endingSoon: result = result.filter { $0.remainingLessons == 1 }
        case .finished: result = result.filter { $0.remainingLessons <= 0 }
        }
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            result = result.filter {
                [$0.lastName, $0.firstName, $0.middleName ?? ""]
                    .joined(separator: " ")
                    .lowercased()
                    .contains(q)
            }
        }
        // Parse each `createdAt` once instead of re-parsing on every comparison during the sort.
        return result
            .map { ($0, Formatters.parseISO($0.createdAt) ?? .distantPast) }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }

    func toggleFilter(_ next: StudentFilter) {
        filter = filter == next ? .all : next
    }

    @MainActor
    func load(onUnauthorized: () -> Void) async {
        do {
            students = try await API.students()
        } catch is AuthError {
            onUnauthorized()
        } catch {
            showToast("Нет связи с сервером", error: true)
        }
        isLoading = false
    }

    @MainActor
    func refresh(onUnauthorized: () -> Void) async {
        do {
            students = try await API.students()
        } catch is AuthError {
            onUnauthorized()
        } catch {
            showToast("Нет связи с сервером", error: true)
        }
    }

    @MainActor
    func add(_ input: StudentInput, onUnauthorized: () -> Void) async throws {
        do {
            try await API.createStudent(input)
            await refresh(onUnauthorized: onUnauthorized)
        } catch is AuthError {
            onUnauthorized()
            throw APIError.message("Unauthorized")
        } catch {
            showToast((error as? LocalizedError)?.errorDescription ?? "Не удалось добавить", error: true)
            throw error
        }
    }

    @MainActor
    func update(_ id: Int, _ input: StudentInput, onUnauthorized: () -> Void) async throws {
        do {
            try await API.updateStudent(id, input)
            await refresh(onUnauthorized: onUnauthorized)
        } catch is AuthError {
            onUnauthorized()
            throw APIError.message("Unauthorized")
        } catch {
            showToast((error as? LocalizedError)?.errorDescription ?? "Не удалось сохранить", error: true)
            throw error
        }
    }

    @MainActor
    func delete(_ id: Int, onUnauthorized: () -> Void) async {
        do {
            try await API.deleteStudent(id)
            await refresh(onUnauthorized: onUnauthorized)
        } catch is AuthError {
            onUnauthorized()
        } catch {
            showToast((error as? LocalizedError)?.errorDescription ?? "Не удалось удалить", error: true)
        }
    }

    @MainActor
    @discardableResult
    func complete(_ id: Int, onUnauthorized: () -> Void) async -> Bool {
        do {
            try await API.completeLesson(id)
            await refresh(onUnauthorized: onUnauthorized)
            showToast("Урок проведён", error: false)
            return true
        } catch is AuthError {
            onUnauthorized()
            return false
        } catch {
            showToast((error as? LocalizedError)?.errorDescription ?? "Не удалось отметить урок", error: true)
            return false
        }
    }

    @MainActor
    @discardableResult
    func missed(_ id: Int, onUnauthorized: () -> Void) async -> Bool {
        do {
            try await API.markMissed(id)
            await refresh(onUnauthorized: onUnauthorized)
            showToast("Пропуск отмечен", error: false)
            return true
        } catch is AuthError {
            onUnauthorized()
            return false
        } catch {
            showToast((error as? LocalizedError)?.errorDescription ?? "Не удалось отметить пропуск", error: true)
            return false
        }
    }

    @MainActor
    func renew(_ student: Student, lessons: Int, payment: Int, onUnauthorized: () -> Void) async throws {
        let input = StudentInput(
            firstName: student.firstName,
            lastName: student.lastName,
            middleName: student.middleName ?? "",
            totalLessons: lessons,
            remainingLessons: lessons,
            paidAmount: payment,
            missedClasses: student.missedClasses,
            isPaid: true
        )
        try await update(student.id, input, onUnauthorized: onUnauthorized)
        showToast("Готово: 0 из \(lessons)", error: false)
    }

    private func showToast(_ message: String, error: Bool) {
        toastIsError = error
        toast = message
    }
}

@Observable
final class DiaryViewModel {
    var pieces: [StudentPiece] = []
    var isLoading = true
    var toast: String?
    var toastIsError = false

    @MainActor
    func load(studentId: Int, onUnauthorized: () -> Void) async {
        isLoading = true
        do {
            pieces = try await API.pieces(studentId: studentId)
        } catch is AuthError {
            onUnauthorized()
        } catch {
            showToast("Нет связи с сервером", error: true)
        }
        isLoading = false
    }

    @MainActor
    func create(studentId: Int, title: String, composer: String, onUnauthorized: () -> Void) async throws {
        do {
            let created = try await API.createPiece(
                studentId: studentId,
                PieceInput(title: title, composer: composer, readiness: 0, status: .learning)
            )
            pieces.insert(created, at: 0)
        } catch is AuthError {
            onUnauthorized()
            throw APIError.message("Unauthorized")
        }
    }

    @MainActor
    func delete(studentId: Int, pieceId: Int, onUnauthorized: () -> Void) async {
        do {
            try await API.deletePiece(studentId: studentId, pieceId: pieceId)
            pieces.removeAll { $0.id == pieceId }
        } catch is AuthError {
            onUnauthorized()
        } catch {
            showToast((error as? LocalizedError)?.errorDescription ?? "Не удалось удалить", error: true)
        }
    }

    @MainActor
    func createShare(studentId: Int, onUnauthorized: () -> Void) async -> URL? {
        do {
            let result = try await API.createDiaryShare(studentId: studentId)
            if let url = URL(string: result.url), url.scheme != nil, url.host != nil {
                return url
            }
            var components = URLComponents(url: AppConfig.apiBaseURL, resolvingAgainstBaseURL: false)
            components?.path = ""
            components?.query = nil
            components?.fragment = nil
            if let root = components?.url,
               let url = URL(string: result.url.hasPrefix("/") ? result.url : "/\(result.url)", relativeTo: root)?.absoluteURL
            {
                return url
            }
            showToast("Некорректная ссылка", error: true)
            return nil
        } catch is AuthError {
            onUnauthorized()
            return nil
        } catch {
            showToast((error as? LocalizedError)?.errorDescription ?? "Не удалось создать ссылку", error: true)
            return nil
        }
    }

    private func showToast(_ message: String, error: Bool) {
        toastIsError = error
        toast = message
    }
}

@Observable
final class PieceDetailViewModel {
    var detail: PieceDetail?
    var isLoading = true
    var toast: String?
    var toastIsError = false

    var notes: [StudentMaterial] { detail?.materials.filter { $0.kind == .file } ?? [] }
    var links: [StudentMaterial] { detail?.materials.filter { $0.kind == .link } ?? [] }

    @MainActor
    func load(studentId: Int, pieceId: Int, onUnauthorized: () -> Void) async {
        isLoading = true
        do {
            detail = try await API.piece(studentId: studentId, pieceId: pieceId)
        } catch is AuthError {
            onUnauthorized()
        } catch {
            showToast("Нет связи с сервером", error: true)
        }
        isLoading = false
    }

    @MainActor
    func saveMeta(
        studentId: Int,
        title: String,
        composer: String,
        readiness: Int,
        status: PieceStatus,
        onUnauthorized: () -> Void
    ) async {
        guard let detail else { return }
        // Skip no-op writes (e.g. hydration syncing local state from server).
        if detail.readiness == readiness && detail.status == status
            && detail.title == title && detail.composer == composer
        {
            return
        }
        do {
            let updated = try await API.updatePiece(
                studentId: studentId,
                pieceId: detail.id,
                PieceInput(title: title, composer: composer, readiness: readiness, status: status)
            )
            self.detail?.title = updated.title
            self.detail?.composer = updated.composer
            self.detail?.readiness = updated.readiness
            self.detail?.status = updated.status
            self.detail?.updatedAt = updated.updatedAt
        } catch is AuthError {
            onUnauthorized()
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            showToast("Не удалось сохранить готовность", error: true)
        }
    }

    @MainActor
    func addNote(studentId: Int, body: String, onUnauthorized: () -> Void) async throws {
        guard let detail else { return }
        do {
            let note = try await API.addPieceNote(studentId: studentId, pieceId: detail.id, body: body)
            self.detail?.notes.insert(note, at: 0)
        } catch is AuthError {
            onUnauthorized()
            throw APIError.message("Unauthorized")
        }
    }

    @MainActor
    func deleteNote(studentId: Int, noteId: Int, onUnauthorized: () -> Void) async {
        guard let detail else { return }
        do {
            try await API.deletePieceNote(studentId: studentId, pieceId: detail.id, noteId: noteId)
            self.detail?.notes.removeAll { $0.id == noteId }
        } catch is AuthError {
            onUnauthorized()
        } catch {
            showToast("Не удалось удалить заметку", error: true)
        }
    }

    @MainActor
    func addLink(studentId: Int, title: String, url: String, note: String, onUnauthorized: () -> Void) async throws {
        guard let detail else { return }
        do {
            let created = try await API.addMaterialLink(
                studentId: studentId,
                MaterialLinkInput(title: title, url: url, note: note, pieceId: detail.id)
            )
            self.detail?.materials.append(created)
        } catch is AuthError {
            onUnauthorized()
            throw APIError.message("Unauthorized")
        }
    }

    @MainActor
    func addFile(
        studentId: Int,
        title: String,
        note: String,
        fileName: String,
        mimeType: String,
        fileData: Data,
        onUnauthorized: () -> Void
    ) async throws {
        guard let detail else { return }
        do {
            let created = try await API.addMaterialFile(
                studentId: studentId,
                title: title,
                note: note,
                fileName: fileName,
                mimeType: mimeType,
                fileData: fileData,
                pieceId: detail.id
            )
            self.detail?.materials.append(created)
        } catch is AuthError {
            onUnauthorized()
            throw APIError.message("Unauthorized")
        }
    }

    @MainActor
    func deleteMaterial(studentId: Int, materialId: Int, onUnauthorized: () -> Void) async {
        do {
            try await API.deleteMaterial(studentId: studentId, materialId: materialId)
            detail?.materials.removeAll { $0.id == materialId }
        } catch is AuthError {
            onUnauthorized()
        } catch {
            showToast("Не удалось удалить", error: true)
        }
    }

    private func showToast(_ message: String, error: Bool) {
        toastIsError = error
        toast = message
    }
}

@Observable
final class HistoryViewModel {
    var items: [Activity] = []
    var isLoading = true

    struct DayGroup: Identifiable {
        let id: String
        let label: String
        let items: [Activity]
    }

    var groups: [DayGroup] {
        var map: [String: [Activity]] = [:]
        var order: [String] = []
        for item in items {
            let key = Formatters.dayKey(item.createdAt)
            if map[key] == nil {
                order.append(key)
                map[key] = []
            }
            map[key]?.append(item)
        }
        return order.map { key in
            let list = map[key] ?? []
            return DayGroup(
                id: key,
                label: Formatters.dayLabel(list.first?.createdAt ?? ""),
                items: list
            )
        }
    }

    @MainActor
    func load(onUnauthorized: () -> Void) async {
        isLoading = true
        do {
            items = try await API.activity()
        } catch is AuthError {
            onUnauthorized()
        } catch {
            items = []
        }
        isLoading = false
    }
}
