import SwiftUI
import PhotosUI
import UIKit

private let notesAccent = Color(red: 0.93, green: 0.62, blue: 0.32)

struct PieceDetailView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(StudentsViewModel.self) private var studentsVM
    @State private var vm = PieceDetailViewModel()

    let studentId: Int
    let pieceId: Int

    @State private var readiness: Double = 0
    @State private var status: PieceStatus = .learning
    @State private var filter: MaterialFilter = .all
    @State private var showAddLink = false
    @State private var showAddNote = false
    @State private var showPhotoPicker = false
    @State private var showFileImporter = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var pendingFile: PendingFile?
    @State private var deleteMaterial: StudentMaterial?
    @State private var deleteNote: StudentPieceNote?
    @State private var readinessSaveTask: Task<Void, Never>?
    @State private var isHydrating = true

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

    private var filteredMaterials: [StudentMaterial] {
        guard let detail = vm.detail else { return [] }
        switch filter {
        case .all: return detail.materials
        case .notes: return vm.notes
        case .links: return vm.links
        }
    }

    var body: some View {
        Group {
            if vm.isLoading && vm.detail == nil {
                ProgressView("Загрузка…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let detail = vm.detail {
                listContent(detail)
            } else {
                ContentUnavailableView("Произведение не найдено", systemImage: "music.note")
            }
        }
        .background { AppCanvasBackground() }
        .navigationTitle(vm.detail?.title ?? "Произведение")
        .navigationBarTitleDisplayMode(.inline)
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
        .sheet(isPresented: $showAddNote) {
            AddLessonNoteSheet { body in
                try await vm.addNote(
                    studentId: studentId, body: body,
                    onUnauthorized: auth.handleUnauthorized
                )
            }
            .presentationDetents([.medium])
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
            isPresented: Binding(get: { deleteMaterial != nil }, set: { if !$0 { deleteMaterial = nil } })
        ) {
            Button("Удалить", role: .destructive) {
                if let target = deleteMaterial {
                    Task {
                        await vm.deleteMaterial(
                            studentId: studentId, materialId: target.id,
                            onUnauthorized: auth.handleUnauthorized
                        )
                    }
                }
                deleteMaterial = nil
            }
            Button("Отмена", role: .cancel) { deleteMaterial = nil }
        } message: {
            if let deleteMaterial { Text(deleteMaterial.title) }
        }
        .alert(
            "Удалить заметку?",
            isPresented: Binding(get: { deleteNote != nil }, set: { if !$0 { deleteNote = nil } })
        ) {
            Button("Удалить", role: .destructive) {
                if let target = deleteNote {
                    Task {
                        await vm.deleteNote(
                            studentId: studentId, noteId: target.id,
                            onUnauthorized: auth.handleUnauthorized
                        )
                    }
                }
                deleteNote = nil
            }
            Button("Отмена", role: .cancel) { deleteNote = nil }
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if vm.detail != nil {
                addBar
            }
        }
        .task {
            isHydrating = true
            await vm.load(studentId: studentId, pieceId: pieceId, onUnauthorized: auth.handleUnauthorized)
            if let detail = vm.detail {
                readiness = Double(detail.readiness)
                status = detail.status
            }
            // Let SwiftUI settle before treating slider/status changes as user edits.
            try? await Task.sleep(for: .milliseconds(100))
            isHydrating = false
        }
    }

    private var addBar: some View {
        HStack(spacing: 8) {
            addChip(title: "Заметка", systemImage: "text.badge.plus") { showAddNote = true }
            addChip(title: "Ссылка", systemImage: "link") { showAddLink = true }
            addChip(title: "Фото", systemImage: "photo") { showPhotoPicker = true }
            addChip(title: "PDF", systemImage: "doc") { showFileImporter = true }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private func addChip(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                Text(title)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(AppTheme.primary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func listContent(_ detail: PieceDetail) -> some View {
        List {
            Section {
                readinessCard(detail)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            Section {
                statusPicker
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            Section {
                headerRow(title: "Заметки с уроков")
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                if detail.notes.isEmpty {
                    emptyInline(
                        title: "Пока без заметок",
                        hint: "Например: разобрали экспозицию, темп ♩=72"
                    )
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(detail.notes) { note in
                        noteRow(note)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) { deleteNote = note } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                    }
                }
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

                if filteredMaterials.isEmpty {
                    emptyInline(
                        title: emptyMaterialsTitle,
                        hint: emptyMaterialsHint
                    )
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 16, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                } else {
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
                                Button(role: .destructive) { deleteMaterial = material } label: {
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

    private var emptyMaterialsTitle: String {
        switch filter {
        case .all: return "Нет материалов"
        case .notes: return "Нет нот"
        case .links: return "Нет ссылок"
        }
    }

    private var emptyMaterialsHint: String {
        switch filter {
        case .all: return "Добавьте скан партитуры или ссылку на запись"
        case .notes: return "Сфотографируйте ноты или загрузите PDF"
        case .links: return "YouTube, эталонные исполнения"
        }
    }

    private func readinessCard(_ detail: PieceDetail) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ReadinessRing(value: Int(readiness.rounded()))
                    .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 4) {
                    Text(detail.title)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    if !detail.composer.isEmpty {
                        Text(detail.composer)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if let student {
                        Text(student.fullName)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Готовность")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text("\(Int(readiness.rounded()))%")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(AppTheme.primary)
                }
                Slider(value: $readiness, in: 0...100, step: 5)
                    .tint(AppTheme.primary)
                    .onChange(of: readiness) { _, newValue in
                        guard !isHydrating else { return }
                        readinessSaveTask?.cancel()
                        let value = Int(newValue.rounded())
                        readinessSaveTask = Task {
                            do {
                                try await Task.sleep(for: .milliseconds(450))
                            } catch {
                                return
                            }
                            guard !Task.isCancelled else { return }
                            // Unstructured task: newer slides cancel only the wait, not an in-flight PUT.
                            Task { await persistMeta(readiness: value) }
                        }
                    }
            }
        }
        .padding(16)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private var statusPicker: some View {
        AppSegmentCapsule(
            options: PieceStatus.allCases.map { (value: $0, title: $0.title) },
            selection: $status
        )
        .onChange(of: status) { _, newValue in
            guard !isHydrating else { return }
            Task { await persistMeta(status: newValue) }
        }
    }

    private func headerRow(title: String) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func noteRow(_ note: StudentPieceNote) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(note.body)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Text(Formatters.dayLabel(note.createdAt))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            Color(.systemBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func emptyInline(title: String, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(hint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            Color(.secondarySystemGroupedBackground).opacity(0.7),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    private func persistMeta(readiness newReadiness: Int? = nil, status newStatus: PieceStatus? = nil) async {
        guard let detail = vm.detail else { return }
        await vm.saveMeta(
            studentId: studentId,
            title: detail.title,
            composer: detail.composer,
            readiness: newReadiness ?? Int(readiness.rounded()),
            status: newStatus ?? status,
            onUnauthorized: auth.handleUnauthorized
        )
    }
}

// MARK: - Helpers

private extension PieceDetailView {
    func handlePhotoPick(_ item: PhotosPickerItem?) async {
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

    func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                let data = try Data(contentsOf: url)
                let ext = url.pathExtension.lowercased()
                let mime: String = {
                    switch ext {
                    case "pdf": return "application/pdf"
                    case "png": return "image/png"
                    case "jpg", "jpeg": return "image/jpeg"
                    case "heic": return "image/heic"
                    default: return "application/octet-stream"
                    }
                }()
                pendingFile = PendingFile(data: data, fileName: url.lastPathComponent, mimeType: mime)
            } catch {
                vm.toastIsError = true
                vm.toast = "Не удалось прочитать файл"
            }
        case .failure:
            break
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

struct AddLessonNoteSheet: View {
    let onConfirm: (_ body: String) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool
    @State private var bodyText = ""
    @State private var saving = false
    @State private var error: String?

    private var canSave: Bool {
        !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !saving
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Что сделали на уроке")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                TextEditor(text: $bodyText)
                    .focused($focused)
                    .frame(minHeight: 140)
                    .padding(12)
                    .background(
                        Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                if let error {
                    Text(error)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(AppTheme.danger)
                }
                Spacer()
            }
            .padding(16)
            .background { AppCanvasBackground() }
            .navigationTitle("Заметка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { Task { await save() } }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .onAppear { focused = true }
        }
    }

    private func save() async {
        focused = false
        saving = true
        error = nil
        defer { saving = false }
        do {
            try await onConfirm(bodyText.trimmingCharacters(in: .whitespacesAndNewlines))
            dismiss()
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? "Не удалось сохранить"
        }
    }
}
