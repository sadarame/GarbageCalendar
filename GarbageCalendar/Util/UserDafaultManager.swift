//
//  UserDafaultManager.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/05/28.
//

import Foundation

func saveGarbageInfoName(_ name: String) {
    UserDefaults.standard.set(name, forKey: "garbageInfoName")
}

func loadGarbageInfoName() -> String? {
    return UserDefaults.standard.string(forKey: "garbageInfoName")
}


func saveUserID(_ userID: String) {
    UserDefaults.standard.set(userID, forKey: "userID")
}

func loadUserID() -> String? {
    return UserDefaults.standard.string(forKey: "userID")
}

func saveGarbageRegistModels(_ models: [GarbageRegistModel]) {
    do {
        let data = try JSONEncoder().encode(models)
        UserDefaults.standard.set(data, forKey: "garbageRegistModels")
        
        //Widget用データの保存
        if let userDefaults = UserDefaults(suiteName: "group.yosuke.GarbageCalendar.Widget") {
            userDefaults.set(data, forKey: "garbageRegistModels")
        }
        
    } catch {
        print("Failed to save garbage regist models: \(error)")
    }
}

func loadGarbageRegistModels() -> [GarbageRegistModel] {
    if let data = UserDefaults.standard.data(forKey: "garbageRegistModels") {
        do {
            let models = try JSONDecoder().decode([GarbageRegistModel].self, from: data)
            return models
        } catch {
            print("Failed to load garbage regist models: \(error)")
        }
    }
    return []
}

func saveUserAddressRegistModel(_ model: UserAddressRegistModel) {
    do {
        let data = try JSONEncoder().encode(model)
        UserDefaults.standard.set(data, forKey: "userAddressRegistModel")
    } catch {
        print("Failed to save UserAddressRegistModel: \(error)")
    }
}

func loadUserAddressRegistModel() -> UserAddressRegistModel? {
    if let data = UserDefaults.standard.data(forKey: "userAddressRegistModel") {
        do {
            let model = try JSONDecoder().decode(UserAddressRegistModel.self, from: data)
            return model
        } catch {
            print("Failed to load UserAddressRegistModel: \(error)")
        }
    }
    return nil
}

func saveGarbageAreaConvModel(_ model: GarbageAreaConvModel) {
    do {
        let data = try JSONEncoder().encode(model)
        UserDefaults.standard.set(data, forKey: "garbageAreaConvModel")
    } catch {
        print("Failed to save GarbageAreaConvModel: \(error)")
    }
}

func loadGarbageAreaConvModel() -> GarbageAreaConvModel? {
    if let data = UserDefaults.standard.data(forKey: "garbageAreaConvModel") {
        do {
            let model = try JSONDecoder().decode(GarbageAreaConvModel.self, from: data)
            return model
        } catch {
            print("Failed to load GarbageAreaConvModel: \(error)")
        }
    }
    return nil
}

func saveTriggerFlg(_ trigger: Int) {
    UserDefaults.standard.set(trigger, forKey: "triggerFlg")
}

func loadTriggerFlg() -> Int? {
    return UserDefaults.standard.integer(forKey: "triggerFlg")
}


func saveDestination(_ destination: String) {
    UserDefaults.standard.set(destination, forKey: "destination")
}

func loadDestination() -> String? {
    return UserDefaults.standard.string(forKey: "destination")
    
}

// FCMトークンを保存するメソッド
func saveFCMToken(_ token: String) {
    UserDefaults.standard.set(token, forKey: "fcmToken")
}

// 保存されたFCMトークンを読み込むメソッド
func loadFCMToken() -> String? {
    return UserDefaults.standard.string(forKey: "fcmToken")
}

func saveIsShowNavigateAddress(_ value: String) {
    UserDefaults.standard.set(value, forKey: "isShowNavigateAddress")
}

// UserDefaultsからisShowNavigateAddressを読み込むメソッド（String型）
func loadIsShowNavigateAddress() -> String? {
    return UserDefaults.standard.string(forKey: "isShowNavigateAddress")
}


func saveIsShowNavigateMap(_ value: String) {
    UserDefaults.standard.set(value, forKey: "isShowNavigateMap")
}

// UserDefaultsからisShowNavigateAddressを読み込むメソッド（String型）
func loadIsShowNavigateMap() -> String? {
    return UserDefaults.standard.string(forKey: "isShowNavigateMap")
}

func saveIsNotificationEnabled(_ value: Bool) {
    UserDefaults.standard.set(value, forKey: "isNotificationEnabled")
}

func loadIsNotificationEnabled() -> Bool {
    return UserDefaults.standard.bool(forKey: "isNotificationEnabled")
}


func saveNotificateModel(_ model: NotificateModel) {
    do {
        let data = try JSONEncoder().encode(model)
        UserDefaults.standard.set(data, forKey: "NotificateModel")
    } catch {
        print("Failed to save GarbageAreaConvModel: \(error)")
    }
}

func loadNotificateModel() -> NotificateModel? {
    if let data = UserDefaults.standard.data(forKey: "NotificateModel") {
        do {
            let model = try JSONDecoder().decode(NotificateModel.self, from: data)
            return model
        } catch {
            print("Failed to load NotificateModel: \(error)")
        }
    }
    return nil
}

func saveIsFisrstOpenCalendar(_ value: Bool) {
    UserDefaults.standard.set(value, forKey: "isFirstLoadCalendar")
}

func loadIsFisrstOpenCalendar() -> Bool {
    return UserDefaults.standard.bool(forKey: "isFirstLoadCalendar")
}
