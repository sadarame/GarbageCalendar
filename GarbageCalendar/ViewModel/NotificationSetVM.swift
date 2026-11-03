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
        if !model.isNotificationEnabled {
            changeNotificateSetting()
            return
        }
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    // 通知が許可されている場合
                    print("通知が許可されています")
                    // 通知の有効状態を保存
                    UIApplication.shared.registerForRemoteNotifications()
                    self.changeNotificateSetting()
                case .denied:
                    // 通知が拒否されている場合
                    print("通知が拒否されています")
                    // ポップアップを表示して通知許可を求める
                    self.requestNotificationPermission()
                case .notDetermined:
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
                    UIApplication.shared.registerForRemoteNotifications()
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
    
    // Persist the desired setting locally; show server acknowledgement separately.
    func changeNotificateSetting() {
        tmpModel = model
        saveNotificateModel(model)
        Task { @MainActor in NotificationServerSync.shared.enqueue() }
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

// Requests are serialized so a slower ON request cannot overwrite a later OFF.
import FirebaseAuth
import FirebaseFunctions
import FirebaseMessaging

@MainActor
final class NotificationServerSync: ObservableObject {
    static let shared = NotificationServerSync()
    @Published var status = "通知設定は未同期です"
    private var pending: Task<Void, Never>?
    private var suspended = false

    func suspendForReset() async {
        suspended = true
        await pending?.value
    }

    func resumeAfterReset() {
        suspended = false
        status = "通知設定は未同期です"
    }

    func enqueue() {
        guard !suspended else { return }
        let previous = pending
        pending = Task {
            await previous?.value
            await syncLatest()
        }
    }

    private func syncLatest() async {
        guard !suspended, let setting = loadNotificateModel() else { return }
        status = "通知設定を同期中…"
        do {
            try await CollectionAPI.shared.authenticate()
            let clock = Calendar.current
            let formatter = DateFormatter()
            formatter.calendar = ScheduleEngine.calendar
            formatter.timeZone = ScheduleEngine.calendar.timeZone
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd"
            let rules = loadGarbageRegistModels().map { original in
                var rule = original
                if rule.strDate.isEmpty { rule.strDate = formatter.string(from: rule.date) }
                return rule
            }
            let encoded = try JSONEncoder().encode(rules)
            let ruleObjects = try JSONSerialization.jsonObject(with: encoded)
            var payload: [String: Any] = [
                "settings": ["enabled": setting.isNotificationEnabled,
                             "previousDay": setting.dateType == .theDayBefore,
                             "hour": clock.component(.hour, from: setting.notificateTime),
                             "minute": clock.component(.minute, from: setting.notificateTime),
                             "timeZone": "Asia/Tokyo"],
                "rules": setting.isNotificationEnabled ? ruleObjects : []
            ]
            if setting.isNotificationEnabled {
                payload["fcmToken"] = try await Messaging.messaging().token()
            }
            _ = try await Functions.functions(region: "asia-northeast1")
                .httpsCallable("saveNotificationSettingsV2").call(payload)
            // Only retire legacy local reservations after the server accepts ownership.
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            UserDefaults.standard.set(true, forKey: "serverNotificationsActivated")
            status = setting.isNotificationEnabled ? "サーバー通知に同期済み" : "通知OFFに同期済み"
        } catch {
            status = "未同期：通信を確認して再試行してください。変更前の通知設定が残る場合があります。"
        }
    }
}
