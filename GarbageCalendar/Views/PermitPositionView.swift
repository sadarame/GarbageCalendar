//
//  LocationSetView.swift
//  dustCalrendar
//
//  Created by Yosuke Yoshida on 2023/03/20.
//

import SwiftUI
import _CoreLocationUI_SwiftUI

struct PermitPositionView: View {
    
    @ObservedObject var locationClient = LocationClient()
    @State var isActive = false
    @State var isGetLocation = false
    
    //位置情報の取得の許可を得るためのView
    var body: some View {
        NavigationStack {
            VStack{
                Spacer()
                //位置情報取得後
                if locationClient.didRequest {
                    
                    //
                    Text(Const.locationViewMsg3)
                    //次へ
                    Button("次へ"){
                        isActive = true
                    }
                    
                //位置情報取得前
                } else {
                    //文言１
                    Text(Const.locationViewMsg1)
                    // 位置情報許可ボタン
                    LocationButton(.currentLocation) {
                        locationClient.requestLocation()
                    }
                    //文言２
                    Text(Const.locationViewMsg2)
                }
                
                if (locationClient.requesting) {
                    ScaleEffectProgressView(5)
                    Text("位置情報取得中・・")
                }
                Spacer()
            }
        }
        .navigationDestination(isPresented: $isActive) {
            AddressRegistView(locationClient:locationClient)
        }
    }}


