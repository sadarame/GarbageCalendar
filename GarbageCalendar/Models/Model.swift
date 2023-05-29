//
//  Model.swift
//  dustCalrendar
//
//  Created by Yosuke Yoshida on 2023/02/25.
//

import Foundation // Model は SwiftUI をインポートしない

struct Model {

    enum Pet:String { // ケースは犬か猫か
        case 🐶
        case 🐱
    }

    var pet: Pet = .🐶 // 初期値は犬

    mutating func switchPet() { // 犬と猫を切り替える関数
        if pet == .🐶 {
            pet = .🐱
        } else {
            pet = .🐶
        }
    }

}
