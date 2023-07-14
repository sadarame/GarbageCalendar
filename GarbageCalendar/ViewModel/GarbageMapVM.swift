//
//  MapVM.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/05/09.
//

import Foundation
import MapKit
import SwiftUI

//
class GarbageMapVM: BaseVM {
    //リクエストパラメタ
    @Published var reqparam:GarbageAreaConvModel = GarbageAreaConvModel()
    //取得してきたゴミデータ
    @Published var modelList:[GarbageAreaConvModel] = []
    //次ページへの遷移するためのフラグ
    @Published var toNextPage = false
    //フォーカスする位置情報を定義
    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002))
    // 取得してきたピン情報
    @Published var pinList: [MKPointAnnotation] = []
    
//    @AppStorage("garbageInfoName") var garbageInfoName: String = ""
    
    override init() {
        super.init()
//        self.region = getUserMapInfo()
        onAppearInit()
    }
    
    func onAppearInit(){
        //ユーザ情報を取得してMapをFocus
        getUserMapInfo()
        //API叩くときのリクエストパラメタ作成
        setRequestParam()
        //APIをコール
        callGetGarbageAreaAPI()
    }
    
    // 緯度経度からMapにピンを表示する
    func addPinToMap(latitude: Double, longitude: Double, title: String, subtitle: String) {
        let pin = MKPointAnnotation()
        pin.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        pin.title = title
        pin.subtitle = title
        pinList.append(pin)
        
    }
    
    //緯度経度からMapに表示
    func getUserMapInfo() {
        let userAdr = loadUserAddressRegistModel()
        
        if let latitudeString = userAdr?.latitude,
           let longitudeString = userAdr?.longitude,
           let latitude = Double(latitudeString),
           let longitude = Double(longitudeString) {
            
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            region = MKCoordinateRegion(center: coordinate, span: region.span)
        }
       
    }
    
    //TODO:　地名までで情報をひきに行く
    func getgarbageAreaConv(userAdr:AdrSetModel){
        
    }
    
    //リクエストパラメタを設定
    func setRequestParam (){
        if let userUnfo = loadUserAddressRegistModel() {
            reqparam.longitude = userUnfo.longitude
            reqparam.latitude = userUnfo.latitude
        }
    }
    
    //ゴミ情報取得APIをコールする
    func callGetGarbageAreaAPI(){
        // 住所情報の構造体をJSONデータに変換
        let jsonData = try! JSONEncoder().encode(reqparam)
        // JSONデータを文字列に変換
        let jsonString = String(data: jsonData, encoding: .utf8)
        // リクエストパラメータを作成
        let requestBody = [
            "TYPE": Const.TYPE_GET_GARBAGE_AREA,
            "API_KEY": Const.API_KEY,
            "GARBAGE_ADRRESS": jsonString,
        ]
        
        // JSONにデータ変換
        let jsonRequestBody = try! JSONSerialization.data(withJSONObject: requestBody)
        
        //APIのコール
        fetchDataFromAPI(url: Const.URL_API_CALL, type: Const.TYPE_GET_GARBAGE_AREA,jsonData:jsonRequestBody) { [self] (result: Result<GarbageAreaRes, Error>) in
            DispatchQueue.main.async {
                switch result {
                    
                case .success(let responseData):
                    //編集不可を解除
                    self.isDisEditable  = false
                    //ユーザーデフォルトに保存
                    self.modelList = responseData.result
                    //マップにPinを指す
                    self.addPinsFromModelList()
      
                case .failure(let error):
                    // エラー時の処理
                    self.showPopup(withMessage: "住所情報が取得できませんでした。")
                    
                    //次ページへ遷移する処理
                    self.toNextPage = true
                    
                    print("Error: \(error)")
                }
                //通信終わりのため、プログレス非表示に
                self.isShowProgres = false
            }
        }
    }
    
    func addPinsFromModelList() {
        for model in self.modelList {
            if let latitudeString = model.latitude,
               let longitudeString = model.longitude,
               let latitude = Double(latitudeString),
               let longitude = Double(longitudeString) {
                let title = model.garbageInfoName ?? "" // ピンのタイトル
                let subtitle = "" // ピンのサブタイトル
                
                addPinToMap(latitude: latitude, longitude: longitude, title: title, subtitle: subtitle)
            }
        }
    }

    
    //リストクリックした際のイベント
    func handleElementTap(model:GarbageAreaConvModel){
        //アンラップ
        guard let id = model.garbageGroupId else {
            // optionalValueがnilの場合の処理
            showPopup(withMessage: "グループIDが取得できませんでした")
            return
        }
        
        saveGarbageAreaConvModel(model)
//        garbageInfoName = model.garbageInfoName ?? ""
        
        //ゴミ情報取得APIを叩く
        callGetGarbageInfo(id: id)
        
    }
    
    func callGetGarbageInfo(id:String){
        self.isShowProgres = true
        self.isDisEditable = true
        
        let requestBody = [
            "TYPE": Const.TYPE_GET_GARBAGE_INFO,
            "API_KEY": Const.API_KEY,
            "GROUP_ID": id
        ]
        
        // JSONにデータ変換
        let jsonRequestBody = try! JSONSerialization.data(withJSONObject: requestBody)
        
        //APIのコール
        fetchDataFromAPI(url: Const.URL_API_CALL, type: Const.TYPE_GET_GARBAGE_AREA,jsonData:jsonRequestBody) { [self] (result: Result<GetGarbageInfoRes, Error>) in
            DispatchQueue.main.async {
                switch result {
                    
                case .success(let responseData):
                    //編集不可を解除
                    self.isDisEditable  = false
                    //レスポンスをデータモデルに変換してユーザーデフォルトに保存
                    self.assignValues(from: responseData)
  
                case .failure(let error):
                    // エラー時の処理
                    self.showPopup(withMessage: "住所情報が取得できませんでした。")
                    
                    print("Error: \(error)")
                }
                //通信終わりのため、プログレス非表示に
                self.isShowProgres = false
                self.isDisEditable = false
                //次ページへ遷移する処理
                self.toNextPage = true
            }
        }
    }
    func assignValues(from schedule: GetGarbageInfoRes) {
        var garbageModels: [GarbageRegistModel] = []
        
        for garbageItem in schedule.result {
            var garbageModel = GarbageRegistModel()
            
            garbageModel.garbageType = garbageItem.garbageType
            garbageModel.schedule = garbageItem.schedule
            garbageModel.yobi = garbageItem.yobi
            
            
            if let day = garbageItem.day {
                garbageModel.day = Int(day) ?? 1
            }
            
            if let dateString = garbageItem.date {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                if let date = dateFormatter.date(from: dateString) {
                    garbageModel.date = date
                }
            }
            
            if let weekOfMonth = garbageItem.weekOfMonth,
               let freqWeek = garbageItem.freqWeek {
                garbageModel.weekOfMonth = weekOfMonth
                garbageModel.freqWeek = freqWeek
            }
            
            garbageModels.append(garbageModel)
        }
        
        saveGarbageRegistModels(garbageModels)
    }

}

