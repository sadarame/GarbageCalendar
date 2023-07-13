//
//  UserAddressVM.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/06/06.
//

import Foundation
import CoreLocation

class UserAddressRegistVM: BaseVM {
    // モデルを変数
    @Published var model: UserAddressRegistModel = UserAddressRegistModel()
    //画面遷移用のフラグ
    @Published var activie:Bool = false
    
    //住所情報取用のクラス
    private let locationManager = CLLocationManager()
    
    //初期処理
    override init() {
        //ユーザーデフォルトから住所情報を取得
        if let model = loadUserAddressRegistModel() {
            self.model = model
        }
    }
    
    //初期表示時の処理
    func onapperInit(){
        //ユーザIDが取得できない場合は
        if model.userId == "" {
            //APIコール
            callGetUserIDAPI()
        }
    }
    
    //バリデーションチェック
    func validateInputFields() -> Bool {
        let isPostalCodeValid = !model.postalCode.isEmpty
        let isAdministrativeAreaValid = !model.administrativeArea.isEmpty
        let isLocalityValid = !model.locality.isEmpty
        let isThoroughfareValid = !model.thoroughfare.isEmpty
        let isSubThoroughfareValid = true // 必須ではないのでチェックなし
        let isBuildNameValid = true // 必須ではないのでチェックなし
        
        return isPostalCodeValid && isAdministrativeAreaValid && isLocalityValid && isThoroughfareValid && isSubThoroughfareValid && isBuildNameValid
    }
    
    //位置情報取得
    func requestLocation(){
//        if (locationManager.authorizationStatus == .authorizedWhenInUse) {
            isShowProgres = true
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.delegate = self
            locationManager.requestLocation()
//        }
    }
    
