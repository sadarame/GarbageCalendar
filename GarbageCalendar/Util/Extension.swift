//
//  Extension.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/06/05.
//

import Foundation

//Json変換するための拡張
extension Encodable {
    func toJSONData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(self)
    }

    func toJSONString() throws -> String {
        let data = try toJSONData()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
