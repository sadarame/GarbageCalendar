//
//  File.swift
//  dustCalrendar
//
//  Created by Yosuke Yoshida on 2023/04/02.
//

import Foundation
import MapKit

class Geocoder {
    // ジオコーディング
    func geocoding(){
        let locationManager = CLLocationManager()
      
        let address = "東京都墨田区押上１丁目１−２" // 東京スカイツリーの住所
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            if let lat = placemarks?.first?.location?.coordinate.latitude {
                print("緯度 : \(lat)")
            }
            if let long = placemarks?.first?.location?.coordinate.longitude {
                print("経度 : \(long)")
            }
        }
    }
    
    func reverseGeocoding(){
        
        let location = CLLocation()

        let geocoder = CLGeocoder()
        
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let post = placemarks?.first?.postalCode {
                    print("郵便番号 : \(post)")
            }
        }
    }
}
