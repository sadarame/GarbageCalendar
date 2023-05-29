//
//  AdrSetVM.swift
//  dustCalrendar
//
//  Created by Yosuke Yoshida on 2023/03/23.
//

import SwiftUI
import RealmSwift
import Foundation

class SetAdressInfoVM: BaseVM {
    
    //レルムのデータが存在するかのフラグ
    var isNoAdrData = false
    
    @Published var userNo = ""
    
    @Published var adrSetModel:AdrSetModel?
    //郵便番号
    @Published var postalCode = ""
    //都道府県
    @Published var administrativeArea = ""
    //郡（なくてもよいかも）
    @Published var subAdministrativeArea = ""
    //市区町村
    @Published var locality = ""
    //丁目なしの地名
    @Published var subLocality = ""
    //地名
    @Published var thoroughfare = ""
    //番地
    @Published var subThoroughfare = ""
    //建物名
    @Published var buildName = ""
    
    //緯度
    @Published var latitude = ""
    //経度
    @Published var longitude = ""

    //ユーザの住所情報を保存するメソッド
    func setUserAdrData(){
        let realm = try! Realm()
        let tmp_adrSetModel = AdrSetModel()
        tmp_adrSetModel.postalCode = self.postalCode
        tmp_adrSetModel.administrativeArea = self.administrativeArea
        tmp_adrSetModel.subAdministrativeArea = self.subAdministrativeArea
        tmp_adrSetModel.locality = self.locality
        tmp_adrSetModel.subLocality = self.subLocality
        tmp_adrSetModel.thoroughfare = self.thoroughfare
        tmp_adrSetModel.subThoroughfare = self.subThoroughfare
        
        tmp_adrSetModel.buildName = self.buildName
        tmp_adrSetModel.latitude = self.latitude
        tmp_adrSetModel.longitude = self.longitude
        
        try! realm.write {
            realm.add(tmp_adrSetModel)
        }
    }
    
    //View表示時の初期化処理
    func DispInitValue(locationClient:LocationClient){
        do {
            let realm = try Realm()
            if let adrSetModelData = realm.objects(AdrSetModel.self).first {
                adrSetModel = adrSetModelData
            } else {
                adrSetModel = AdrSetModel()
                isNoAdrData = true
            }
        } catch let error as NSError {
          // handle error
            print(error)
        }
        
        // RalmDataが存在しない場合
        if isNoAdrData {
            //現在位置からジオコーディング
            let placemark = locationClient.placeInfo
            
            //緯度経度取得
            self.latitude = locationClient.location?.latitude.description ?? ""
            self.longitude = locationClient.location?.longitude.description ?? ""
            
            self.postalCode = placemark?.postalCode ?? ""
            self.administrativeArea = placemark?.administrativeArea ?? ""
            self.subAdministrativeArea = placemark?.subAdministrativeArea ?? ""
            self.locality = placemark?.locality ?? ""
            self.subLocality = placemark?.subLocality ?? ""
            self.thoroughfare = placemark?.thoroughfare ?? ""
            self.subThoroughfare = placemark?.subThoroughfare ?? ""
            
        } else {
            //Ralmから初期値を設定
            self.postalCode = adrSetModel!.postalCode!
            self.administrativeArea = adrSetModel!.administrativeArea!
            self.subAdministrativeArea = adrSetModel!.subAdministrativeArea!
            self.locality = adrSetModel!.locality!
            self.subLocality = adrSetModel!.subLocality!
            self.thoroughfare = adrSetModel!.thoroughfare!
            self.subThoroughfare = adrSetModel!.subThoroughfare!
            
            self.buildName = adrSetModel!.buildName!
            self.latitude = adrSetModel!.latitude!
            self.longitude = adrSetModel!.longitude!
            
        }
    }
    
    //使ってない
    //さいたま市緑区、四日市市の対応
    func strSplitCity(strLocal:String) -> [String] {
        
        var counter = 0
        //1個目の配列に市まで入る。2個目の配列に市以降の文字列が入る
        //さいたま市緑区対応
        var rv:[String] = ["",""]
        
        //一文字づつ配列化
        let strLocalsList = Array(strLocal)
        
        for c_strLocal in strLocalsList {
            if c_strLocal == "市" {
                //「市」の出現位置と文字列の長さが同一の場合
                if counter == strLocalsList.count {
                    //引数をそのまま戻り値に設定する
                    rv[0] = strLocal
                    break
                //さいたま市緑区や四日市市を救いたい
                } else {
                    //四日市市のパターン
                    if ((strLocalsList.count - counter) == 1 ){
                        rv[0] = strLocal
                    //さいたま市緑区の場合
                    } else {
                        counter = counter + 1
                        for i in 0 ..< counter {
                            rv[0]  = rv[0] + String(strLocalsList[i])
                        }
                        //さいたま市以降の文字列を要素２の配列に設定
                        for i in counter ..< strLocalsList.count {
                            rv[1]  = rv[1] + String(strLocalsList[i])
                        }
                    }
                    break
                }
            }
            counter = counter + 1
        }
        return rv
    }
}
