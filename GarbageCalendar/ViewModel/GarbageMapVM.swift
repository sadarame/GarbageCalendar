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
    //遷移先に渡すフラグ（なんのイベントで遷移したか）
    @Published var triggerFlg = 0
    //フォーカスする位置情報を定義
    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.009, longitudeDelta: 0.009))
    // 取得してきたピン情報
    @Published var pinList: [MKPointAnnotation] = []
    
    
    override init() {
        super.init()
        onAppearInit()
        
    }
    
    // MARK: 画面初期表示
    func onAppearInit(){
        setNavigateFlg()
        //ユーザ情報を取得してMapをFocus
        getUserMapInfo()
        //API叩くときのリクエストパラメタ作成
        setRequestParam()
        //APIをコール
        callGetGarbageAreaAPI()
    }
    
    // MARK: チュートリアルフラグ取得
    func setNavigateFlg() {
        if let isShowNavigate = loadIsShowNavigateMap() {
            if isShowNavigate == Const.show_NavigationView {
                self.isShowNavigate = true
            } else {
                self.isShowNavigate = false
            }
        } else {
            self.isShowNavigate = true
        }
        
        self.navigateKey = "isShowNavigateMap"
        self.navigateText = Const.INFO_MESSAGE_2
    }
    
    // MARK:  緯度経度からMapにピンを表示する
    func addPinToMap(latitude: Double, longitude: Double, title: String, subtitle: String) {
        let pin = MKPointAnnotation()
        pin.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        pin.title = title
        pin.subtitle = title
        pinList.append(pin)
        
    }
    
    // MARK: 緯度経度からMapに表示
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
    
    // MARK: 　地名までで情報をひきに行く
    func getgarbageAreaConv(userAdr:AdrSetModel){
        
    }
    
    // MARK: リクエストパラメタを設定
    func setRequestParam (){
        if let userUnfo = loadUserAddressRegistModel() {
            reqparam.longitude = userUnfo.longitude
            reqparam.latitude = userUnfo.latitude
        }
    }
    
    // MARK: ゴミ情報取得APIをコールする
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
                    //リストから重複を削除
                    self.removeDuplicatesFromModelList()
      
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
    
    // MARK: ゴミ情報からマップにピンする
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

    // MARK: リストクリックした際のイベント
    func handleElementTap(model:GarbageAreaConvModel){
        //モデルの保存
        saveGarbageAreaConvModel(model)
        //フラグセット
        saveTriggerFlg(Const.TRG_LIST_TAP)
        //画面遷移
        toNextPage = true
    }
    
    // MARK: 次へボタン（該当なし）
    func tapNextButton(){
        //フラグセット
        saveTriggerFlg(Const.TRG_NEXT_BUTTON)
        //画面遷移
        toNextPage = true
    }
    
    // MARK: リストから重複した情報を削除
    //同一のゴミ情報情報が複数取得されてくる場合がある
    func removeDuplicatesFromModelList() {
        var seenElements = Set<String>()
        var uniqueElements = [GarbageAreaConvModel]()
        
        for model in modelList {
            let key = "\(model.garbageGroupId ?? "")-\(model.garbageInfoName ?? "")-\(model.officialFlag ?? "")"
            
            if !seenElements.contains(key) {
                seenElements.insert(key)
                uniqueElements.append(model)
            }
        }
        
        modelList = uniqueElements
    }

}

