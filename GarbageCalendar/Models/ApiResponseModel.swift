//
//  ApiResponseModel.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/06/07.
//

import Foundation

struct ApiAddressResponse: Codable {
    let message: String?
    let results: [ApiAddress]?
    let status: Int
}

struct ApiAddress: Codable {
    let address1: String
    let address2: String
    let address3: String
    let kana1: String
    let kana2: String
    let kana3: String
    let prefcode: String
    let zipcode: String
}
