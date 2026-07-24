import SwiftUI
import UIKit

/// Diary for one student — list of repertoire pieces (not lesson counts).
struct DiaryDetailView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(StudentsViewModel.self) private var studentsVM
    @State private var vm = DiaryViewModel()

    let studentId: Int

    @State private var showAddPiece = false
    @State private var deleteTarget: StudentPiece?
    @State private var shareURL: URL?
    @State private var isCreatingShare = false

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
        .navigationTitle("Дневник")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await shareDiary() }
                } label: {
                    if isCreatingShare {
                        ProgressView()
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .disabled(isCreatingShare || vm.isLoading)
                .accessibilityLabel("Поделиться дневником")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddPiece = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Новое произведение")
            }
        }
        .sheet(isPresented: $showAddPiece) {
            AddPieceSheet { title, composer in
                try await vm.create(
                    studentId: studentId,
                    title: title,
                    composer: composer,
                    onUnauthorized: auth.handleUnauthorized
                )
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: Binding(
            get: { shareURL.map { ShareURLItem(url: $0) } },
            set: { if $0 == nil { shareURL = nil } }
        )) { item in
            DiaryShareSheet(items: [item.url])
        }
        .alert(
            "Удалить произведение?",
            isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } })
        ) {
            Button("Удалить", role: .destructive) {
                if let target = deleteTarget {
                    Task {
                        await vm.delete(
                            studentId: studentId,
                            pieceId: target.id,
                            onUnauthorized: auth.handleUnauthorized
                        )
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
        .refreshable {
            await vm.load(studentId: studentId, onUnauthorized: auth.handleUnauthorized)
        }
    }

    private func shareDiary() async {
        isCreatingShare = true
        defer { isCreatingShare = false }
        if let url = await vm.createShare(studentId: studentId, onUnauthorized: auth.handleUnauthorized) {
            shareURL = url
        }
    }

    @ViewBuilder
    private func content(_ student: Student) -> some View {
        if vm.isLoading {
            ProgressView("Загрузка…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if vm.pieces.isEmpty {
            emptyState(student)
        } else {
            List {
                Section {
                    Text("Произведения \(student.firstName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 0, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }

                Section {
                    ForEach(vm.pieces) { piece in
                        NavigationLink(value: StudentRoute.piece(studentId: studentId, pieceId: piece.id)) {
                            PieceRowView(piece: piece)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteTarget = piece
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .navigationLinkIndicatorVisibility(.hidden)
        }
    }

    private func emptyState(_ student: Student) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(AppTheme.primary.opacity(0.85))
                .frame(width: 64, height: 64)
                .background(AppTheme.primary.opacity(0.12), in: Circle())

            VStack(spacing: 6) {
                Text("Репертуар пуст")
                    .font(.headline)
                Text("Добавьте произведение — внутри будут ноты, ссылки, готовность и заметки с уроков")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Новое произведение") { showAddPiece = true }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.primary)
                .frame(minHeight: 44)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct PieceRowView: View {
    let piece: StudentPiece

    var body: some View {
        HStack(spacing: 14) {
            ReadinessRing(value: piece.readiness)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(piece.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if !piece.composer.isEmpty {
                    Text(piece.composer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    Text(piece.status.title)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.primary.opacity(0.12), in: Capsule())

                    let mats = piece.materialsCount ?? 0
                    let notes = piece.notesCount ?? 0
                    if mats > 0 || notes > 0 {
                        Text("\(mats) мат. · \(notes) зам.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
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
}

struct ReadinessRing: View {
    let value: Int

    private var progress: Double {
        min(1, max(0, Double(value) / 100))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.primary.opacity(0.12), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AppTheme.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(value)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(AppTheme.primary)
        }
        .accessibilityLabel("Готовность \(value) процентов")
    }
}

struct AddPieceSheet: View {
    let onConfirm: (_ title: String, _ composer: String) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Field?
    @State private var title = ""
    @State private var composer = ""
    @State private var saving = false
    @State private var error: String?

    private enum Field { case title, composer }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && !saving
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(spacing: 0) {
                        field("Название", text: $title, field: .title, placeholder: "ХТК, прелюдия и фуга ре минор")
                        Divider().padding(.leading, 14)
                        field("Композитор", text: $composer, field: .composer, placeholder: "И. С. Бах")
                    }
                    .background(
                        Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )

                    if let error {
                        Text(error)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(AppTheme.danger)
                    }
                }
                .padding(16)
            }
            .background { AppCanvasBackground() }
            .navigationTitle("Новое произведение")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") { Task { await save() } }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func field(_ label: String, text: Binding<String>, field: Field, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .focused($focused, equals: field)
                .textInputAutocapitalization(.sentences)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func save() async {
        focused = nil
        saving = true
        error = nil
        defer { saving = false }
        do {
            try await onConfirm(
                title.trimmingCharacters(in: .whitespacesAndNewlines),
                composer.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            dismiss()
        } catch {
            self.error = (error as? LocalizedError)?.errorDescription ?? "Не удалось сохранить"
        }
    }
}

private struct ShareURLItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct DiaryShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
