//
//  GarbageRegistrationVM.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/05/30.
//

import Foundation
import SwiftUI

class GarbageRegistVM : BaseVM {
    //モデルを変数
    @Published var garbageRegistModel:GarbageRegistModel = GarbageRegistModel()
    //モデル変数のリスト
    @Published var garbageRegistModelList:[GarbageRegistModel] = []
    //APIコールの状況（画面遷移の判断に使うかも？）
    @Published var apiResponseStatus = 0
    
//    @AppStorage("garbageInfoName") var garbageInfoName: String = ""
    
    //プルダウンの選択肢
    let garbageTypes:[String] = ["燃えるゴミ","燃えないゴミ","プラスチック","ビン・カン",
                                 "ペットボトル","古紙","ダンボール","資源ゴミ","粗大ごみ"]
    let schedules:[String] = ["毎週","隔週","毎月","第○曜日"]
    let yobis:[String] = ["月曜日","火曜日","水曜日","木曜日","金曜日","土曜日","日曜日"]
    let weekOfMonths = ["第一", "第二", "第三", "第四", "第五"]
    let freqWeeks = ["二週に一回", "三週に一回", "四週に一回"]
    let days:[Int] = Array(1...31)
    let months:[Int] = Array(1...12)
    
    override init() {
        super.init()
        
//        ユーザデフォルトからモデル変数リストを取得
        garbageRegistModelList = loadGarbageRegistModels()

        //はじめましてだったらリスト作る
        if garbageRegistModelList.isEmpty{
            self.addGarbageInfo()
        }
    }
    
    //こっちのinitでデータを取得する方法
    func callGetGarbageInfo(id:String){
        //LISTを選択した場合
        
        //選択しなかった場合
        guard let convModel = loadGarbageAreaConvModel(),
              let id = convModel.No else {
                return
            }
        
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

            }
        }
    }

    
    //プラスボタン押下時のイベント
    //リストに構造体を追加
    func addGarbageInfo(){
        let newGarbageRegistModel = GarbageRegistModel() // 新しいインスタンスを作成
        garbageRegistModelList.append(newGarbageRegistModel) // リストに追加
        saveGarbageRegistModels(garbageRegistModelList)//ユーザデフォルトに保存
    }
    
    //登録ボタン押下時の処理
    func registData(){
        //重複チェック
        if checkForDuplicates() {
            return
        }
        
        //プログレス表示,編集不可
        isShowProgres = true
        isDisEditable = true
        
        //ユーザーデフォルトに登録
        saveGarbageRegistModels(garbageRegistModelList)
        //登録用のAPIを叩く
        callRegistGarbageInfoAPI()
    }
    
    //ゴミ情報登録APIをコールする
    func callRegistGarbageInfoAPI(){
        // ゴミ情報リストをJSONデータに変換
        let jsonData = try! JSONEncoder().encode(garbageRegistModelList)
        // JSONデータを文字列に変換
        let jsonString = String(data: jsonData, encoding: .utf8)
        
        let model = loadGarbageAreaConvModel()
        
        // リクエストパラメータを作成
        let requestBody = [
            "TYPE": Const.TYPE_REGIST_GARBAGE_INFO,
            "API_KEY": Const.API_KEY,
            "USER_ID":loadUserID(),
            "GARBAGE_INFO": jsonString,
            "GARBAGE_INFO_NAME": model?.garbageInfoName,
            "CONV_NO": model?.No
        ]
        
        // JSONにデータ変換
        let jsonRequestBody = try! JSONSerialization.data(withJSONObject: requestBody)
        
        //APIのコール
        fetchDataFromAPI(url: Const.URL_API_CALL, type: Const.TYPE_REGIST_GARBAGE_INFO, jsonData: jsonRequestBody) { (result: Result<GarbageRegistRes, Error>) in
            //メインスレッドで実行
            DispatchQueue.main.async {
                switch result {
                case .success(let responseData):
                    //ステータスに登録状況をセット
                    if responseData.status == "succsess" {
                        self.apiResponseStatus = 1
                    }
                    
                case .failure(let error):
                    // エラー時の処理
                    self.showPopup(withMessage: "ゴミ情報登録でエラーが発生しました。")
                    print("Error: \(error)")
                }
                //プログレス表示,編集不可解除
                self.isShowProgres = false
                self.isDisEditable = false
            }
        }
    }//ファンクションの括弧
    
    //入力チェック
    func checkForDuplicates() -> Bool {
        var isError = false
        var uniqueSet = Set<String>() // 重複をチェックするためのセット
        
        for (index, model) in garbageRegistModelList.enumerated() {
            //前回のエラーをクリア
            garbageRegistModelList[index].duplicateError = false
            // UUID以外の項目で重複をチェック
            let uniqueKey = "\(model.garbageType)-\(model.schedule)-\(model.yobi)-\(model.day)-\(model.weekOfMonth)-\(model.freqWeek)-\(model.strDate)"
//            print(uniqueKey)
            if uniqueSet.contains(uniqueKey) {
                // 重複が見つかった場合は重複要素のエラーを設定
                garbageRegistModelList[index].duplicateError = true
                isError = true
            }
            uniqueSet.insert(uniqueKey) // ユニークなキーをセットに追加
        }
        
        if isError {
            showPopup(withMessage: "重複しているデータが存在します。")
        }
        return isError
    }
    
    //削除イベント
    func deleteCard(at index: Int) {
        garbageRegistModelList.remove(at: index)
        saveGarbageRegistModels(garbageRegistModelList)
        apiResponseStatus = 1
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
