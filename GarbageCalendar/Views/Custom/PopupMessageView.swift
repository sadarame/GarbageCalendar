//
//  PopUpView2.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/08/23.
//

import SwiftUI

struct PopupMessageView: View {
    @ObservedObject var vm: BaseVM
    
    var body: some View {
        GeometryReader { geometry in

            ZStack {
                PopupBackgroundView(isPresented: vm.isShowNavigate)
                    .transition(.opacity)
                
                PopupContentsView(vm:vm)
                    .frame(width: geometry.size.width * 0.8, height: geometry.size.height * 0.5)
                    .background(Color.white)
                    .cornerRadius(20)
            }

        }
    }
}

struct PopupBackgroundView: View {
    @State var isPresented: Bool
    
    var body: some View {
        Color.black.opacity(0.3)
            .onTapGesture {
                self.isPresented = false
            }
            .edgesIgnoringSafeArea(.all)
    }
}

struct PopupContentsView: View {
    @ObservedObject var vm: BaseVM
    @State var isChecked : Bool = false
    
    var body: some View {
        VStack {
            //タイトルエリア
            HStack{
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title)
                
                Text("アプリについて")
                    .font(.title)
            }
            
            //メッセージ
            Text(vm.navigateText)
                .padding()
            Spacer()
            

            
            if vm.navigateKey == Const.KEY_NOTIFICATE {
                //閉じるボタン
                Button(action: {
                    vm.isShowNavigate = false
                    vm.openAppSettings()
                    
                }, label: {
                    Text("設定画面へ")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                })
                
                
            } else {
                //チェックエリア
                Toggle(isOn: $isChecked) {
                    Text("次回以降表示しない")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                //閉じるボタン
                Button(action: {
                    vm.isShowNavigate = false
                    
                }, label: {
                    Text("Close")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                })
            }
            
        }
        //VStackのモディファイア
        .padding()
        .onChange(of: isChecked) { newValue in
            if newValue {
                UserDefaults.standard.set(Const.hide_NavigationView, forKey: vm.navigateKey)
            } else {
                UserDefaults.standard.set(Const.show_NavigationView, forKey: vm.navigateKey)
            }
            
        }
    }
}

struct PopupImageContentsView: View {
    @Binding var isPresented: Bool
    var body: some View {
        VStack {
            Image(systemName: "star.fill")
                .font(.system(size: 50))
            Button(action: {
                isPresented = false
            }, label: {
                Text("Close")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
            })
        }
    
    }
}
