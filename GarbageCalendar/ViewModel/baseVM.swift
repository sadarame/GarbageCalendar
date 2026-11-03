//
//  BaseVM.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/05/29.
//

import Foundation
import SwiftUI

class BaseVM: NSObject, ObservableObject {
    
    @Published var isLoading: Bool = false
    //プログレスエフェクト表示制御
    @Published var isShowProgres = false
    //エラーメッセージ
    @Published var isShowingPopup: Bool = false
    @Published var popupMessage: String = ""
    
    //編集不可フラグ
    @Published var isDisEditable: Bool = false
    
    //AppStore更新ありフラグ
    @Published var isAlertAppStore: Bool = false
    @Published var currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    @Published private var latestAppVersion = ""
    
    
    //ナビゲーション用のフラグ
    @Published var isShowNavigate:Bool = false
    var navigateText:String = ""
    var navigateKey:String = ""
    
    func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
   
    //Appストアのバージョン確認
    func fetchAppStoreVersion(){
        guard let appStoreURL = URL(string: "https://itunes.apple.com/lookup?id=6459478923") else {
//            completion(.failure(NSError(domain: "", code: -1, userInfo: nil)))
            print("エラー")
            return
        }
        
        let task = URLSession.shared.dataTask(with: appStoreURL) { data, _, error in
            if let data = data,
               let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let results = response["results"] as? [[String: Any]],
               let latestAppVersion = results.first?["version"] as? String {
                
                if latestAppVersion != self.currentAppVersion {
                    self.isAlertAppStore = true
                }
                
            } else {
                print("エラー")
            }
        }
        
        task.resume()
    }
    
    func openAppStore() {
        guard let appStoreURL = URL(string: "https://itunes.apple.com/app/6459478923") else {
            return
        }
        UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
    }

    
    
    // ポップアップを表示するメソッド
    func showPopup(withMessage message: String) {
        popupMessage = message
        isShowingPopup = true
    }
    
    // ポップアップを非表示にするメソッド
    func hidePopup() {
        isShowingPopup = false
    }

}

import FirebaseAuth
import FirebaseFunctions

@MainActor
final class CollectionAPI {
    static let shared = CollectionAPI()
    private var login: Task<Void, Error>?
    private var contributionSync: Task<Void, Error>?

    func waitForAuthentication() async throws {
        if let login { try await login.value }
    }

    func authenticate() async throws {
        if let login { return try await login.value }
        guard Auth.auth().currentUser == nil else { return }
        let task = Task { _ = try await Auth.auth().signInAnonymously() }
        login = task
        defer { login = nil }
        try await task.value
    }

    func call<T: Decodable>(_ endpoint: String, data: [String: Any]) async throws -> T {
        try await authenticate()
        let result = try await Functions.functions(region: "asia-northeast1").httpsCallable(endpoint).call(data)
        let bytes = try JSONSerialization.data(withJSONObject: result.data)
        return try JSONDecoder().decode(T.self, from: bytes)
    }

    // Recover schedules saved locally by the earlier opt-in version.
    func syncSavedContributionIfNeeded() async throws {
        if let contributionSync { return try await contributionSync.value }
        guard !UserDefaults.standard.bool(forKey: "collection.hasPublishedContribution") else { return }
        let saved = loadGarbageRegistModels()
        guard !saved.isEmpty,
              let area = loadUserAddressRegistModel(),
              let latitude = Double(area.latitude), let longitude = Double(area.longitude) else { return }
        let name = loadGarbageInfoName().flatMap { $0.isEmpty ? nil : $0 } ?? "この地域の収集予定"
        let task = Task { @MainActor in
            let _: SharedSaveResponse = try await self.call("saveSharedScheduleV2", data: [
                "name": name, "latitude": latitude, "longitude": longitude,
                "rules": try Self.rules(saved)])
            UserDefaults.standard.set(true, forKey: "collection.hasPublishedContribution")
        }
        contributionSync = task
        defer { contributionSync = nil }
        try await task.value
    }

    static func rules(_ models: [GarbageRegistModel]) throws -> Any {
        let formatter = DateFormatter()
        formatter.calendar = ScheduleEngine.calendar
        formatter.timeZone = ScheduleEngine.calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let normalized = models.map { original in
            var model = original
            if model.strDate.isEmpty { model.strDate = formatter.string(from: model.date) }
            return model
        }
        return try JSONSerialization.jsonObject(with: JSONEncoder().encode(normalized))
    }
}

struct SharedSearchResponse: Decodable {
    let result: [GarbageAreaConvModel]
    let truncated: Bool
}
struct SharedSaveResponse: Decodable { let id: String }
struct SharedWithdrawResponse: Decodable { let withdrawn: Bool }
struct SharedScheduleResponse: Decodable {
    let sourceUrl: String?
    let id: String
    let name: String
    let rules: [SharedRule]
}
struct SharedRule: Decodable {
    let garbageType: String
    let iconType: String?
    let schedule: String
    let yobi: String?
    let day: Int?
    let weekOfMonth: String?
    let freqWeek: String?
    let strDate: String?
    let validFrom: String?
    let validTo: String?
    let specificDates: [String]?
    let excludedDates: [String]?
    let additionalDates: [String]?

    func model() -> GarbageRegistModel {
        var result = GarbageRegistModel()
        result.garbageType = garbageType
        result.iconType = iconType
        result.schedule = schedule
        result.validFrom = validFrom
        result.validTo = validTo
        result.specificDates = specificDates
        result.excludedDates = excludedDates
        result.additionalDates = additionalDates
        if let yobi { result.yobi = yobi }
        if let day { result.day = day }
        if let weekOfMonth { result.weekOfMonth = weekOfMonth }
        if let freqWeek { result.freqWeek = freqWeek }
        if let strDate {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = .current
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: strDate) { result.date = date }
            result.strDate = strDate
        }
        return result
    }
}


/// Reset the entire navigation tree only after server cleanup and identity deletion succeed.
@MainActor
final class UserSession: ObservableObject {
    static let shared = UserSession()
    @Published var generation = UUID()
    @Published var isResetting = false

    func reset() async throws {
        guard !isResetting else { return }
        isResetting = true
        await NotificationServerSync.shared.suspendForReset()
        defer {
            isResetting = false
            NotificationServerSync.shared.resumeAfterReset()
        }
        // Await an in-flight anonymous login before deciding which identity to delete.
        try await CollectionAPI.shared.syncSavedContributionIfNeeded()
        try await CollectionAPI.shared.waitForAuthentication()
        if let user = Auth.auth().currentUser {
            let _: UserResetResponse = try await CollectionAPI.shared.call("resetUserDataV2", data: [:])
            try await user.delete()
        }
        try Auth.auth().signOut()
        clearLocalUserData()
        generation = UUID()
    }
}

struct UserResetResponse: Decodable { let reset: Bool }
