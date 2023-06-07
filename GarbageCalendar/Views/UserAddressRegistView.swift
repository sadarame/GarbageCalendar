//
//  UserAddressRegistView.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/06/06.
//

import SwiftUI
import _CoreLocationUI_SwiftUI

struct UserAddressRegistView: View {
    //VM
    @ObservedObject var vm: UserAddressRegistVM = UserAddressRegistVM()
    
    var body: some View {
        //ナビゲーション
        NavigationStack {
            ZStack{
                VStack{
                    //現在地情報取得ボタンのエリア
                    LocationButtonArea(vm: vm)
                    //ユーザからの入力を受け付けるエリア
                    UserInputArea(vm: vm)
                }
                //位置情報取得中にプログレスを全面表示する
                if vm.isShowProgres {EffectProgressView(10)}
            }
        }
    }
}

//入力フィールドのラベル
struct InputLabelView : View {
    let labelName:String
    
    var body: some View {
        Text(labelName).font(.headline)
    }
}
//入力フィールド
struct InputFieldView : View {
    
    @Binding var text: String
    let placeHolder: String?
    
    init(text: Binding<String>, placeHolder: String? = nil) {
        self._text = text
        self.placeHolder = placeHolder
    }
    
    var body: some View {
        TextField(placeHolder ?? "", text: $text)
        .padding(.all)
        .clipShape(RoundedRectangle(cornerRadius: 10.0))
        .background(Color(red: 239.0/255.0, green: 243.0/255, blue: 244.0/255.0, opacity:1.0))
        .textFieldStyle(.plain)
        .foregroundColor(placeHolder == "任意" ? .gray : .black)
            // その他の修飾やスタイリング
    }
}

struct LocationButtonArea : View {
    
    @ObservedObject var vm: UserAddressRegistVM
    
    var body: some View {
        VStack{
            Text("位置情報から住所情報を入力")
            LocationButton(.currentLocation) {
                //位置情報取得
                vm.requestLocation()
            }
        }
    }
}

struct UserInputArea : View {
    
    @ObservedObject var vm: UserAddressRegistVM
    
    var body: some View {
        ScrollView{
            //入力フィールドの作成
            VStack(alignment: .leading, spacing: 10.0) {
                InputLabelView(labelName: "郵便番号")
                InputFieldView(text: $vm.model.postalCode)
                    .onSubmit(vm.callGetAddressAPI)
                
                HStack{
                    VStack(alignment: .leading){
                        InputLabelView(labelName: "都道府県")
                        InputFieldView(text: $vm.model.administrativeArea)
                    }
                    VStack(alignment: .leading) {
                        InputLabelView(labelName: "市区町村")
                        InputFieldView(text: $vm.model.locality)
                    }
                }
                
                InputLabelView(labelName: "丁目")
                InputFieldView(text: $vm.model.thoroughfare)
                
                InputLabelView(labelName: "番地")
                InputFieldView(text: $vm.model.subThoroughfare,placeHolder:"任意")
                
                
                //名前
                Group{
                    HStack{
                        InputLabelView(labelName: "名前")
                        VStack(alignment: .leading){
                            Text("※他の方も利用できるように命名してくれると嬉しいです。").font(.system(size: 12))
                            Text("例：ビル名など").font(.system(size: 12))
                        }
                    }
                    InputFieldView(text: $vm.model.UserAddressName)
                    
                }
                
            }
        }
        .padding(.horizontal,15)
        //ナビゲーション処理
        .navigationBarTitle(Text("住所情報入力"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    //vm.registData()
                }) { Text("登録") }
            }
        }
    }
}


struct UserAddressRegistView_Previews: PreviewProvider {
    static var previews: some View {
        UserAddressRegistView()
    }
}
