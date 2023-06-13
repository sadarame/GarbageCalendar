//
//  UserDafaultManager.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/05/28.
//

import Foundation

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
