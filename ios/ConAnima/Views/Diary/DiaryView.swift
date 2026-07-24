import SwiftUI

/// Top-level "Дневник" tab — pick a student to open their program (sheet music,
/// links, progress notes). Reuses the shared `StudentsViewModel` already loaded
/// by the Students tab instead of fetching the roster a second time.
struct DiaryView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(StudentsViewModel.self) private var studentsVM
    @State private var query = ""

    private var filtered: [Student] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return studentsVM.students }
        return studentsVM.students.filter {
            [$0.lastName, $0.firstName, $0.middleName ?? ""]
                .joined(separator: " ")
                .lowercased()
                .contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if studentsVM.isLoading {
                    ProgressView("Загрузка…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if studentsVM.students.isEmpty {
                    ContentUnavailableView {
                        Label("Пока никого нет", systemImage: "music.note.list")
                    } description: {
                        Text("Добавьте ученика на вкладке «Ученики» — дневник появится здесь")
                    }
                } else {
                    list
                }
            }
            .navigationTitle("Дневник")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: DiaryRoute.self) { route in
                switch route {
                case .student(let id):
                    DiaryDetailView(studentId: id)
                }
            }
            .searchable(text: $query, prompt: Copy.searchPlaceholder)
            .refreshable {
                await studentsVM.refresh(onUnauthorized: auth.handleUnauthorized)
            }
        }
    }

    @ViewBuilder
    private var list: some View {
        if filtered.isEmpty {
            List {
                Section {
                    ContentUnavailableView(Copy.searchEmpty, systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background { AppCanvasBackground() }
        } else {
            List {
                Section {
                    ForEach(filtered) { student in
                        NavigationLink(value: DiaryRoute.student(student.id)) {
                            DiaryStudentRow(student: student)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background { AppCanvasBackground() }
            .navigationLinkIndicatorVisibility(.hidden)
        }
    }
}

private struct DiaryStudentRow: View {
    let student: Student

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.12))
                    .frame(width: 40, height: 40)
                Text(initials)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(student.fullName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text("Ноты, ссылки, прогресс")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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

    private var initials: String {
        let parts = [student.firstName, student.lastName]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let chars = parts.prefix(2).compactMap { $0.first.map(String.init) }
        return chars.joined().uppercased()
    }
}
