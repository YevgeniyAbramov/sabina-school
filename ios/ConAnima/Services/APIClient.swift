import Foundation

enum AuthError: Error {
    case unauthorized
}

enum APIError: LocalizedError {
    case invalidURL
    case badResponse
    case message(String)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Некорректный адрес API"
        case .badResponse: return "Некорректный ответ сервера"
        case .message(let m): return m
        case .network(let err):
            if let urlErr = err as? URLError {
                switch urlErr.code {
                case .appTransportSecurityRequiresSecureConnection:
                    return "ATS блокирует HTTP. Код −1022"
                case .notConnectedToInternet:
                    return "Нет интернета на телефоне"
                case .timedOut:
                    return "Таймаут. Порт 3000 может резаться LTE"
                case .cannotConnectToHost, .cannotFindHost:
                    return "Не достучаться до сервера (\(urlErr.code.rawValue))"
                default:
                    return "Сеть: \(urlErr.localizedDescription) (\(urlErr.code.rawValue))"
                }
            }
            return "Нет связи: \(err.localizedDescription)"
        }
    }
}

enum AppConfig {
    /// Prod cabinet API (same host as web).
    static let apiBaseURL = URL(string: "http://46.101.212.67:3000/api/v1")!
}

enum AuthStore {
    private static let tokenKey = "auth_token"
    private static let nameKey = "teacher_name"

    static var token: String? {
        get { UserDefaults.standard.string(forKey: tokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: tokenKey) }
    }

    static var teacherName: String? {
        get { UserDefaults.standard.string(forKey: nameKey) }
        set { UserDefaults.standard.set(newValue, forKey: nameKey) }
    }

    static var isAuthenticated: Bool { token != nil && !(token?.isEmpty ?? true) }

    static func set(token: String, teacherName: String?) {
        self.token = token
        if let teacherName { self.teacherName = teacherName }
    }

    static func clear() {
        token = nil
        teacherName = nil
    }
}

final class APIClient {
    static let shared = APIClient()

    var baseURL: URL {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
           let url = URL(string: raw),
           !raw.contains("localhost") {
            return url
        }
        return AppConfig.apiBaseURL
    }

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    private let session: URLSession = {
        let c = URLSessionConfiguration.ephemeral
        c.timeoutIntervalForRequest = 20
        c.timeoutIntervalForResource = 30
        c.waitsForConnectivity = true
        c.tlsMinimumSupportedProtocolVersion = .TLSv12
        // Cleartext HTTP to VPS — ATS must allow via Info.plist
        c.httpAdditionalHeaders = ["Accept": "application/json"]
        return URLSession(configuration: c)
    }()

