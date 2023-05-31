//
//  GarbageRegistView.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/05/30.
//

import SwiftUI

struct GarbageRegistView: View {
    
    @ObservedObject var vm:GarbageRegistVM = GarbageRegistVM()
    
    var body: some View {
        ZStack {
            ScrollView {
                ForEach(vm.garbageRegistModelList.indices, id: \.self) { index in
                    VStack {
                        Picker("選択肢", selection: $vm.garbageRegistModelList[index].garbageType) {
                            ForEach(vm.garbageRegistModelList[index].garbageTypes, id: \.self) { selection in
                                Text(selection)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
            }
            
            // 他のビュー要素
            // ...
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton {
                        // フロートボタンがタップされた時の処理
                        vm.addGarbageInfo()
                    }
                    .padding()
                }
            }
        }
    }
}

struct GarbageRegistView_Previews: PreviewProvider {
    static var previews: some View {
        GarbageRegistView()
    }
}
