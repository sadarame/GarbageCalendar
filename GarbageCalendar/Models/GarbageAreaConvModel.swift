import Foundation

class GarbageAreaConvModel:Identifiable,Codable {
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
    var officialFlag: Bool?
    // 使用回数
    var usageCount: String?
    // ゴミ情報名称
    var garbageInfoName: String?
    //緯度
    var latitude: String?
    //経度
    var longitude: String?

//    init(no: Int?, postalCode: String?, administrativeArea: String?, locality: String?, thoroughfare: String?, garbageGroupId: String?, officialFlag: Bool?, usageCount: Int?, garbageInfoName: String?,latitude: String?,longitude: String?) {
//        self.no = no
//        self.postalCode = postalCode
//        self.administrativeArea = administrativeArea
//        self.locality = locality
//        self.thoroughfare = thoroughfare
//        self.garbageGroupId = garbageGroupId
//        self.officialFlag = officialFlag
//        self.usageCount = usageCount
//        self.garbageInfoName = garbageInfoName
//        self.latitude = latitude
//        self.longitude = longitude
//    }
}
