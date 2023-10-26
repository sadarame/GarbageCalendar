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
    //画面更新用（本来いらない）
    @Published var tmpModel:NotificateModel = NotificateModel()
    //モデル変数のリスト
    @Published var garbageRegistModelList:[GarbageRegistModel] = []
    
    // MARK: - 初期処理
    override init() {
        super.init()
        //アラートメッセージの表示
        navigateKey = Const.KEY_NOTIFICATE
        navigateText = Const.INFO_MESSAGE_3
        
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
 
    // MARK: - 通知許可系
    // 通知許可ステータスを確認する関数
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    // 通知が許可されている場合
                    print("通知が許可されています")
                    // 通知の有効状態を保存
                    self.changeNotificateSetting()
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
    
   // MARK: - 通知設定変更
    func changeNotificateSetting(){
        //再描画対策
        tmpModel  = model
        //変更内容保存
        saveNotificateModel(self.model)
        
        //通知設定のクリア
        removeAllNotifications()
        
        //通知設定が有効の場合
        if model.isNotificationEnabled {
            //通知登録処理を呼ぶ
            registerNotificationsForGarbageModels()
            
        //通知設定が無効の場合
        }else{
            //通知処理を削除する
            
        }
    }
    
    // MARK: - 通知登録情報読み込み
    func registerNotificationsForGarbageModels() {
            for garbageModel in garbageRegistModelList {
                switch garbageModel.schedule {
                case "毎週":

                    // ③-2: ゴミの種類（garbageType）、曜日（GarbageRegistModel.yobi）、selectedDate、selectionDateをもとに通知設定を登録
                    registerNotificationForWeekly(garbageType: garbageModel.garbageType,
                                                  yobi: garbageModel.yobi,
                                                  dateType: model.dateType,
                                                  notificateTime: model.notificateTime)
                case "隔週":
                    // ④-1: ゴミの種類、間隔（GarbageRegistModel.freqWeek）、曜日、直近の収集日（GarbageRegistModel.strDate）をもとに通知設定を登録
                    registerNotificationForBiweekly(garbageType: garbageModel.garbageType,
                                                    freqWeek: garbageModel.freqWeek,
                                                    yobi: garbageModel.yobi,
                                                    strDate: garbageModel.strDate,
                                                    dateType: model.dateType,
                                                    notificateTime: model.notificateTime)
                case "毎月":
                    // ⑤-1: ゴミの種類と日付（GarbageRegistModel.day）をもとに通知設定を登録
                    registerNotificationForMonthly(garbageType: garbageModel.garbageType,
                                                   day: garbageModel.day,
                                                   dateType: model.dateType,
                                                   notificateTime: model.notificateTime)
                    
                case "第○曜日":
                    // ⑥-1: ゴミの種類と日付（GarbageRegistModel.weekOfMonth）と曜日をもとに通知設定を登録
                    registerNotificationForSpecificWeekday(garbageType: garbageModel.garbageType,
                                                          weekOfMonth: garbageModel.weekOfMonth,
                                                          yobi: garbageModel.yobi,
                                                          dateType: model.dateType,
                                                          notificateTime: model.notificateTime)
                    
                default:
                    break
                }
            }
        }
    
    // MARK: ゴミ情報から毎週の通知設定を登録するメソッド
    func registerNotificationForWeekly(garbageType: String, yobi: String, dateType: NotificationTiming, notificateTime: Date) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "ゴミの収集日です"
        content.body = "今日は\(garbageType)の収集日です."
        
        // 曜日を数値に変換
        guard let weekday = yobiToWeekday(yobi) else {
            print("曜日の変換に失敗しました")
            return
        }
        
        // 通知のトリガーを設定
        var dateComponents = DateComponents()
        dateComponents.weekday = weekday // 曜日
        
        // ここでselectedDateを考慮して日付を設定
        if dateType == .theDayBefore {
            content.body = "明日は\(garbageType)の収集日です."
            // 前日通知の場合、通知を前日（1日減算）に設定
            if let currentDay = dateComponents.day {
                dateComponents.day = currentDay - 1
            } else {
                dateComponents.day = 1
            }
        }
        
        dateComponents.hour = Calendar.current.component(.hour, from: notificateTime)
        dateComponents.minute = Calendar.current.component(.minute, from: notificateTime)
        
        // 通知が繰り返されるようにトリガーを設定
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

    
    // MARK: ゴミ情報から隔週の通知設定を登録するメソッド
    func registerNotificationForBiweekly(garbageType: String, freqWeek: String, yobi: String, strDate: String, dateType: NotificationTiming, notificateTime: Date) {
        let center = UNUserNotificationCenter.current()

        // 通知コンテンツを作成
        let content = UNMutableNotificationContent()
        content.title = "ゴミの収集日です"
        content.body = "今日は\(garbageType)の収集日です。"

        // 曜日を数値に変換
        guard let weekday = yobiToWeekday(yobi) else {
            print("曜日の変換に失敗しました")
            return
        }

        // 開始日（strDate）をDateに変換
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let startDate = dateFormatter.date(from: strDate) else {
            print("開始日の変換に失敗しました")
            return
        }

        // 通知のトリガーを設定
        var dateComponents = Calendar.current.dateComponents([.weekday, .hour, .minute], from: startDate)
        dateComponents.weekday = weekday

        // 週ごとの秒数を計算
        let secondsInMinute = 60
        let secondsInHour = 60 * secondsInMinute
        let secondsInDay = 24 * secondsInHour
        let secondsInWeek = 7 * secondsInDay

        var interval = TimeInterval(0)

        switch freqWeek {
        case "二週に一回":
            interval = TimeInterval(2 * secondsInWeek)
        case "三週に一回":
            interval = TimeInterval(3 * secondsInWeek)
        case "四週に一回":
            interval = TimeInterval(4 * secondsInWeek)
        default:
            // エラーハンドリング
            break
        }

        // 通知タイミングを前日にずらす
        if dateType == .theDayBefore {	
            let secondsInDay = 24 * secondsInHour
            interval -= Double(secondsInDay)
            content.body = "明日は\(garbageType)の収集日です。"
        }

        // 通知の時刻を設定
        let calendar = Calendar.current
        let notificateDate = calendar.date(bySettingHour: calendar.component(.hour, from: notificateTime), minute: calendar.component(.minute, from: notificateTime), second: 0, of: startDate)!

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: true)

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

    // MARK: - ゴミ情報から毎月の通知設定を登録するメソッド
    func registerNotificationForMonthly(garbageType: String, day: Int, dateType: NotificationTiming, notificateTime: Date) {
        let center = UNUserNotificationCenter.current()

        // 通知コンテンツを作成
        let content = UNMutableNotificationContent()
        content.title = "ゴミの収集日です"
        content.body = "今日は\(garbageType)の収集日です。"

        // 現在の年月を取得
        let currentDate = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)

        // 指定された日が存在するか確認
        let calendarRange = calendar.range(of: .day, in: .month, for: currentDate)!
        if day < 1 || day > calendarRange.count {
            print("指定された日が存在しません。通知は設定されません。")
            return
        }

        // 次回の通知日を計算
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day

        // 通知タイミングを前日にずらす
        if dateType == .theDayBefore {
            content.body = "明日は\(garbageType)の収集日です。"
            dateComponents.day! -= 1
        }

        // 通知の時刻を設定
        let notificateCalendar = Calendar.current
        let notificateDate = notificateCalendar.date(bySettingHour: notificateCalendar.component(.hour, from: notificateTime), minute: notificateCalendar.component(.minute, from: notificateTime), second: 0, of: currentDate)!

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
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
    
    // MARK: - ゴミ情報から第◯曜日の通知設定を登録するメソッド
    func registerNotificationForSpecificWeekday(garbageType: String, weekOfMonth: String, yobi: String, dateType: NotificationTiming, notificateTime: Date) {
        let center = UNUserNotificationCenter.current()

        // 通知コンテンツを作成
        let content = UNMutableNotificationContent()
        content.title = "ゴミの収集日です"
        content.body = "今日は\(garbageType)の収集日です。"

        // 現在の年月を取得
        let currentDate = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)

        // 第何曜日の日付を計算
        guard let weekIndex = ["第一", "第二", "第三", "第四", "第五"].firstIndex(of: weekOfMonth),
              let weekday = yobiToWeekday(yobi) else {
            print("曜日または週の指定が不正確です")
            return
        }

        // 最初の日から最初の曜日までの日数を計算
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1
        let firstDayOfMonth = calendar.date(from: dateComponents)!

        let dayOfWeek = calendar.component(.weekday, from: firstDayOfMonth)
        var daysToAdd = weekday - dayOfWeek
        if daysToAdd < 0 {
            daysToAdd += 7
        }
        dateComponents.day! += daysToAdd + (weekIndex * 7)

        // 通知タイミングを前日にずらす
        if dateType == .theDayBefore {
            dateComponents.day! -= 1
            content.body = "明日は\(garbageType)の収集日です。"
        }
        
        // 通知の時刻を設定
        let notificateCalendar = Calendar.current
        let notificateDate = notificateCalendar.date(bySettingHour: notificateCalendar.component(.hour, from: notificateTime), minute: notificateCalendar.component(.minute, from: notificateTime), second: 0, of: currentDate)!

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
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



    // MARK: - 通知削除メソッド
    func removeAllNotifications() {
        let center = UNUserNotificationCenter.current()
        
        // すべての通知を削除
        center.removeAllPendingNotificationRequests()
        
        // 通知センターからも削除
        center.removeAllDeliveredNotifications()
    }
    // MARK: - 曜日変換メソッド
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
