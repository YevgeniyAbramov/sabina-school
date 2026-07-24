import Foundation

enum Copy {
    static let paid = "Оплачено"
    static let unpaid = "Не оплачено"
    static let endingSoon = "Заканчивается"
    static let finished = "Закончился"
    static let filterAll = "Все"
    static let filterPaid = "Оплачено"
    static let filterUnpaid = "Не оплачено"
    static let filterEmpty = "По этому фильтру пусто"
    static let filterEmptyHint = "Сбросьте фильтр или добавьте нового"
    static let filterShowAll = "Показать всех"
    static let searchPlaceholder = "Поиск по имени…"
    static let searchEmpty = "Никого не нашли"
    static let searchEmptyHint = "Попробуйте другое имя или сбросьте поиск"
    static let searchClear = "Сбросить поиск"
}

enum DayNames {
    static let full = [
        "Воскресенье", "Понедельник", "Вторник", "Среда",
        "Четверг", "Пятница", "Суббота",
    ]
    static let short = ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"]
    /// Mon→Sun order for UI
    static let weekOrder = [1, 2, 3, 4, 5, 6, 0]
}

enum MonthNames {
    static let full = [
        "Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
        "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь",
    ]
    static let short = [
        "Янв", "Фев", "Мар", "Апр", "Май", "Июн",
        "Июл", "Авг", "Сен", "Окт", "Ноя", "Дек",
    ]
}

enum Formatters {
    static func normalizeTime(_ slot: String) -> String {
        let parts = slot.split(separator: ":")
        let h = parts.first.map(String.init) ?? "00"
        let m = parts.dropFirst().first.map(String.init) ?? "00"
        return String(format: "%02d:%02d", Int(h) ?? 0, Int(m) ?? 0)
    }

    static func formatTime(_ slot: String) -> String {
        let parts = slot.split(separator: ":").prefix(2)
        return parts.joined(separator: ":")
    }

    static func formatNumber(_ num: Int) -> String {
        let s = String(num)
        var result = ""
        for (i, ch) in s.reversed().enumerated() {
            if i > 0 && i % 3 == 0 { result.append(" ") }
            result.append(ch)
        }
        return String(result.reversed())
    }

    static func pluralStudents(_ n: Int) -> String {
        let mod10 = n % 10
        let mod100 = n % 100
        if mod10 == 1 && mod100 != 11 { return "ученик" }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return "ученика" }
        return "учеников"
    }

    static func pluralLessons(_ n: Int) -> String {
        let mod10 = n % 10
        let mod100 = n % 100
        if mod10 == 1 && mod100 != 11 { return "\(n) занятие" }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return "\(n) занятия" }
        return "\(n) занятий"
    }

    // Reused across calls — `ISO8601DateFormatter`/`DateFormatter` init is expensive
    // (locale/calendar/ICU setup); allocating one per call showed up as real jank
    // once lists (e.g. sorting students by `createdAt`) grew past ~50 rows.
    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoStandard: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let dayLabelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d MMMM, EEE"
        return f
    }()

    private static let shortTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "HH:mm"
        return f
    }()

    private static let fullTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d MMM, HH:mm"
        return f
    }()

    static func parseISO(_ iso: String) -> Date? {
        if let d = isoFractional.date(from: iso) { return d }
        return isoStandard.date(from: iso)
    }

    static func dayKey(_ iso: String) -> String {
        guard let d = parseISO(iso) else { return iso }
        let c = Calendar.current
        return "\(c.component(.year, from: d))-\(c.component(.month, from: d))-\(c.component(.day, from: d))"
    }

    static func dayLabel(_ iso: String) -> String {
        guard let d = parseISO(iso) else { return "" }
        let cal = Calendar.current
        if cal.isDateInToday(d) { return "Сегодня" }
        if cal.isDateInYesterday(d) { return "Вчера" }
        return dayLabelFormatter.string(from: d)
    }

    static func timeLabel(_ iso: String, short: Bool) -> String {
        guard let d = parseISO(iso) else { return "" }
        return (short ? shortTimeFormatter : fullTimeFormatter).string(from: d)
    }
}
