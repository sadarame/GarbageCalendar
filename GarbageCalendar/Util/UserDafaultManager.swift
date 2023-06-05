//
//  UserDafaultManager.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/05/28.
//

import Foundation

struct Person: Codable {
    var name: String
    var age: Int
}

func savePerson(_ person: Person) {
    let encoder = JSONEncoder()
    if let encodedData = try? encoder.encode(person) {
        UserDefaults.standard.set(encodedData, forKey: "person")
    }
}

func loadPerson() -> Person? {
    if let savedData = UserDefaults.standard.data(forKey: "person") {
        let decoder = JSONDecoder()
        if let loadedPerson = try? decoder.decode(Person.self, from: savedData) {
            return loadedPerson
        }
    }
    return nil
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
