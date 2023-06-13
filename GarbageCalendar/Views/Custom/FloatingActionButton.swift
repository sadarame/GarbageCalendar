//
//  SwiftUIView.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/05/30.
//

import SwiftUI

struct FloatingAddButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(radius: 5)
        }
        .frame(width: 60, height: 60)
    }
}

struct FloatingRegistButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("次へ")
                .font(.title)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
//                .clipShape(Circle())
                .shadow(radius: 5)
        }
        .frame(width: 100, height: 60)
    }
}
