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


