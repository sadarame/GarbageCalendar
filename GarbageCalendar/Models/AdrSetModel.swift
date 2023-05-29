//
//  AdrSetModel.swift
//  dustCalrendar
//
//  Created by Yosuke Yoshida on 2023/03/22.
//

import Foundation
import RealmSwift

//住所データモデル
    class AdrSetModel:Object,Identifiable  {
        var isExistRalm  = false
        //郵便番号
        @Persisted var postalCode:String? = ""
        //都道府県
        @Persisted var administrativeArea:String? = ""
        //郡（なくてもよいかも）
        @Persisted var subAdministrativeArea:String? = ""
        //市区町村
        @Persisted var locality:String? = ""
        //丁目なしの地名
        @Persisted var subLocality:String? = ""
        //地名
        @Persisted var thoroughfare:String? = ""
        //番地
        @Persisted var subThoroughfare:String? = ""
        //建物名
        @Persisted var buildName:String? = ""
        
        //緯度
        @Persisted var latitude:String? = ""
        //経度
        @Persisted var longitude:String? = ""
    
//    func getFullAddress() -> String {
//            return "\(self.post_cd), \(self.pref_nm), \(self.city_nm), \(self.tyome_nm), \(self.building_nm)"
//        }
}
