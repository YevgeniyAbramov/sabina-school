import SwiftUI
import PhotosUI
import UIKit

/// Sheet-music amber — same fur tint as `PawBurst` / Live Activity, kept as the
/// visual thread for "on-theme" accents across the app.
private let notesAccent = Color(red: 0.93, green: 0.62, blue: 0.32)

struct DiaryDetailView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(StudentsViewModel.self) private var studentsVM
    @State private var vm = DiaryViewModel()

    let studentId: Int

    @State private var showAddLink = false
    @State private var showPhotoPicker = false
    @State private var showFileImporter = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var pendingFile: PendingFile?
    @State private var deleteTarget: StudentMaterial?

    private struct PendingFile: Identifiable {
        let id = UUID()
        let data: Data
        let fileName: String
        let mimeType: String
    }

    private var student: Student? {
        studentsVM.students.first { $0.id == studentId }
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
        } else if vm.materials.isEmpty {
            ContentUnavailableView {
                Label("Дневник пуст", systemImage: "music.note.list")
            } description: {
                Text("Добавьте ссылку на видео или скан нот — прогресс \(student.firstName) соберётся в одном месте")
            }
        } else {
            List {
                Section {
                    ForEach(vm.sorted) { material in
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
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
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
                Circle()
                    .fill(tint.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: symbolName)
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
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
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
