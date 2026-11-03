import Foundation

/// Collection dates are civil dates in Japan, independent of the device language.
enum ScheduleEngine {
    static var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return value
    }
    static let weekdays = ["日曜日", "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日"]
    static let ordinals = ["第一", "第二", "第三", "第四", "第五"]

    static func matches(_ model: GarbageRegistModel, on date: Date) -> Bool {
        let cal = calendar
        let target = cal.startOfDay(for: date)
        let parts = cal.dateComponents([.year, .month, .day], from: target)
        let key = String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
        if let from = model.validFrom, key < from { return false }
        if let to = model.validTo, key > to { return false }
        if model.schedule == "指定日のみ" { return model.specificDates?.contains(key) == true }
        if model.excludedDates?.contains(key) == true { return false }
        if model.additionalDates?.contains(key) == true { return true }
        let weekday = cal.component(.weekday, from: target) - 1
        switch model.schedule {
        case "毎週":
            return weekdays[weekday] == model.yobi
        case "毎月":
            return cal.component(.day, from: target) == model.day
        case "第○曜日":
            return weekdays[weekday] == model.yobi &&
                ordinals.firstIndex(of: model.weekOfMonth) == (cal.component(.day, from: target) - 1) / 7
        case "隔週":
            guard let interval = ["二週に一回": 2, "三週に一回": 3, "四週に一回": 4][model.freqWeek],
                  weekdays[weekday] == model.yobi else { return false }
            let formatter = DateFormatter()
            formatter.calendar = cal
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = cal.timeZone
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.isLenient = false
            let anchor = cal.startOfDay(for: formatter.date(from: model.strDate) ?? model.date)
            // Legacy forms allow the anchor date and selected weekday to differ.
            // Use the first selected weekday on/after the anchor as the first collection.
            let anchorWeekday = cal.component(.weekday, from: anchor) - 1
            let firstOffset = (weekday - anchorWeekday + 7) % 7
            let days = (cal.dateComponents([.day], from: anchor, to: target).day ?? -1) - firstOffset
            return days >= 0 && days % (interval * 7) == 0
        default:
            return false
        }
    }

    struct Reminder {
        let date: Date
        let types: [String]
    }

    /// Merge same-day types so one collection day consumes only one pending slot.
    static func reminders(models: [GarbageRegistModel], after now: Date,
                          previousDay: Bool, hour: Int, minute: Int,
                          limit: Int = 60) -> [Reminder] {
        guard limit > 0, (0...23).contains(hour), (0...59).contains(minute) else { return [] }
        let cal = calendar
        let today = cal.startOfDay(for: now)
        var result: [Reminder] = []
        for offset in 0...366 {
            guard let collection = cal.date(byAdding: .day, value: offset, to: today),
                  let notificationDay = cal.date(byAdding: .day, value: previousDay ? -1 : 0, to: collection),
                  let fireDate = cal.date(bySettingHour: hour, minute: minute, second: 0, of: notificationDay),
                  fireDate > now else { continue }
            let types = Array(Set(models.filter { matches($0, on: collection) }.map(\.garbageType))).sorted()
            if !types.isEmpty { result.append(Reminder(date: fireDate, types: types)) }
            if result.count == limit { break }
        }
        return result
    }
}
