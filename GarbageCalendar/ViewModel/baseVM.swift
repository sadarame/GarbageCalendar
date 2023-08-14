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

