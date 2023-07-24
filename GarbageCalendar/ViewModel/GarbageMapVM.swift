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
    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018))
    // 取得してきたピン情報
    @Published var pinList: [MKPointAnnotation] = []
    
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
        
        let semaphore = DispatchSemaphore(value: 0)
        
        isShowProgres = true
        isDisEditable = true
        
        //アンラップ
        guard let id = model.garbageGroupId else {
            // optionalValueがnilの場合の処理
            showPopup(withMessage: "グループIDが取得できませんでした")
            return
        }
        
        saveGarbageAreaConvModel(model)
        
        if let name = model.garbageInfoName {
            garbageInfoName = name
        }
        
        //ゴミ情報取得APIを叩く
        callGetGarbageInfo(id: id,semaphore:semaphore)
        
        semaphore.wait()
        
        toNextPage = true
        
    }
    
    func callGetGarbageInfo(id:String,semaphore:DispatchSemaphore){
        
        isShowProgres = true
        isDisEditable = true
        
        let requestBody = [
            "TYPE": Const.TYPE_GET_GARBAGE_INFO,
            "API_KEY": Const.API_KEY,
            "GROUP_ID": id
        ]
        
        // JSONにデータ変換
        let jsonRequestBody = try! JSONSerialization.data(withJSONObject: requestBody)
        
        
        guard let url = URL(string: Const.URL_API_CALL) else {
//            completion(.failure(APIError.invalidURL))
            return
        }
        
        //リクエスト作成
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //引数で受け取ったjsonを設定
        request.httpBody = jsonRequestBody
        
        isLoading = true
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            if let error = error {
                self.showPopup(withMessage: "ゴミ情報が取得できませんでした。")
                return
            }
            
            guard let data = data else {
                self.showPopup(withMessage: "ゴミ情報が取得できませんでした。")
                return
            }
            
            do {
                logData(data)
                let decodedData = try JSONDecoder().decode(GetGarbageInfoRes.self, from: data)
                self.assignValues(from: decodedData)
//                DispatchQueue.main.async {
//                    self.toNextPage = true
//                }
                semaphore.signal()
         
            } catch {
                       self.showPopup(withMessage: "ゴミ情報が取得できませんでした。")
                return
            }
        }.resume()
        
        //APIのコール
//        fetchDataFromAPI(url: Const.URL_API_CALL, type: Const.TYPE_GET_GARBAGE_AREA,jsonData:jsonRequestBody) { [self] (result: Result<GetGarbageInfoRes, Error>) in
//            DispatchQueue.main.async {
//                switch result {
//
//                case .success(let responseData):
//                    //編集不可を解除
//                    self.isDisEditable  = false
//                    //レスポンスをデータモデルに変換してユーザーデフォルトに保存
//                    self.assignValues(from: responseData)
//
//                    self.toNextPage = true
//                    semaphore.signal()
//
//                case .failure(let error):
//                    // エラー時の処理
//                    self.showPopup(withMessage: "住所情報が取得できませんでした。")
//
//                    print("Error: \(error)")
//                }
//                //通信終わりのため、プログレス非表示に
//                self.isShowProgres = false
//                self.isDisEditable = false
//                //次ページへ遷移する処理、なぜかできない
//                //遷移と同時にinitが複数回よばれてなかったことにされる？
////                self.toNextPage = true
//
//            }
//        }
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
    
    //リストから重複した情報を削除
    func removeDuplicatesFromModelList() {
        var seenElements = Set<String>()
        var uniqueElements = [GarbageAreaConvModel]()
        
        for model in modelList {
            let key = "\(model.garbageGroupId ?? "")-\(model.garbageInfoName ?? "")"
            
            if !seenElements.contains(key) {
                seenElements.insert(key)
                uniqueElements.append(model)
            }
        }
        
        modelList = uniqueElements
    }


}

