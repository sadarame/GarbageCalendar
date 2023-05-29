//
//  BaseVM.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/05/29.
//

import Foundation

class BaseVM: ObservableObject {
    
    @Published var isLoading: Bool = false
    var requestBody:[String:String]
    
    init(){
        
    }

    //通信用のメソッド（各VMから呼び出す）
    func fetchDataFromAPI<T: Decodable>(url: String, type:String,completion: @escaping (Result<T, Error>) -> Void) {
        guard let request = URLRequest(url:URL(string: url)!) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        //TODO:あとでスイッチ分にするかも
        if type == Const.TYPE_GET_USER_ID {
            //リクエスト値を設定
            requestBody = [
                "TYPE":Const.TYPE_GET_USER_ID,
                "API_KEY":Const.API_KEY
            ]
            
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let jsonData = try? JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
        }
        
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
