//
//  Modifier.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/06/10.
//

import Foundation
import SwiftUI

struct CommonViewModifier: ViewModifier {
    
    @ObservedObject var vm: BaseVM
    
    func body(content: Content) -> some View {
        content
        //エラーメッセージ
            .alert(isPresented: $vm.isShowingPopup) {
                Alert(title: Text("Error"), message: Text(vm.popupMessage), dismissButton: .default(Text("OK"), action: {
                    vm.hidePopup()
                }))
            }
        // 編集不可
            .disabled(vm.isDisEditable)
            .toolbar {  // VStackに指定
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()         // 右寄せにする
                    Button("閉じる") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)  //  フォーカスを外す
                    }
                }
            }
    }
}

struct NumberPadViewModifier: ViewModifier {
    @ObservedObject var vm:UserAddressRegistVM
    let type: String?
    
    init(vm: UserAddressRegistVM? = nil, type: String? = nil) {
        self.vm = vm ?? UserAddressRegistVM()
        self.type = type
    }
    
    func body(content: Content) -> some View {
        if type == Const.type_NumberPad {
            content
                .keyboardType(.numberPad )
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        Spacer() // 右寄せスペーサー
                        Button(action: {
                            if type == Const.type_NumberPad {
                                // 郵便番号の場合の処理
                                vm.callGetAddressAPI()
                            }
                            endEditing()
                        }) {
                            Text("閉じる")
                        }
                    }
                }
        }
    }
    private func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}