    func login(username: String, password: String) async throws -> ApiResponse<IgnoredData> {
        let url = baseURL
            .appendingPathComponent("auth")
            .appendingPathComponent("login")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "username": username,
            "password": password,
        ])
        // Login may return HTTP 401 with JSON body — do not treat as session expiry.
        do {
            let (data, response) = try await session.data(for: req)
            if let http = response as? HTTPURLResponse,
               !(200...499).contains(http.statusCode),
               http.statusCode != 401 {
                throw APIError.message("HTTP \(http.statusCode)")
            }
            do {
                return try decoder.decode(ApiResponse<IgnoredData>.self, from: data)
            } catch {
                let preview = String(data: data, encoding: .utf8) ?? "empty"
                throw APIError.message("Ответ не JSON: \(preview.prefix(120))")
            }
        } catch let e as APIError {
            throw e
        } catch {
            throw APIError.network(error)
        }
    }

    /// Root of the server (no `/api/v1`) — used to resolve relative asset URLs
    /// like uploaded material files (`/uploads/materials/...`).
    var fileRootURL: URL {
        let str = baseURL.absoluteString
        let suffix = "/api/v1"
        let stripped = str.hasSuffix(suffix) ? String(str.dropLast(suffix.count)) : str
        return URL(string: stripped) ?? baseURL
    }

    private func buildURL(_ path: String) -> URL? {
        let base = baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let suffix = path.hasPrefix("/") ? path : "/\(path)"
        return URL(string: base + suffix)
    }

    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: (any Encodable)? = nil
    ) async throws -> ApiResponse<T> {
        guard let url = buildURL(path) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthStore.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }
        return try await send(req)
    }

    /// Multipart upload (e.g. sheet music scan) — separate from `request` because
    /// the body needs raw `multipart/form-data` framing instead of JSON encoding.
    func uploadMultipart<T: Decodable>(
        _ path: String,
        fields: [String: String],
        fileField: String,
        fileName: String,
        mimeType: String,
        fileData: Data
    ) async throws -> ApiResponse<T> {
        guard let url = buildURL(path) else {
            throw APIError.invalidURL
        }
        let boundary = "Boundary-\(UUID().uuidString)"
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token = AuthStore.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        for (name, value) in fields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append(
            "Content-Disposition: form-data; name=\"\(fileField)\"; filename=\"\(fileName)\"\r\n"
                .data(using: .utf8)!
        )
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        return try await send(req)
    }

    private func send<T: Decodable>(_ req: URLRequest) async throws -> ApiResponse<T> {
        do {
            let (data, response) = try await session.data(for: req)
            if let http = response as? HTTPURLResponse, http.statusCode == 401 {
                AuthStore.clear()
                throw AuthError.unauthorized
            }
            return try decoder.decode(ApiResponse<T>.self, from: data)
        } catch let e as AuthError {
            throw e
        } catch let e as DecodingError {
            throw APIError.message("Ошибка разбора ответа: \(e.localizedDescription)")
        } catch {
            throw APIError.network(error)
        }
    }
}

private struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    init(_ value: any Encodable) {
        encodeFunc = value.encode
    }
    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}

enum API {
    static func students() async throws -> [Student] {
        let r: ApiResponse<[Student]> = try await APIClient.shared.request("/students")
        guard r.status else { throw APIError.message(r.message ?? "Не удалось загрузить учеников") }
        return r.data ?? []
    }

    static func student(_ id: Int) async throws -> Student {
        let r: ApiResponse<Student> = try await APIClient.shared.request("/student/\(id)")
        guard r.status, let s = r.data else {
            throw APIError.message(r.message ?? "Ученик не найден")
        }
        return s
    }

    static func createStudent(_ input: StudentInput) async throws {
        let r: ApiResponse<IgnoredData> = try await APIClient.shared.request(
            "/students", method: "POST", body: input
        )
        guard r.status else { throw APIError.message(r.message ?? "Не удалось добавить") }
    }

    static func updateStudent(_ id: Int, _ input: StudentInput) async throws {
        let r: ApiResponse<IgnoredData> = try await APIClient.shared.request(
            "/student/\(id)", method: "PUT", body: input
        )
        guard r.status else { throw APIError.message(r.message ?? "Не удалось сохранить") }
    }

    static func deleteStudent(_ id: Int) async throws {
        let r: ApiResponse<IgnoredData> = try await APIClient.shared.request(
            "/student/\(id)", method: "DELETE"
        )
        guard r.status else { throw APIError.message(r.message ?? "Не удалось удалить") }
    }

    static func completeLesson(_ id: Int) async throws {
        let r: ApiResponse<IgnoredData> = try await APIClient.shared.request(
            "/student/\(id)/complete-lesson", method: "POST"
        )
        guard r.status else { throw APIError.message(r.message ?? "Ошибка") }
    }

    static func markMissed(_ id: Int) async throws {
        let r: ApiResponse<IgnoredData> = try await APIClient.shared.request(
            "/student/\(id)/mark-missed", method: "POST"
        )
        guard r.status else { throw APIError.message(r.message ?? "Ошибка") }
    }

    static func schedule(studentId: Int) async throws -> [ScheduleSlot] {
        let r: ApiResponse<[ScheduleSlot]> = try await APIClient.shared.request(
            "/student/\(studentId)/schedule"
        )
        guard r.status else { throw APIError.message(r.message ?? "Не удалось загрузить расписание") }
        return r.data ?? []
    }

