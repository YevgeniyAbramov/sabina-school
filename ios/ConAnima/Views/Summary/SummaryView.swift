import SwiftUI
import Charts

/// Full tab screen — same chrome as Students / Journal (large title, scroll away content).
struct SummaryView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(StudentsViewModel.self) private var studentsVM

    @State private var amount = 0
    @State private var monthly: [Int] = Array(repeating: 0, count: 12)
    @State private var loading = true

    private var students: [Student] { studentsVM.students }

    private var now: Date { .now }
    private var month: Int { Calendar.current.component(.month, from: now) }
    private var year: Int { Calendar.current.component(.year, from: now) }

    private var stats: (
        paid: Int, unpaid: Int, done: Int, left: Int, missed: Int, lowStock: Int
    ) {
        let paid = students.filter(\.isPaid).count
        var done = 0, left = 0, missed = 0
        for s in students {
            let total = max(0, s.totalLessons)
            let remaining = min(total, max(0, s.remainingLessons))
            var m = max(0, s.missedClasses)
            if total > 0 && m > total { m = 0 }
            done += max(0, total - remaining)
            left += remaining
            missed += m
        }
        return (
            paid,
            students.count - paid,
            done,
            left,
            missed,
            students.filter { $0.remainingLessons == 1 }.count
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if loading && monthly.allSatisfy({ $0 == 0 }) && amount == 0 {
                    ProgressView("Загрузка…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    summaryList
                }
            }
            .background { AppCanvasBackground() }
            .navigationTitle("Итоги")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { await load() }
            .task { await load() }
        }
    }

    private var summaryList: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Выручка · \(MonthNames.full[month - 1]) \(year)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(loading ? "…" : "\(Formatters.formatNumber(amount)) ₸")
                        .font(.largeTitle.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    Color(.systemBackground),
                    in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                )
                .shadow(color: .black.opacity(0.05), radius: 10, y: 3)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section {
                paidUnpaidCard
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    kpi("Пройдено", "\(stats.done)", AppTheme.primary)
                    kpi("Осталось", "\(stats.left)", AppTheme.warning)
                    kpi("Пропуски", "\(stats.missed)", .secondary)
                    kpi(Copy.endingSoon, "\(stats.lowStock)", AppTheme.warning)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Год \(year)")
                        .font(.headline)
                    Chart {
                        ForEach(Array(MonthNames.short.enumerated()), id: \.offset) { i, name in
                            LineMark(
                                x: .value("Месяц", name),
                                y: .value("Сумма", monthly[i])
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(AppTheme.primary)
                            AreaMark(
                                x: .value("Месяц", name),
                                y: .value("Сумма", monthly[i])
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(AppTheme.primary.opacity(0.12))
                        }
                    }
                    .frame(height: 180)
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisValueLabel().font(.caption2)
                        }
                    }
                    .chartYAxis(.hidden)
                }
                .padding(16)
                .background(
                    Color(.systemBackground),
                    in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                )
                .shadow(color: .black.opacity(0.05), radius: 10, y: 3)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 16, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background { AppCanvasBackground() }
    }

    /// Оплачено / Не оплачено sum to the full roster — grouped as one card, like `metricsStrip`.
    private var paidUnpaidCard: some View {
        HStack(spacing: 8) {
            kpi("Оплачено", "\(stats.paid)", AppTheme.success)
            kpi("Не оплачено", "\(stats.unpaid)", AppTheme.danger)
        }
    }

    private func kpi(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.semibold).monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            Color(.systemBackground),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func load() async {
        loading = true
        defer { loading = false }
        do {
            if let s = try await API.monthlySummary(year: year, month: month) {
                amount = s.totalAmount
            } else {
                amount = 0
            }
            var yearData = Array(repeating: 0, count: 12)
            for m in 1...12 {
                if let s = try? await API.monthlySummary(year: year, month: m) {
                    yearData[m - 1] = s.totalAmount
                }
            }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                monthly = yearData
            }
        } catch is AuthError {
            auth.handleUnauthorized()
        } catch {
            amount = 0
        }
    }
}
