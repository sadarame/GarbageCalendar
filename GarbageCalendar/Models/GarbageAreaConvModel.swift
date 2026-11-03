import Foundation

enum ScheduleRegistrationCategory: String, CaseIterable {
    case master = "運営が登録した収集日"
    case community = "利用者が登録した収集日"

    var symbol: String { self == .master ? "tray.full.fill" : "person.fill" }
}

class GarbageAreaConvModel: Identifiable, Codable, Hashable, Equatable {
    // No
    var No: String?
    // 郵便番号
    var postalCode: String?
    // 都道府県
    var administrativeArea: String?
    // 市区町村
    var locality: String?
    // 丁目
    var thoroughfare: String?
    // グループID
    var garbageGroupId: String?
    // 公式フラグ
    var officialFlag: String?
    // 使用回数
    var usageCount: String?
    var registrationSource: String?
    var legacyUsageCount: String?

    var registrationCategory: ScheduleRegistrationCategory {
        // Old responses used officialFlag for master registrations. An explicit
        // source takes precedence, including a user's copy of a master schedule.
        let isMaster = registrationSource == "admin" ||
            (registrationSource == nil && officialFlag == "1")
        return isMaster ? .master : .community
    }

    var usageLabel: String {
        if let count = usageCount { return "利用 \(count)件" }
        if let count = legacyUsageCount { return "以前の利用 \(count)件" }
        return "利用件数：未集計"
    }
    // ゴミ情報名称
    var garbageInfoName: String?
    //緯度
    var latitude: String?
    //経度
    var longitude: String?

    // カスタムの等価性比較を実装します
    static func == (lhs: GarbageAreaConvModel, rhs: GarbageAreaConvModel) -> Bool {
        return lhs.No == rhs.No &&
               lhs.postalCode == rhs.postalCode &&
               lhs.administrativeArea == rhs.administrativeArea &&
               lhs.locality == rhs.locality &&
               lhs.thoroughfare == rhs.thoroughfare &&
               lhs.garbageGroupId == rhs.garbageGroupId &&
               lhs.officialFlag == rhs.officialFlag &&
               lhs.usageCount == rhs.usageCount &&
               lhs.registrationSource == rhs.registrationSource &&
               lhs.legacyUsageCount == rhs.legacyUsageCount &&
               lhs.garbageInfoName == rhs.garbageInfoName &&
               lhs.latitude == rhs.latitude &&
               lhs.longitude == rhs.longitude
    }

    // ハッシュ値を計算するためのメソッドを実装します
    func hash(into hasher: inout Hasher) {
        hasher.combine(No)
        hasher.combine(postalCode)
        hasher.combine(administrativeArea)
        hasher.combine(locality)
        hasher.combine(thoroughfare)
        hasher.combine(garbageGroupId)
        hasher.combine(officialFlag)
        hasher.combine(usageCount)
        hasher.combine(registrationSource)
        hasher.combine(legacyUsageCount)
        hasher.combine(garbageInfoName)
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}

// Keep the reference associated with the saved calendar, not a search preview.
struct CollectionReference: Codable {
    let scheduleId: String
    var sourceUrl: String?

    var url: URL? {
        guard let sourceUrl, let url = URL(string: sourceUrl),
              let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme),
              let host = url.host, !host.isEmpty else { return nil }
        return url
    }

    static func load() -> CollectionReference? {
        guard let data = UserDefaults.standard.data(forKey: "collection.reference") else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }

    static func save(_ reference: CollectionReference?) {
        if let reference, let data = try? JSONEncoder().encode(reference) {
            UserDefaults.standard.set(data, forKey: "collection.reference")
        } else {
            UserDefaults.standard.removeObject(forKey: "collection.reference")
        }
    }
}
