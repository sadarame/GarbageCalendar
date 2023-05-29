//
//  UserDataAccess.swift
//  dustCalrendar
//
//  Created by Yosuke Yoshida on 2023/02/17.
//

import Foundation
import RealmSwift

// テーブル
class Shop: Object {
    @Persisted  var name = ""   // カラム
    @Persisted  var menu:Menu?  // カラム
}

// テーブル
class Menu: Object {
    @Persisted  var name = ""  // カラム
    @Persisted  var price = 0  // カラム
}