    static func replaceSchedule(studentId: Int, slots: [ScheduleSlotInput]) async throws {
        struct Body: Encodable { let slots: [ScheduleSlotInput] }
        let r: ApiResponse<IgnoredData> = try await APIClient.shared.request(
            "/student/\(studentId)/schedule", method: "PUT", body: Body(slots: slots)
        )
        guard r.status else { throw APIError.message(r.message ?? "Не удалось сохранить") }
    }

    static func schedule(day: Int) async throws -> [ScheduleSlot] {
        let r: ApiResponse<[ScheduleSlot]> = try await APIClient.shared.request(
            "/schedule?day=\(day)"
        )
        guard r.status else { throw APIError.message(r.message ?? "Не удалось загрузить") }
        return r.data ?? []
    }

    static func monthlySummary(year: Int, month: Int) async throws -> MonthlySummary? {
        let r: ApiResponse<MonthlySummary> = try await APIClient.shared.request(
            "/monthly-summary?year=\(year)&month=\(month)"
        )
        return r.status ? r.data : nil
    }

    static func activity(kind: String = "all") async throws -> [Activity] {
        let r: ApiResponse<[Activity]> = try await APIClient.shared.request(
            "/activity?kind=\(kind)"
        )
        guard r.status else { throw APIError.message(r.message ?? "Не удалось загрузить историю") }
        return r.data ?? []
    }

    static func materials(studentId: Int) async throws -> [StudentMaterial] {
        let r: ApiResponse<[StudentMaterial]> = try await APIClient.shared.request(
            "/student/\(studentId)/materials"
        )
        guard r.status else { throw APIError.message(r.message ?? "Не удалось загрузить дневник") }
        return r.data ?? []
    }

    static func addMaterialLink(studentId: Int, _ input: MaterialLinkInput) async throws -> StudentMaterial {
        let r: ApiResponse<StudentMaterial> = try await APIClient.shared.request(
            "/student/\(studentId)/materials/link", method: "POST", body: input
        )
        guard r.status, let m = r.data else {
            throw APIError.message(r.message ?? "Не удалось добавить ссылку")
        }
        return m
    }

    static func addMaterialFile(
        studentId: Int,
        title: String,
        note: String,
        fileName: String,
        mimeType: String,
        fileData: Data
    ) async throws -> StudentMaterial {
        let r: ApiResponse<StudentMaterial> = try await APIClient.shared.uploadMultipart(
            "/student/\(studentId)/materials/file",
            fields: ["title": title, "note": note],
            fileField: "file",
            fileName: fileName,
            mimeType: mimeType,
            fileData: fileData
        )
        guard r.status, let m = r.data else {
            throw APIError.message(r.message ?? "Не удалось загрузить файл")
        }
        return m
    }

    static func updateMaterial(studentId: Int, materialId: Int, _ input: MaterialUpdateInput) async throws -> StudentMaterial {
        let r: ApiResponse<StudentMaterial> = try await APIClient.shared.request(
            "/student/\(studentId)/materials/\(materialId)", method: "PUT", body: input
        )
        guard r.status, let m = r.data else {
            throw APIError.message(r.message ?? "Не удалось сохранить")
        }
        return m
    }

    static func deleteMaterial(studentId: Int, materialId: Int) async throws {
        let r: ApiResponse<IgnoredData> = try await APIClient.shared.request(
            "/student/\(studentId)/materials/\(materialId)", method: "DELETE"
        )
        guard r.status else { throw APIError.message(r.message ?? "Не удалось удалить") }
    }
}

extension StudentMaterial {
    /// Absolute URL to open — links are already absolute; uploaded files are
    /// server-relative paths resolved against the API host.
    var resolvedURL: URL? {
        URL(string: url, relativeTo: APIClient.shared.fileRootURL)?.absoluteURL
    }
}
