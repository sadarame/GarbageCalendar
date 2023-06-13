//
//  Test.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/06/12.
//

import SwiftUI

struct Test: View {
    var body: some View {
        VStack(spacing: 10){
            Button(action: {
                print("おうか")
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

struct Test_Previews: PreviewProvider {
    static var previews: some View {
        Test()
    }
}
