//
//  NoticateVM.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/09/15.
//

import Foundation
import SwiftUI

class NotificationSetVM: BaseVM {
    
    @Published var isNotificationEnabled = false
    @Published var selectedDate = "当日"
    @Published var selectionDate = Date()
    
    @Published var isAlertPresented = false

    //モデル変数のリスト
    @Published var garbageRegistModelList:[GarbageRegistModel] = []
    
    //初期処理
    override init() {
        //登録したゴミ情報を取得
        garbageRegistModelList = loadGarbageRegistModels()
        // 通知設定をを読み込む
        isNotificationEnabled = loadIsNotificationEnabled()
        
       
    }
    
    func onApperInit(){
        //アラートメッセージの表示
        self.navigateKey = Const.KEY_NOTIFICATE
        self.navigateText = Const.INFO_MESSAGE_3
    }
 
    
    // 通知許可ステータスを確認する関数
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    // 通知が許可されている場合
                    print("通知が許可されています")
                    // 通知の有効状態を保存
                    self.saveIsNotificationEnabled(self.isNotificationEnabled)
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
                    self.saveIsNotificationEnabled(self.isNotificationEnabled)
                } else {
                    // ユーザーが拒否またはエラーが発生した場合
                    print("通知が拒否またはエラーが発生しました")
                    self.isShowNavigate = true
                    self.isNotificationEnabled = false
                    self.saveIsNotificationEnabled(self.isNotificationEnabled)
                    print(self.isAlertPresented )
                }
            }
        }
    }

    // isNotificationEnabledの値を保存する関数
    func saveIsNotificationEnabled(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: "isNotificationEnabled")
    }
}







    
    
    