    //緯度情報と住所情報を変換
    private func getAddressFromCoordinates() {
        guard let latitude = locationManager.location?.coordinate.latitude,
              let longitude = locationManager.location?.coordinate.longitude else {
            return
        }
        
        model.latitude = String(latitude)
        model.longitude = String(longitude)
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                // 住所を取得
                self.model.postalCode = placemark.postalCode ?? ""
                self.model.administrativeArea = placemark.administrativeArea ?? ""
                self.model.subAdministrativeArea = placemark.subAdministrativeArea ?? ""
                self.model.locality = placemark.locality ?? ""
                self.model.subLocality = placemark.subLocality ?? ""
                self.model.thoroughfare = placemark.thoroughfare ?? ""
                self.model.subThoroughfare = placemark.subThoroughfare ?? ""
                //名前に丁目を設定
                //                self.model.UserAddressName = self.model.thoroughfare
                //プログレスバーを非表示
                self.isShowProgres = false
            }
        }
    }
    
    //データモデルをUserDefaultとサーバに登録
    func registUserInfo(){
        
    }
    
    // ユーザ情報登録
    func callRegistUserInfoAPI(completion: @escaping (Result<Void, Error>) -> Void) {
        
        // ゴミ情報リストをJSONデータに変換
        let jsonData = try! JSONEncoder().encode(model)
        // JSONデータを文字列に変換
        let jsonString = String(data: jsonData, encoding: .utf8)
        // リクエストパラメータを作成
        let requestBody = [
            "TYPE": Const.TYPE_REGIST_USER_INFO,
            "API_KEY": Const.API_KEY,
            "USER_INFO": jsonString
        ]
        // JSONにデータ変換
        let jsonRequestBody = try! JSONSerialization.data(withJSONObject: requestBody)
        
        // APIのコール
        fetchDataFromAPI(url: Const.URL_API_CALL, type: Const.TYPE_REGIST_GARBAGE_INFO, jsonData: jsonRequestBody) { (result: Result<UserRegistRes, Error>) in
            
            switch result {
            case .success(let responseData):
                // ステータスに登録状況をセット
                if responseData.status == Const.STATUS_SUCCSESS {
                    completion(.success(()))
                } else {
                    completion(.failure(APIError.noData))
                }
                
            case .failure(let error):
                // エラー時の処理
                completion(.failure(error))
            }
        }
    }
    
    //ユーザID払出し
    func callGetUserIDAPI(){
        //プログレス表示
        isShowProgres = true
        //編集不可
        isDisEditable  = true
        //パラメタ作成
        let requestBody = [
            "TYPE":Const.TYPE_GET_USER_ID,
            "API_KEY":Const.API_KEY
        ]
        // JSONにデータ変換
        let jsonRequestBody = try! JSONSerialization.data(withJSONObject: requestBody)
        
        //APIのコール
        fetchDataFromAPI(url: Const.URL_API_CALL, type: Const.TYPE_GET_USER_ID,jsonData:jsonRequestBody) { [self] (result: Result<ResponseData, Error>) in
            DispatchQueue.main.async {
                switch result {
                    
                case .success(let responseData):
                    
                    //ユーザーデフォルトに保存
                    self.model.userId = responseData.userId
                    saveUserAddressRegistModel(self.model)
                    //編集不可を解除
                    self.isDisEditable  = false
                    
                case .failure(let error):
                    // エラー時の処理
                    self.showPopup(withMessage: "ユーザIDの払い出しに失敗しました。やり直してください")
                    
                    print("Error: \(error)")
                }
                //通信終わりのため、プログレス非表示に
                self.isShowProgres = false
            }
        }
    }
    
    //郵便番号から住所情報を取得する
    func callGetAddressAPI() {
        //プログレスバー表示
        isShowProgres = true
        
        let strURL = Const.URL_ZIPCODE_API + model.postalCode
        guard let url = URL(string: strURL) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            
            guard let jsonData = data else { return }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(ApiAddressResponse.self, from: jsonData)
                DispatchQueue.main.async {
                    //住所情報をモデルにセット
                    self.model.administrativeArea = response.results?.first?.address1 ?? ""
                    self.model.locality = response.results?.first?.address2 ?? ""
                    self.model.thoroughfare = response.results? .first?.address3 ?? ""
                    //番地までは取れないから空文字で更新
                    self.model.subThoroughfare = ""
                    self.model.subLocality = ""
                    self.model.subAdministrativeArea = ""
                    
                    //名前に丁目を設定
                    //                    self.model.UserAddressName = self.model.thoroughfare
                    //プログレスバー非表示
                    self.isShowProgres = false
                }
            } catch {
                //プログレスバー非表示
                self.isShowProgres = false
                print("Error: \(error)")
            }
        }.resume()
    }
    
    //手入力された住所を緯度経度に変換
    func getCoordinatesFromAddress(completion: @escaping (Result<(String, String), Error>) -> Void) {
        let address = model.administrativeArea + model.locality + model.thoroughfare + model.subThoroughfare
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let placemark = placemarks?.first {
                let coordinates = placemark.location?.coordinate
                if let latitude = coordinates?.latitude, let longitude = coordinates?.longitude {
                    completion(.success((String(latitude), String(longitude))))
                } else {
                    completion(.failure(NSError(domain: "GeocodingError", code: 0, userInfo: nil)))
                }
            } else {
                completion(.failure(NSError(domain: "GeocodingError", code: 0, userInfo: nil)))
            }
        }
    }
    
    // 次へボタンが押されたときの処理
    //緯度経度の取得処理と登録処理を呼び出す
    func onNextButtonTapped() {
    
        //プログレス表示,編集不可
        isShowProgres = true
        isDisEditable = true
        
        //緯度経度取得処理
        getCoordinatesFromAddress { result in
            switch result {
            case .success(let (latitude, longitude)):
                // 緯度と経度をモデルにセット
                self.model.latitude = latitude
                self.model.longitude = longitude
            case .failure(let error):
                // エラーハンドリング
                print("Error: \(error)")
            }
            
            //登録API呼び出し
            self.callRegistUserInfoAPI { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success():
                        //次画面に遷移
                        self.activie = true
                        
                    case .failure(let error):
                        // ユーザ情報登録失敗時の処理
                        self.showPopup(withMessage: "ユーザ情報登録でエラーが発生しました。")
                        print("ユーザ情報登録エラー: \(error)")
                    }
                    // プログレス表示、編集不可
                    self.isShowProgres = false
                    self.isDisEditable = false
                }
                //入力された情報をユーザデフォルトに保存
                saveUserAddressRegistModel(self.model)
            }
        }
    }
    
}

//デリゲートメソッド（実装必須）
extension UserAddressRegistVM: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //位置情報が更新された場合の処理
        getAddressFromCoordinates()
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 位置情報の取得に失敗した場合の処理を記述
        self.showPopup(withMessage: "位置情報を取得できませんでした。")
        self.isShowProgres = false
        
    }
}

