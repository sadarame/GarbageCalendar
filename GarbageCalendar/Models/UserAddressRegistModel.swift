//
//  UserAddressModel.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/06/06.
//

import Foundation

class UserAddressRegistModel:Identifiable,Codable {
    //ユーザーID
    var userId = "" {
        didSet{
            saveUserID(userId)
        }
    }
    //郵便番号　○
    var postalCode:String = ""
    //都道府県　○
    var administrativeArea: String = ""
    //郡（なくてもよいかも）
    var subAdministrativeArea: String = ""
    //市区町村　○
    var locality: String = ""
    //丁目なしの地名
    var subLocality: String = ""
    //地名　○
    var thoroughfare: String = ""
    //番地　○
    var subThoroughfare: String = ""
    //ビル名
    var buildName: String = ""
    //緯度
    var latitude: String = ""
    //経度
    var longitude: String = ""
    //FCMトークン
    var fcm_token:String = ""
    //最終更新日
    var last_updated:String = ""
}
