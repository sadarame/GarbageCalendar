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
    @Published var reference: CollectionReference?
    @Published private(set) var isLoadingSchedule = false
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
    
    @Published var needsArea = false
    @Published var hasPublishedContribution = UserDefaults.standard.bool(forKey: "collection.hasPublishedContribution")
    private var selectedScheduleId: String?
    private var didLoad = false
    private(set) var editsSavedAutomatically = false
    var count = 0
    
    override init() {
        super.init()
    }
    
    // MARK: 画面表示時の処理
    func onApperInit(){
        guard !didLoad else { return }
        didLoad = true
        let trigger = loadTriggerFlg()
        editsSavedAutomatically = trigger == Const.TRG_SIDE_MENU
        //リストタップで遷移
        if trigger == Const.TRG_LIST_TAP {
            //タップされたListをもとに情報を取得する
            callGetGarbageInfo()
            //次へボタン押下時
        } else if (trigger == Const.TRG_NEXT_BUTTON) || (trigger == Const.TRG_SIDE_MENU)  {
            //ユーザデフォルトからモデル変数リストを取得
            garbageRegistModelList = loadGarbageRegistModels()
            //はじめましてだったらリスト作る

            //ゴミ情報名称を設定
            garbageInfoName = loadGarbageInfoName() ?? ""
            reference = CollectionReference.load()
            
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
        
        isShowProgres = true
        isLoadingSchedule = true
        Task { @MainActor in
            defer {
                self.isLoadingSchedule = false
                self.isShowProgres = false
            }
            do {
                let response: SharedScheduleResponse = try await CollectionAPI.shared.call(
                    "getSharedScheduleV2", data: ["id": id])
                self.selectedScheduleId = response.id
                self.reference = CollectionReference(scheduleId: response.id, sourceUrl: response.sourceUrl)
                self.garbageInfoName = response.name
                self.garbageRegistModelList = response.rules.map { $0.model() }
            } catch {
                self.showPopup(withMessage: "収集情報を取得できませんでした。戻って再検索してください。")
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

        guard !isShowProgres else { return }
        guard !garbageRegistModelList.isEmpty else {
            showPopup(withMessage: "収集ルールを1件以上追加してください。")
            return
        }
        guard !checkForDuplicates() else { return }
        if garbageInfoName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let area = loadUserAddressRegistModel()
            let label = (area?.locality ?? "") + (area?.thoroughfare ?? "")
            garbageInfoName = label.isEmpty ? "この地域の収集予定" : label + "の収集予定"
        }
        callRegistGarbageInfoAPI()
    }

    func saveCalendarEdits() {
        guard editsSavedAutomatically else { return }
        saveGarbageInfoName(garbageInfoName)
        saveGarbageRegistModels(garbageRegistModelList)
    }

    private func finishSaving() {
        CollectionReference.save(reference)
        saveGarbageInfoName(garbageInfoName)
        saveGarbageRegistModels(garbageRegistModelList)
        saveDestination(Const.view_CalendarView)
        toNextPage = true
    }

    // Registration updates only this Firebase user's own community contribution.
    func callRegistGarbageInfoAPI() {
        guard let address = loadUserAddressRegistModel(),
              let latitude = Double(address.latitude), let longitude = Double(address.longitude),
              !garbageInfoName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            needsArea = true
            return
        }
        isShowProgres = true
        Task { @MainActor in
            defer { self.isShowProgres = false }
            do {
                var payload: [String: Any] = [
                    "name": self.garbageInfoName, "latitude": latitude, "longitude": longitude,
                    "rules": try CollectionAPI.rules(self.garbageRegistModelList)]
                if let id = self.selectedScheduleId { payload["selectedScheduleId"] = id }
                let _: SharedSaveResponse = try await CollectionAPI.shared.call("saveSharedScheduleV2", data: payload)
                self.hasPublishedContribution = true
                UserDefaults.standard.set(true, forKey: "collection.hasPublishedContribution")
                self.finishSaving()
            } catch {
                self.showPopup(withMessage: "保存できませんでした。通信を確認して再試行してください。")
            }
        }
    }

    func withdrawSharing() {
        guard !isShowProgres else { return }
        isShowProgres = true
        Task { @MainActor in
            defer { self.isShowProgres = false }
            do {
                let _: SharedWithdrawResponse = try await CollectionAPI.shared.call("unpublishSharedScheduleV2", data: [:])
                self.hasPublishedContribution = false
                UserDefaults.standard.set(false, forKey: "collection.hasPublishedContribution")
                self.showPopup(withMessage: "共有を停止しました。端末の予定は引き続き利用できます。")
            } catch {
                self.showPopup(withMessage: "共有を停止できませんでした。通信を確認して再試行してください。")
            }
        }
    }

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
            let uniqueKey = "\(model.garbageType)-\(model.schedule)-\(model.yobi)-\(model.day)-\(model.weekOfMonth)-\(model.freqWeek)-\(model.strDate)-\((model.excludedDates ?? []).sorted())-\((model.additionalDates ?? []).sorted())-\(model.validFrom ?? "")-\(model.validTo ?? "")-\((model.specificDates ?? []).sorted())"
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
