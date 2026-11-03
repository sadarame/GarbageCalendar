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

struct GetGarbageInfoRes: Codable {
    let status: String
    let result: [GarbageItemRes]
    let message: String
}

struct GarbageItemRes: Codable {
    let id: String
    let garbageType: String
    let schedule: String
    let yobi: String?
    let day: String?
    let month: String?
    let date: String?
    let weekOfMonth: String?
    let freqWeek: String?
}

// Postal codes are resolved against the postal directory before geocoding an address.
enum PostalCodeLookup {
    enum LookupError: LocalizedError {
        case invalid, notFound, unavailable
        var errorDescription: String? {
            switch self {
            case .invalid: return "郵便番号を7桁で入力してください。"
            case .notFound: return "この郵便番号の住所が見つかりませんでした。番号を確認してください。"
            case .unavailable: return "住所を取得できませんでした。通信を確認して再試行してください。"
            }
        }
    }

    static func normalize(_ value: String) throws -> String {
        let text = (value.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? value)
            .replacingOccurrences(of: "〒", with: "")
            .filter { !$0.isWhitespace && !"-−‐‑–—ー".contains($0) }
        guard text.count == 7, text.allSatisfy({ $0.isASCII && $0.isNumber }) else {
            throw LookupError.invalid
        }
        return text
    }

    static func addresses(for input: String, session: URLSession = .shared) async throws -> [ApiAddress] {
        let code = try normalize(input)
        var components = URLComponents(string: "https://zipcloud.ibsnet.co.jp/api/search")!
        components.queryItems = [URLQueryItem(name: "zipcode", value: code), URLQueryItem(name: "limit", value: "1000")]
        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 20
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw LookupError.unavailable }
        let result = try JSONDecoder().decode(ApiAddressResponse.self, from: data)
        guard result.status == 200 else { throw LookupError.unavailable }
        let matches = (result.results ?? []).filter { $0.zipcode == code }
        guard !matches.isEmpty else { throw LookupError.notFound }
        return matches
    }
}

extension ApiAddress {
    var displayAddress: String { address1 + address2 + address3 }
    var geocodingAddress: String {
        address1 + address2 + (address3 == "以下に掲載がない場合" ? "" : address3)
    }
}
