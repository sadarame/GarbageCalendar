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
    //ゴミ情報名称
    @Published var garbageInfoName = ""
    //画面遷移用のフラグ
    @Published var toNextPage:Bool = false
    
    //プルダウンの選択肢
    let garbageTypes:[String] = ["燃えるゴミ","燃えないゴミ","プラスチック","ビン・カン",
                                 "ペットボトル","古紙","ダンボール","資源ゴミ","粗大ごみ","危険・有害","繊維"]
    let schedules:[String] = ["毎週","隔週","毎月","第○曜日"]
    let yobis:[String] = ["月曜日","火曜日","水曜日","木曜日","金曜日","土曜日","日曜日"]
    let weekOfMonths = ["第一", "第二", "第三", "第四", "第五"]
    let freqWeeks = ["二週に一回", "三週に一回", "四週に一回"]
    let days:[Int] = Array(1...31)
    let months:[Int] = Array(1...12)
    
    var count = 0
    
    override init() {
        super.init()
        onApperInit()
    }
    
    // MARK: 画面表示時の処理
    func onApperInit(){
        let trigger = loadTriggerFlg()
        //リストタップで遷移
        if trigger == Const.TRG_LIST_TAP {
            //タップされたListをもとに情報を取得する
            callGetGarbageInfo()
            //次へボタン押下時
        } else if (trigger == Const.TRG_NEXT_BUTTON) || (trigger == Const.TRG_SIDE_MENU)  {
            //ユーザデフォルトからモデル変数リストを取得
            garbageRegistModelList = loadGarbageRegistModels()
            //はじめましてだったらリスト作る
            if garbageRegistModelList.isEmpty{
                self.addGarbageInfo()
            }
            //ゴミ情報名称を設定
            garbageInfoName = loadGarbageInfoName() ?? ""
            
        } else {
            //なにもしない
        }
    }
    
    // MARK: ゴミ情報取得
    func callGetGarbageInfo(){
        
        //選択した情報を取得し、グループidをアンラップ
        guard let convModel = loadGarbageAreaConvModel(),
              let id = convModel.garbageGroupId,
              let tmpGarbageInfoName = convModel.garbageInfoName
        else {
            return
        }
        
        garbageInfoName = tmpGarbageInfoName
        
        //リクエスト作成
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
                    //レスポンスをデータモデルに変換してユーザーデフォルトに保存し、
                    //クラス変数二セット
                    self.assignValues(from: responseData)
                case .failure(let error):
                    // エラー時の処理
                    self.showPopup(withMessage: "ゴミ情報が取得できませんでした。")
                    print("Error: \(error)")
                }
            }
        }
    }
    
    // MARK: プラスボタン押下時のイベント
    //リストに構造体を追加
    func addGarbageInfo(){
        let newGarbageRegistModel = GarbageRegistModel() // 新しいインスタンスを作成
        garbageRegistModelList.append(newGarbageRegistModel) // リストに追加
    }
    
    // MARK: 登録ボタン押下時の処理
    func registData(){
        
        saveGarbageInfoName(garbageInfoName)
        //重複チェック
        if checkForDuplicates() {
            return
        }
        //ユーザーデフォルトに登録
        saveGarbageRegistModels(garbageRegistModelList)
        //登録用のAPIを叩く
        callRegistGarbageInfoAPI()
    }
    
    // MARK: ゴミ情報登録APIをコールする
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
            "GARBAGE_INFO_NAME": garbageInfoName,
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
                        //画面遷移
                        self.toNextPage = true
                    }else{
                        self.showPopup(withMessage: "ゴミ情報登録でエラーが発生しました。")
                    }
                    
                case .failure(let error):
                    // エラー時の処理
                    self.showPopup(withMessage: "ゴミ情報登録でエラーが発生しました。")
                    print("Error: \(error)")
                }
            }
        }
    }//ファンクションの括弧
    
    // MARK: 入力チェック
    func checkForDuplicates() -> Bool {
        
        for model in garbageRegistModelList {
            print("\(model.garbageType)-\(model.schedule)-\(model.yobi)-\(model.day)-\(model.weekOfMonth)-\(model.freqWeek)-\(model.strDate)")
        }
        
        
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
    
    // MARK: 削除イベント
    func deleteCard(at index: Int) {
        garbageRegistModelList.remove(at: index)
        saveGarbageRegistModels(garbageRegistModelList)
    }
    
    // MARK: 構造体の詰め込みメソッド
    func assignValues(from schedule: GetGarbageInfoRes) {
        var garbageModels: [GarbageRegistModel] = []
        
        for garbageItem in schedule.result {
            var garbageModel = GarbageRegistModel()
            
            garbageModel.garbageType = garbageItem.garbageType
            garbageModel.schedule = garbageItem.schedule
            
            if let yobi = garbageItem.yobi {
                garbageModel.yobi = yobi
            }
            
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
        
        self.garbageRegistModelList = garbageModels
        saveGarbageRegistModels(garbageRegistModelList)
        
    }
    
    // MARK: スクロール移動
    func scrollToBottom(scrollViewProxy: ScrollViewProxy) {
        scrollViewProxy.scrollTo(garbageRegistModelList.indices.last, anchor: .bottom)
    }
    
}
