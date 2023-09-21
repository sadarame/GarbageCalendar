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

    //引数ありでAPIコールする用のメソッド
    func fetchDataFromAPI<T: Decodable>(url: String, type:String, jsonData:Data, completion: @escaping (Result<T, Error>) -> Void) {
        
        isShowProgres = true
            isDisEditable = true
        
        guard let url = URL(string: url) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        //リクエスト作成
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //引数で受け取ったjsonを設定
        request.httpBody = jsonData
        
        isLoading = true
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                self.isLoading = false
                self.isShowProgres = false
                self.isDisEditable = false
            }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
//                logData(data)
                let decodedData = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

enum APIError: Error {
    case invalidURL
    case noData
}

func logData(_ data: Data) {
    if let jsonString = String(data: data, encoding: .utf8) {
        print(jsonString)
    } else {
        print("Invalid data")
    }
    

}



