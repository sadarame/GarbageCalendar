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
final class ScheduleMapAnnotation: MKPointAnnotation {
    var models: [GarbageAreaConvModel] = []
}

class GarbageMapVM: BaseVM {
    @Published var selectedPin: ScheduleMapAnnotation?
    var visibleModels: [GarbageAreaConvModel] { selectedPin?.models ?? modelList }

    //リクエストパラメタ
    @Published var reqparam:GarbageAreaConvModel = GarbageAreaConvModel()
    @Published var searchMessage = ""
    //取得してきたゴミデータ
    @Published var modelList:[GarbageAreaConvModel] = []
    //次ページへの遷移するためのフラグ
    @Published var toNextPage = false
    //遷移先に渡すフラグ（なんのイベントで遷移したか）
    @Published var triggerFlg = 0
    //フォーカスする位置情報を定義
    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.048))
    // 取得してきたピン情報
    @Published var pinList: [MKPointAnnotation] = []
    
    
    override init() {
        super.init()
        
    }
    
    // MARK: 画面初期表示
    func onAppearInit(){
        isShowNavigate = false
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
        pin.subtitle = subtitle
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
    // MARK: リクエストパラメタを設定
    func setRequestParam (){
        if let userUnfo = loadUserAddressRegistModel() {
            reqparam.longitude = userUnfo.longitude
            reqparam.latitude = userUnfo.latitude
        }
    }
    
    // MARK: ゴミ情報取得APIをコールする
    func callGetGarbageAreaAPI(){
        guard !isShowProgres else { return }
        reqparam.latitude = String(region.center.latitude)
        reqparam.longitude = String(region.center.longitude)
        guard let latitude = Double(reqparam.latitude ?? ""),
              let longitude = Double(reqparam.longitude ?? "") else {
            searchMessage = "地域の位置を取得できませんでした。戻って現在地か地域名で検索してください。"
            return
        }
        selectedPin = nil
        isShowProgres = true
        searchMessage = "近くの収集情報を検索中…"
        Task { @MainActor in
            defer { self.isShowProgres = false; self.isDisEditable = false }
            do {
                let response: SharedSearchResponse = try await CollectionAPI.shared.call(
                    "searchSharedSchedulesV2", data: ["latitude": latitude, "longitude": longitude, "radiusKm": 2.0])
                self.modelList = response.result
                self.pinList = []
                self.addPinsFromModelList()
                self.searchMessage = response.result.isEmpty
                    ? "近くに共有情報がありません。手動で登録できます。"
                    : ""
            } catch {
                self.modelList = []
                self.pinList = []
                print("Shared schedule search failed: \(error)")
                self.searchMessage = "検索できませんでした。再試行するか、手動で登録してください。"
            }
        }
    }

    // MARK: ゴミ情報からマップにピンする
    func addPinsFromModelList() {
        var pins: [ScheduleMapAnnotation] = []
        for model in modelList {
            guard let latitude = Double(model.latitude ?? ""),
                  let longitude = Double(model.longitude ?? "") else { continue }
            if let existing = pins.first(where: {
                abs($0.coordinate.latitude - latitude) < 0.000001 &&
                abs($0.coordinate.longitude - longitude) < 0.000001
            }) {
                existing.models.append(model)
                existing.title = "この場所の収集情報（\(existing.models.count)件）"
            } else {
                let pin = ScheduleMapAnnotation()
                pin.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                pin.models = [model]
                pin.title = model.garbageInfoName ?? "収集情報"
                pin.subtitle = "下の一覧から収集日を確認できます"
                pins.append(pin)
            }
        }
        pinList = pins
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

