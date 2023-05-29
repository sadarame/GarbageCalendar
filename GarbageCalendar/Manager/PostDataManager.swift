//
//  PostDataManager.swift
//  dustCalrendar
//
//  Created by Yosuke Yoshida on 2023/02/25.
//

import Foundation

class PostDataManager {

func loginAPI() {
    print("login api")
    let url = URL(string: "http://127.0.0.1:8000/api-auth/login/")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST" // POSTリクエスト
    request.httpBody = "username=hoge&password=hoge123".data(using: .utf8) // Bodyに情報を含める
    URLSession.shared.dataTask(with: request, completionHandler: {(data, response, error) in
        print("data: \(String(describing: data))")
        print("response: \(String(describing: response))")
        print("error: \(String(describing: error))")
        print("------------------------------------")
        do{
            let responseData = try JSONSerialization.jsonObject(with: data!, options: [])
            print(responseData)
            }
            catch {
                print(error)
            }
    }).resume()
}
}
