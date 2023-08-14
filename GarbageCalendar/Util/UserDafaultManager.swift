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



