import SwiftUI
import PhotosUI
import UIKit

/// Sheet-music amber — same fur tint as `PawBurst` / Live Activity.
private let notesAccent = Color(red: 0.93, green: 0.62, blue: 0.32)

struct DiaryDetailView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(StudentsViewModel.self) private var studentsVM
    @State private var vm = DiaryViewModel()

    let studentId: Int

    @State private var filter: MaterialFilter = .all
    @State private var showAddLink = false
    @State private var showPhotoPicker = false
    @State private var showFileImporter = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var pendingFile: PendingFile?
    @State private var deleteTarget: StudentMaterial?

    private enum MaterialFilter: Hashable {
        case all, notes, links
    }

    private struct PendingFile: Identifiable {
        let id = UUID()
        let data: Data
        let fileName: String
        let mimeType: String
    }

    private var student: Student? {
        studentsVM.students.first { $0.id == studentId }
    }

    private var notes: [StudentMaterial] {
        vm.sorted.filter { $0.kind == .file }
    }

    private var links: [StudentMaterial] {
        vm.sorted.filter { $0.kind == .link }
    }

    private var filteredMaterials: [StudentMaterial] {
        switch filter {
        case .all: return vm.sorted
        case .notes: return notes
        case .links: return links
        }
    }

    private var shareText: String {
        guard let student else { return "" }
        var lines: [String] = [
            "CON ANIMA — \(student.fullName)",
            "",
            "Уроков пройдено: \(student.completedLessons) из \(student.totalLessons)",
            "Пропусков: \(student.missedClasses)",
            "Осталось: \(student.remainingLessons)",
        ]
        if !notes.isEmpty {
            lines.append("")
            lines.append("Ноты:")
            for m in notes {
                lines.append("• \(m.title)")
            }
        }
        if !links.isEmpty {
            lines.append("")
            lines.append("Ссылки:")
            for m in links {
                let url = m.url.isEmpty ? "" : " — \(m.url)"
                lines.append("• \(m.title)\(url)")
            }
        }
        return lines.joined(separator: "\n")
    }

    var body: some View {
        Group {
            if let student {
                content(student)
            } else {
                ContentUnavailableView("Ученик не найден", systemImage: "person.slash")
            }
        }
        .background { AppCanvasBackground() }
        .navigationTitle(student?.fullName ?? "Дневник")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { showAddLink = true } label: {
                        Label("Ссылка (YouTube и т.п.)", systemImage: "link")
                    }
                    Button { showPhotoPicker = true } label: {
                        Label("Фото нот", systemImage: "photo")
                    }
                    Button { showFileImporter = true } label: {
                        Label("Файл (PDF)", systemImage: "doc")
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Добавить материал")
            }
            ToolbarItem(placement: .topBarTrailing) {
                if student != nil, !vm.isLoading {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Поделиться статистикой")
                }
            }
        }
        .sheet(isPresented: $showAddLink) {
            AddLinkSheet { title, url, note in
                try await vm.addLink(
                    studentId: studentId, title: title, url: url, note: note,
                    onUnauthorized: auth.handleUnauthorized
                )
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $pendingFile) { pending in
            AddFileDetailsSheet(fileName: pending.fileName) { title, note in
                try await vm.addFile(
                    studentId: studentId, title: title, note: note,
                    fileName: pending.fileName, mimeType: pending.mimeType, fileData: pending.data,
                    onUnauthorized: auth.handleUnauthorized
                )
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoPickerItem, matching: .images)
        .onChange(of: photoPickerItem) { _, item in
            Task { await handlePhotoPick(item) }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf, .png, .jpeg, .heic],
            onCompletion: handleFileImport
        )
        .alert(
            "Удалить материал?",
            isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } })
        ) {
            Button("Удалить", role: .destructive) {
                if let target = deleteTarget {
                    Task {
                        await vm.delete(studentId: studentId, materialId: target.id, onUnauthorized: auth.handleUnauthorized)
                    }
                }
                deleteTarget = nil
            }
            Button("Отмена", role: .cancel) { deleteTarget = nil }
        } message: {
            if let deleteTarget { Text(deleteTarget.title) }
        }
        .overlay(alignment: .top) {
            if let toast = vm.toast {
                ToastBanner(message: toast, isError: vm.toastIsError)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                            withAnimation { vm.toast = nil }
                        }
                    }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: vm.toast)
        .task {
            await vm.load(studentId: studentId, onUnauthorized: auth.handleUnauthorized)
        }
    }

    @ViewBuilder
    private func content(_ student: Student) -> some View {
        if vm.isLoading {
            ProgressView("Загрузка…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                Section {
                    statsCard(student)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }

                Section {
                    AppSegmentCapsule(
                        options: [
                            (value: MaterialFilter.all, title: "Все"),
                            (value: MaterialFilter.notes, title: "Ноты"),
                            (value: MaterialFilter.links, title: "Ссылки"),
                        ],
                        selection: $filter
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }

                if filteredMaterials.isEmpty {
                    Section {
                        emptyCard
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                } else {
                    Section {
                        ForEach(filteredMaterials) { material in
                            MaterialRowView(material: material)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if let url = material.resolvedURL {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteTarget = material
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func statsCard(_ student: Student) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Прогресс \(student.firstName)")
                    .font(.headline)
                Spacer(minLength: 8)
                Text("\(Int(student.progress * 100))%")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: student.progress)
                .tint(AppTheme.primary)

            HStack(spacing: 8) {
                diaryMetric(title: "Уроки", value: "\(student.completedLessons)", hint: "из \(student.totalLessons)")
                diaryMetric(title: "Пропуски", value: "\(student.missedClasses)", hint: nil)
                diaryMetric(title: "Ноты", value: "\(notes.count)", hint: nil, tint: notesAccent)
                diaryMetric(title: "Ссылки", value: "\(links.count)", hint: nil)
            }
        }
        .padding(16)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func diaryMetric(title: String, value: String, hint: String?, tint: Color = AppTheme.primary) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let hint {
                Text(hint)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            } else {
                Text(" ")
                    .font(.caption2)
                    .hidden()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background(
            Color(.systemBackground).opacity(0.72),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }

    @ViewBuilder
    private var emptyCard: some View {
        let (title, symbol, hint, actionTitle, action): (String, String, String, String, () -> Void) = {
            switch filter {
            case .all:
                return (
                    "Дневник пока пуст",
                    "music.note.list",
                    "Добавьте ноты или ссылку — прогресс соберётся здесь",
                    "Добавить ссылку",
                    { showAddLink = true }
                )
            case .notes:
                return (
                    "Нет нот",
                    "doc.richtext",
                    "Сфотографируйте партитуру или загрузите PDF",
                    "Добавить ноты",
                    { showPhotoPicker = true }
                )
            case .links:
                return (
                    "Нет ссылок",
                    "link",
                    "YouTube, записи уроков и полезные материалы",
                    "Добавить ссылку",
                    { showAddLink = true }
                )
            }
        }()

        VStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(AppTheme.primary.opacity(0.85))
                .frame(width: 64, height: 64)
                .background(AppTheme.primary.opacity(0.12), in: Circle())

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                Text(hint)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(actionTitle, action: action)
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)
                .frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func handlePhotoPick(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        defer { photoPickerItem = nil }
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            vm.toastIsError = true
            vm.toast = "Не удалось загрузить фото"
            return
        }
        if let uiImage = UIImage(data: data), let jpeg = uiImage.jpegData(compressionQuality: 0.85) {
            pendingFile = PendingFile(data: jpeg, fileName: "Скан.jpg", mimeType: "image/jpeg")
        } else {
            pendingFile = PendingFile(data: data, fileName: "Скан.jpg", mimeType: "image/jpeg")
        }
    }

    private func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                let data = try Data(contentsOf: url)
                pendingFile = PendingFile(
                    data: data,
                    fileName: url.lastPathComponent,
                    mimeType: mimeType(forExtension: url.pathExtension)
                )
            } catch {
                vm.toastIsError = true
                vm.toast = "Не удалось прочитать файл"
            }
        case .failure:
            break
        }
    }

    private func mimeType(forExtension ext: String) -> String {
        switch ext.lowercased() {
        case "pdf": return "application/pdf"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "heic": return "image/heic"
        default: return "application/octet-stream"
        }
    }
}

private struct MaterialRowView: View {
    let material: StudentMaterial

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: symbolName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(tint)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(material.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if !material.note.isEmpty {
                    Text(material.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Color(.systemBackground),
            in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        .accessibilityElement(children: .combine)
    }

    private var symbolName: String {
        switch material.kind {
        case .link: return "play.rectangle.fill"
        case .file: return material.isImage ? "photo.fill" : "doc.richtext.fill"
        }
    }

    private var tint: Color {
        switch material.kind {
        case .link: return AppTheme.primary
        case .file: return notesAccent
        }
    }

    private var subtitle: String {
        let date = Formatters.dayLabel(material.createdAt)
        switch material.kind {
        case .link:
            let host = material.resolvedURL?.host?.replacingOccurrences(of: "www.", with: "") ?? "Ссылка"
            return "\(host) · \(date)"
        case .file:
            return "\(material.fileExtension.uppercased()) · \(date)"
        }
    }
}
