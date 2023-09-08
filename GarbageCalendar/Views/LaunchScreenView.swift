//
//  LaunchScreenView.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/09/04.
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var isLoading = true

    var body: some View {
        if isLoading {
            ZStack {
                Color(UIColor(red: 210/255.0, green: 230/255.0, blue: 151/255.0, alpha: 1.0))
                    .ignoresSafeArea()
                Image("splash")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        isLoading = false
                    }
                }
            }
        } else {
            if loadDestination() == Const.view_CalendarView {
                CalendarView()
            } else {
                UserAddressRegistView()
            }
        }
    }
}



