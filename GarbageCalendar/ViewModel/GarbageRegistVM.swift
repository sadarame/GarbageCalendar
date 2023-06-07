//
//  GarbageRegistrationVM.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/05/30.
//

import Foundation

class GarbageRegistVM : BaseVM {
    //モデルを変数
    @Published var garbageRegistModel:GarbageRegistModel = GarbageRegistModel()
    //モデル変数のリスト
    @Published var garbageRegistModelList:[GarbageRegistModel]=[]
    //APIコールの状況（画面遷移の判断に使うかも？）
    @Published var apiResponseStatus = 0
    
    //プルダウンの選択肢
    let garbageTypes:[String] = ["燃えるゴミ","燃えないゴミ","プラスチック","ビン・カン",
                                 "ペットボトル","古紙","ダンボール","資源ゴミ","粗大ごみ"]
    let schedules:[String] = ["毎週","隔週","毎月","第○曜日"]
    let yobis:[String] = ["月曜日","火曜日","水曜日","木曜日","金曜日","土曜日","日曜日"]
    let weekOfMonths = ["第一", "第二", "第三", "第四", "第五"]
    let freqWeeks = ["二週に一回", "三週に一回", "四週に一回"]
    let days:[Int] = Array(1...31)
    let months:[Int] = Array(1...12)
    
    //初期処理
    func onApperInit(){
        //ユーザデフォルトからモデル変数リストを取得
        garbageRegistModelList = loadGarbageRegistModels()
        
        //はじめましてだったらリスト作る
        if garbageRegistModelList.isEmpty{
            garbageRegistModelList.append(GarbageRegistModel())
        }
    }
    
    //プラスボタン押下時のイベント
    //リストに構造体を追加
    func addGarbageInfo(){
        let newGarbageRegistModel = GarbageRegistModel() // 新しいインスタンスを作成
        garbageRegistModelList.append(newGarbageRegistModel) // リストに追加
    }
    
    //登録ボタン押下時の処理
    func registData(){
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
        // リクエストパラメータを作成
        let requestBody = [
            "TYPE": Const.TYPE_REGIST_GARBAGE_INFO,
            "API_KEY": Const.API_KEY,
            "GARBAGE_INFO": jsonString
        ]
        // JSONにデータ変換
        let jsonRequestBody = try! JSONSerialization.data(withJSONObject: requestBody)
        
        //APIのコール
        fetchDataFromAPI(url: Const.URL_API_CALL, type: Const.TYPE_REGIST_GARBAGE_INFO, jsonData: jsonRequestBody) { (result: Result<GarbageRegistRes, Error>) in
            //        fetchDataFromAPI(url: Const.URL_API_CALL, type: Const.TYPE_REGIST_GARBAGE_INFO) { (result: Result<ResponseData, Error>) in
            switch result {
            case .success(let responseData):
                //ステータスに登録状況をセット
                if responseData.status == "succsess" {
                    self.apiResponseStatus = 1
                }
                
            case .failure(let error):
                // エラー時の処理
                print("Error: \(error)")
            }
        }
    }//ファンクションの括弧
}
