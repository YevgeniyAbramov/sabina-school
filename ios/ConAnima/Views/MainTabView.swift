import SwiftUI

enum MainTab: Hashable {
    case students, history, journal, summary
}

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var studentsVM = StudentsViewModel()
    @State private var selected: MainTab = .students
    @State private var showAdd = false

    var body: some View {
        TabView(selection: $selected) {
            StudentsView(vm: studentsVM, showAdd: $showAdd)
                .tabItem { Label("Ученики", systemImage: "person.3.fill") }
                .tag(MainTab.students)

            HistoryView()
                .tabItem { Label("История", systemImage: "clock.fill") }
                .tag(MainTab.history)

            JournalView()
                .tabItem { Label("Журнал", systemImage: "book.pages.fill") }
                .tag(MainTab.journal)

            SummaryView()
                .tabItem { Label("Итоги", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(MainTab.summary)
        }
        .tint(AppTheme.primary)
        .sheet(isPresented: $showAdd) {
            StudentFormSheet(mode: .add) { input in
                try await studentsVM.add(input, onUnauthorized: auth.handleUnauthorized)
            }
            .presentationDragIndicator(.visible)
        }
        .overlay(alignment: .top) {
            if let toast = studentsVM.toast {
                ToastBanner(message: toast, isError: studentsVM.toastIsError)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                            withAnimation { studentsVM.toast = nil }
                        }
                    }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: studentsVM.toast)
        .environment(studentsVM)
    }
}

struct ToastBanner: View {
    let message: String
    var isError = false

    var body: some View {
        Text(message)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isError ? AppTheme.danger : AppTheme.success, in: Capsule())
            .shadow(radius: 8, y: 4)
    }
}
