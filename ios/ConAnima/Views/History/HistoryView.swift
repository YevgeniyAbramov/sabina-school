import SwiftUI

struct HistoryView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var vm = HistoryViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("Загрузка…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.groups.isEmpty {
                    ContentUnavailableView(
                        "Пока пусто",
                        systemImage: "clock",
                        description: Text("Здесь появятся проведённые уроки, пропуски и оплаты.")
                    )
                } else {
                    List {
                        ForEach(vm.groups) { group in
                            Section {
                                Text(group.label)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 4, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)

                                ForEach(group.items) { item in
                                    ActivityRow(
                                        item: item,
                                        shortTime: group.label == "Сегодня" || group.label == "Вчера"
                                    )
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background { AppCanvasBackground() }
            .navigationTitle("История")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Text(auth.teacherName ?? "Преподаватель")
                        Divider()
                        Button("Выйти", role: .destructive) { auth.logout() }
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
            .refreshable {
                await vm.load(onUnauthorized: auth.handleUnauthorized)
            }
        }
        .task {
            await vm.load(onUnauthorized: auth.handleUnauthorized)
        }
    }
}

struct ActivityRow: View {
    let item: Activity
    var shortTime = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(iconBg, in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    Text(Formatters.timeLabel(item.createdAt, short: shortTime))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 0) {
                    Text(item.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    if let amount = item.amount, amount > 0 {
                        Text(" · \(Formatters.formatNumber(amount)) ₸")
                            .font(.footnote.weight(.medium).monospacedDigit())
                    }
                }
            }
        }
        .padding(14)
        .background(
            Color(.systemBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private var icon: String {
        switch item.kind {
        case .lesson: return "checkmark.circle.fill"
        case .missed: return "person.slash.fill"
        case .payment: return "yensign.circle.fill"
        case .renew: return "shippingbox.fill"
        case .student: return "person.badge.plus.fill"
        }
    }

    private var iconBg: Color {
        switch item.kind {
        case .lesson: return AppTheme.primary
        case .missed: return Color.primary.opacity(0.75)
        case .payment: return AppTheme.warning
        case .renew: return Color(red: 0.18, green: 0.44, blue: 0.37)
        case .student: return Color(red: 0.29, green: 0.44, blue: 0.65)
        }
    }
}
