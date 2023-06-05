//
//  AdrSetView.swift
//  dustCalrendar
//
//  Created by Yosuke Yoshida on 2023/03/22.
//

import SwiftUI
import RealmSwift

struct AddressRegistView: View {
 
    @ObservedObject var vm:AddressRegistVM = AddressRegistVM()
    @State var locationClient:LocationClient
    
    @State var isActive = false
    
    var body: some View {
        NavigationStack {
            VStack{
                HStack{
                    Text("ユーザID")
                    Text(vm.userNo)
                }
                
                HStack{
                    Text("郵便番号")
                    TextField("", text: $vm.postalCode)
                }
                HStack{
                    Text("都道府県")
                    //                TextField("", text: $vm.pref_nm.toUnwrapped(defaultValue: ""))
                    TextField("", text: $vm.administrativeArea)
                }
                HStack{
                    Text("郡")
                    //                TextField("", text: $vm.pref_nm.toUnwrapped(defaultValue: ""))
                    TextField("", text: $vm.subAdministrativeArea)
                }
                HStack{
                    Text("市区町村")
                    TextField("", text: $vm.locality)
                }
                HStack{
                    Text("丁目")
                    TextField("", text: $vm.thoroughfare)
                }
                HStack{
                    Text("番地")
                    TextField("任意", text: $vm.subThoroughfare)
                }
                HStack{
                    Text("建物名")
                    TextField("", text: $vm.buildName)
                }
                
                HStack{
                    Spacer()
                    if !vm.isLoading {
                        Button("登録",action: {
                            //住所情報登録
                            vm.setUserAdrData()
                            isActive = true
                        })
                    }
                }
            }.onAppear{
                //位置情報から住所を設定
                vm.DispInitValue(locationClient: locationClient)
                //ユーザーIDを取得
                vm.callgetUserIdAPI()
                
            }
        }
        .navigationDestination(isPresented: $isActive) {
            GarbageParentView(userAdr:vm.adrSetModel)
        }
    }
}
