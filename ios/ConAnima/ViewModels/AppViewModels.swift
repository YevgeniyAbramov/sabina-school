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
    var materials: [StudentMaterial] = []
    var isLoading = true
    var toast: String?
    var toastIsError = false

    var sorted: [StudentMaterial] {
        materials
            .map { ($0, Formatters.parseISO($0.createdAt) ?? .distantPast) }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
    }

    @MainActor
    func load(studentId: Int, onUnauthorized: () -> Void) async {
        isLoading = true
        do {
            materials = try await API.materials(studentId: studentId)
        } catch is AuthError {
            onUnauthorized()
        } catch {
            showToast("Нет связи с сервером", error: true)
        }
        isLoading = false
    }

    @MainActor
    func addLink(studentId: Int, title: String, url: String, note: String, onUnauthorized: () -> Void) async throws {
        do {
            let created = try await API.addMaterialLink(
                studentId: studentId,
                MaterialLinkInput(title: title, url: url, note: note)
            )
            materials.append(created)
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
        do {
            let created = try await API.addMaterialFile(
                studentId: studentId,
                title: title,
                note: note,
                fileName: fileName,
                mimeType: mimeType,
                fileData: fileData
            )
            materials.append(created)
        } catch is AuthError {
            onUnauthorized()
            throw APIError.message("Unauthorized")
        }
    }

    @MainActor
    func delete(studentId: Int, materialId: Int, onUnauthorized: () -> Void) async {
        do {
            try await API.deleteMaterial(studentId: studentId, materialId: materialId)
            materials.removeAll { $0.id == materialId }
        } catch is AuthError {
            onUnauthorized()
        } catch {
            showToast((error as? LocalizedError)?.errorDescription ?? "Не удалось удалить", error: true)
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
