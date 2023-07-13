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

//自前APIの返却値を定義
struct ResponseData: Codable {
    let status: String
    let userId: String
    let message: String
}

struct GarbageRegistRes: Codable {
    let status: String
    let message: String
}

struct UserRegistRes: Codable {
    let status: String
    let message: String
}

struct GarbageAreaRes: Codable {
    let status: String
    let result:[GarbageAreaConvModel]
    let message: String
}

struct ResultAPI: Codable {
    let No: String
    let postalCode: String
    let administrativeArea: String
    let locality: String
    let thoroughfare: String
    let garbageGroupId: String
    let officialFlag: String?
    let usageCount: String
    let garbageInfoName: String
    let latitude: String
    let longitude: String
}

struct GarbageInfoRes: Codable {
    let status: String
    let result:[GarbageRegistModel]
    let message: String
}
