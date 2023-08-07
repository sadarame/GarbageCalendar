import Foundation

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
        hasher.combine(garbageInfoName)
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}
