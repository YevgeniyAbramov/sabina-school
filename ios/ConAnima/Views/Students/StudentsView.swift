import SwiftUI

struct StudentsView: View {
    @Environment(AuthViewModel.self) private var auth
    @Bindable var vm: StudentsViewModel
    @Binding var showAdd: Bool

    private var subtitle: String {
        if !vm.query.trimmingCharacters(in: .whitespaces).isEmpty || vm.filter != .all {
            return "\(vm.filtered.count) из \(vm.students.count)"
        }
        return "\(vm.students.count) \(Formatters.pluralStudents(vm.students.count))"
    }

    private var hasAlertChips: Bool {
        !vm.isLoading && (vm.unpaidCount > 0 || vm.endingSoonCount > 0 || vm.finishedCount > 0)
    }

    private var paymentFilterBinding: Binding<StudentFilter> {
        Binding(
            get: {
                switch vm.filter {
                case .paid, .unpaid: return vm.filter
                default: return .all
                }
            },
            set: { vm.filter = $0 }
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("Загрузка…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    studentsList
                }
            }
            .navigationTitle("Ученики")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: StudentRoute.self) { route in
                switch route {
                case .detail(let id):
                    StudentDetailView(vm: vm, studentId: id)
                case .diary(let id):
                    DiaryDetailView(studentId: id)
                case .piece(let studentId, let pieceId):
                    PieceDetailView(studentId: studentId, pieceId: pieceId)
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAdd = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Добавить ученика")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if let name = auth.teacherName {
                            Text(name)
                            Text("CON ANIMA")
                            Divider()
                        }
                        Button("Выйти", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                            auth.logout()
                        }
                    } label: {
                        Image(systemName: "person.circle")
                    }
                    .accessibilityLabel("Профиль")
                }
            }
            .searchable(text: $vm.query, prompt: Copy.searchPlaceholder)
            .refreshable {
                await vm.refresh(onUnauthorized: auth.handleUnauthorized)
            }
        }
        .task {
            await vm.load(onUnauthorized: auth.handleUnauthorized)
        }
    }

    @ViewBuilder
    private var studentsList: some View {
        List {
            if !vm.students.isEmpty {
                controlsSection
            }

            if vm.filtered.isEmpty {
                Section {
                    ContentUnavailableView {
                        Label(
                            vm.students.isEmpty ? "Пока никого нет" : (vm.query.isEmpty ? Copy.filterEmpty : Copy.searchEmpty),
                            systemImage: vm.students.isEmpty ? "person.badge.plus" : "magnifyingglass"
                        )
                    } description: {
                        Text(
                            vm.students.isEmpty
                                ? "Добавьте первого ученика — уроки и оплаты подтянутся"
                                : (vm.query.isEmpty ? Copy.filterEmptyHint : Copy.searchEmptyHint)
                        )
                    } actions: {
                        Button(vm.students.isEmpty ? "Добавить" : (vm.query.isEmpty ? Copy.filterShowAll : Copy.searchClear)) {
                            if vm.students.isEmpty {
                                showAdd = true
                            } else if !vm.query.isEmpty {
                                vm.query = ""
                            } else {
                                vm.filter = .all
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
                    Text(subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 4, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                    ForEach(vm.filtered) { student in
                        NavigationLink(value: StudentRoute.detail(student.id)) {
                            StudentRowView(student: student)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task {
                                    await vm.delete(student.id, onUnauthorized: auth.handleUnauthorized)
                                }
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
        .background { AppCanvasBackground() }
        .navigationLinkIndicatorVisibility(.hidden)
    }

    @ViewBuilder
    private var controlsSection: some View {
        if hasAlertChips {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if vm.unpaidCount > 0 {
                            AlertChip(
                                value: vm.unpaidCount,
                                label: Copy.unpaid,
                                tone: .bad,
                                active: vm.filter == .unpaid
                            ) {
                                withAnimation { vm.toggleFilter(.unpaid) }
                            }
                        }
                        if vm.endingSoonCount > 0 {
                            AlertChip(
                                value: vm.endingSoonCount,
                                label: Copy.endingSoon,
                                tone: .warn,
                                active: vm.filter == .endingSoon
                            ) {
                                withAnimation { vm.toggleFilter(.endingSoon) }
                            }
                        }
                        if vm.finishedCount > 0 {
                            AlertChip(
                                value: vm.finishedCount,
                                label: Copy.finished,
                                tone: .muted,
                                active: vm.filter == .finished
                            ) {
                                withAnimation { vm.toggleFilter(.finished) }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }

        Section {
            AppSegmentCapsule(
                options: [
                    (value: StudentFilter.all, title: Copy.filterAll),
                    (value: StudentFilter.paid, title: Copy.filterPaid),
                    (value: StudentFilter.unpaid, title: Copy.filterUnpaid),
                ],
                selection: paymentFilterBinding
            )
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if vm.filter == .endingSoon || vm.filter == .finished {
                Button {
                    withAnimation { vm.filter = .all }
                } label: {
                    Label(
                        vm.filter == .endingSoon ? "Фильтр: \(Copy.endingSoon)" : "Фильтр: \(Copy.finished)",
                        systemImage: "xmark.circle.fill"
                    )
                    .font(.subheadline)
                }
                .tint(.secondary)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
    }
}
