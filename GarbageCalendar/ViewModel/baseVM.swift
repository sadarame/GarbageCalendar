//
//  BaseVM.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/05/29.
//

import Foundation

class BaseVM: NSObject, ObservableObject {
    
    @Published var isLoading: Bool = false

    //引数ありでAPIコールする用のメソッド
    func fetchDataFromAPI<T: Decodable>(url: String, type:String, jsonData:Data, completion: @escaping (Result<T, Error>) -> Void) {
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

//サーバーからの返却値を定義
struct ResponseData: Codable {
    let status: String
    let userId: String
    let message: String
}

struct GarbageRegistRes: Codable {
    let status: String
    let message: String
}

