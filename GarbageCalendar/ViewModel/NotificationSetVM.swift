//
//  NoticateVM.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/09/15.
//

import Foundation
import SwiftUI
import UserNotifications

class NotificationSetVM: BaseVM {
    
    
    //設定のモデル
    @Published var model:NotificateModel = NotificateModel()
    
    @Published var tmpModel:NotificateModel = NotificateModel()
    
    //モデル変数のリスト
    @Published var garbageRegistModelList:[GarbageRegistModel] = []
    
    // MARK: - 初期処理
    override init() {
        //登録したゴミ情報を取得
        garbageRegistModelList = loadGarbageRegistModels()
       
        // 通知設定のモデルを読み込む
        if let model = loadNotificateModel() {
            self.model = model
        }
    }
    
    // MARK: - 画面初期処理
    func onApperInit(){
        //アラートメッセージの表示
        self.navigateKey = Const.KEY_NOTIFICATE
        self.navigateText = Const.INFO_MESSAGE_3
    }
 
    // MARK: - 通知許可
    // 通知許可ステータスを確認する関数
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    // 通知が許可されている場合
                    print("通知が許可されています")
                    // 通知の有効状態を保存
                    saveNotificateModel(self.model)
                case .denied:
                    // 通知が拒否されている場合
                    print("通知が拒否されています")
                    // ポップアップを表示して通知許可を求める
                    self.requestNotificationPermission()
                default:
                    // その他のステータス
                    print("通知設定が不明です")
                }
            }
        }
    }

    // 通知許可を求める関数
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    // ユーザーが許可した場合
                    print("通知が許可されました")
                    // 通知の有効状態を保存
                    self.changeNotificateSetting()
                } else {
                    // ユーザーが拒否またはエラーが発生した場合
                    print("通知が拒否またはエラーが発生しました")
                    self.isShowNavigate = true
                    self.model.isNotificationEnabled = false
                    self.changeNotificateSetting()
                  
                }
            }
        }
    }
   
    func changeNotificateSetting(){
        //再描画対策
        tmpModel  = model
        //変更内容保存
        saveNotificateModel(self.model)
        
        //通知設定が有効の場合
        if model.isNotificationEnabled {
            //通知登録処理を呼ぶ
            scheduleMonthlyNotification()
            
        //通知設定が無効の場合
        }else{
            //通知処理を削除する
            
        }
    }

    func scheduleMonthlyNotification() {
        let notificationCenter = UNUserNotificationCenter.current()

        // 通知内容を設定
        let content = UNMutableNotificationContent()
        content.title = "毎月の通知"
        content.body = "通知の本文"

        // 通知のトリガーを作成
        var dateComponents = DateComponents()
        dateComponents.month = 1 // 1ヶ月ごと
        dateComponents.day = 1   // 1日
        dateComponents.hour = 9  // 9時
        dateComponents.minute = 0 // 0分
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // 通知リクエストを作成
        let request = UNNotificationRequest(identifier: "MonthlyNotification", content: content, trigger: trigger)

        // 通知をスケジュール
        notificationCenter.add(request) { error in
            if let error = error {
                print("通知のスケジュールに失敗しました: \(error)")
            } else {
                print("通知がスケジュールされました")
            }
        }
    }
    
    func registerNotificationsForGarbageModels() {
            for garbageModel in garbageRegistModelList {
                switch garbageModel.schedule {
                case "毎週":
                    // ③-1: クラス変数modelからタイミング（selectedDate）、時分（selectionDate）を取得
                    let selectedDate = model.selectedDate
                    let selectionDate = model.selectionDate
                    
                    // ③-2: ゴミの種類（garbageType）、曜日（GarbageRegistModel.yobi）、selectedDate、selectionDateをもとに通知設定を登録
                    registerNotificationForWeekly(garbageType: garbageModel.garbageType,
                                                  yobi: garbageModel.yobi,
                                                  selectedDate: selectedDate,
                                                  selectionDate: selectionDate)
//                case "隔週":
//                    // ④-1: ゴミの種類、間隔（GarbageRegistModel.freqWeek）、曜日、直近の収集日（GarbageRegistModel.strDate）をもとに通知設定を登録
//                    registerNotificationForBiweekly(garbageType: garbageModel.garbageType,
//                                                    freqWeek: garbageModel.freqWeek,
//                                                    yobi: garbageModel.yobi,
//                                                    strDate: garbageModel.strDate)
//                case "毎月":
//                    // ⑤-1: ゴミの種類と日付（GarbageRegistModel.day）をもとに通知設定を登録
//                    registerNotificationForMonthly(garbageType: garbageModel.garbageType,
//                                                   day: garbageModel.day)
//                case "第○曜日":
//                    // ⑥-1: ゴミの種類と日付（GarbageRegistModel.weekOfMonth）と曜日をもとに通知設定を登録
//                    registerNotificationForSpecificWeekday(garbageType: garbageModel.garbageType,
//                                                          weekOfMonth: garbageModel.weekOfMonth,
//                                                          yobi: garbageModel.yobi)
                default:
                    break
                }
            }
        }
    
    // MARK: ゴミ情報から毎週の通知設定を登録するメソッド
    func registerNotificationForWeekly(garbageType: String, yobi: String, selectedDate: NotificationTiming, selectionDate: Date) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "ゴミの収集日です"
        content.body = "今日は\(garbageType)の収集日です。"
        
        // 曜日を数値に変換
        guard let weekday = yobiToWeekday(yobi) else {
            print("曜日の変換に失敗しました")
            return
        }
        
        // 通知のトリガーを設定
        var dateComponents = DateComponents()
        dateComponents.weekday = weekday // 曜日
        
        // ここでselectedDateを考慮して日付を設定
        if selectedDate == .theDayBefore {
            // 前日通知の場合、通知を前日（1日減算）に設定
            dateComponents.day = dateComponents.day! - 1
        }
        
        dateComponents.hour = Calendar.current.component(.hour, from: selectionDate)
        dateComponents.minute = Calendar.current.component(.minute, from: selectionDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // 通知リクエストを作成
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        // 通知リクエストを登録
        center.add(request) { error in
            if let error = error {
                print("通知の登録に失敗しました: \(error.localizedDescription)")
            } else {
                print("通知が正常に登録されました")
            }
        }
    }


    // MARK: - 日付変換メソッド
    func yobiToWeekday(_ yobi: String) -> Int? {
        let weekdayMapping: [String: Int] = [
            "日曜日": 1,
            "月曜日": 2,
            "火曜日": 3,
            "水曜日": 4,
            "木曜日": 5,
            "金曜日": 6,
            "土曜日": 7
        ]
        
        return weekdayMapping[yobi]
    }

}
