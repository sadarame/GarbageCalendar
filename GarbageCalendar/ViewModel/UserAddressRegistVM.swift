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
    //プログレスエフェクト表示制御
    @Published var isShowProgres = false
    //住所情報取
    private let locationManager = CLLocationManager()
    
    //位置情報取得
    func requestLocation(){
        isShowProgres = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestLocation()
        self.getAddressFromCoordinates()
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
                self.model.UserAddressName = self.model.thoroughfare
                //プログレスバーを非表示
                self.isShowProgres = false
            }
        }
    }
    
    //データモデルをUserDefaultとサーバに登録
    func registUserInfo(){
        
    }
    
    //ユーザ情報登録
    func callRegistUserInfoAPI(){
        
    }
    
    //ユーザID払出し
    func callGetUserIDAPI(){
        
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
                    //名前に丁目を設定
                    self.model.UserAddressName = self.model.thoroughfare
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
    func getCoordinatesFromAddress(address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let placemark = placemarks?.first {
                let coordinates = placemark.location?.coordinate
                completion(coordinates)
            } else {
                completion(nil)
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
    }
}

