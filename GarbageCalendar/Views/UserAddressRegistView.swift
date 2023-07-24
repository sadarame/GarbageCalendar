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
                    //メインエリア
                    ScrollView{
                        //ユーザからの入力を受け付けるエリア
                        UserInputArea(vm: vm)
                    }
                    //次へボタン
                    ButtonToNext(vm: vm)
                        //入力チェッククリアしないと非活性
                        .disabled(!vm.validateInputFields())
                        .frame(width: UIScreen.main.bounds.width * 0.9)
                }
                //位置情報取得中にプログレスを全面表示する
                if vm.isShowProgres {EffectProgressView(10)}
            }
            //画面遷移処理
            .navigationDestination(isPresented: $vm.activie, destination: {
                GarbageMapView()
            })
            //エラーメッセージ表示用モディファイア
            .modifier(CommonViewModifier(vm: vm))
        }
        //初期表示時の初期処理
        .onAppear(perform: vm.onapperInit)
    }
    
}

//ユーザ入力エリア
struct UserInputArea : View {
    
    @ObservedObject var vm: UserAddressRegistVM
    
    var body: some View {
        //入力フィールドの作成
        VStack(alignment: .leading, spacing: 10.0) {
            InputLabelView(labelName: "郵便番号")
            InputFieldView(text: $vm.model.postalCode,type: Const.type_NumberPad,vm:vm)
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
            
            InputLabelView(labelName: "建物名")
            InputFieldView(text: $vm.model.buildName,placeHolder:"任意")
        }
        .padding(.horizontal,15)
        //ナビゲーション処理
        .navigationBarTitle(Text("住所情報入力"))
        .navigationBarTitleDisplayMode(.inline)
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
struct InputFieldView: View {
    @Binding var text: String
    let placeHolder: String?
    let type: String?
    let vm: UserAddressRegistVM?
    
    init(text: Binding<String>, placeHolder: String? = nil, type: String? = nil, vm: UserAddressRegistVM? = nil) {
        self._text = text
        self.placeHolder = placeHolder
        self.type = type
        self.vm = vm
    }
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack{
            let textField = TextField(placeHolder ?? "", text: $text)
                .padding(.all)
                .clipShape(RoundedRectangle(cornerRadius: 10.0))
                .background(Color(red: 239.0/255.0, green: 243.0/255, blue: 244.0/255.0, opacity:1.0))
                .textFieldStyle(.plain)
            
            if type == Const.type_NumberPad {
                textField
                    .keyboardType(.numberPad)
                    .focused($isTextFieldFocused)
            } else {
                textField
                    .keyboardType(.default)
            }
        }
        .onChange(of: isTextFieldFocused) { isFocused in
             if !isFocused {
                 // フォーカスが外れたときの処理
                 vm?.callGetAddressAPI()
             }
         }
    }
}

struct LocationButtonArea : View {
    
    @ObservedObject var vm: UserAddressRegistVM
    
    var body: some View {
        HStack{
            Text("位置情報から住所情報を入力")
            LocationButton{
                //位置情報取得
                vm.requestLocation()
            }
            .labelStyle(.iconOnly)
            .foregroundColor(.white)
            .cornerRadius(30)
            .symbolVariant(.fill)
            .tint(.blue)
        }
    }
}

struct ButtonToNext : View {
    
    @ObservedObject var vm: UserAddressRegistVM
    
    var body: some View {
        VStack{
            Button(action: {
                //ボタン押下のイベント
                vm.onNextButtonTapped()
                
                if vm.model.buildName != "" {
                    vm.garbageInfoName = vm.model.buildName
                } else {
                    vm.garbageInfoName = vm.model.thoroughfare
                }
            
            }) {
                Text("次へ")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .accentColor(Color.white)
                    .background(Color.blue)
                    .cornerRadius(.infinity)
            }
        }
    }
}

struct UserAddressRegistView_Previews: PreviewProvider {
    static var previews: some View {
        UserAddressRegistView()
    }
}
