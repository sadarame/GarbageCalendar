//
//  GarbageRegistView.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/05/30.
//

import SwiftUI

struct GarbageRegistView: View {
    var body: some View {
        ZStack {
            ScrollView {
                
            }
            
            
            // 他のビュー要素
            // ...
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton {
                        // フロートボタンがタップされた時の処理
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
