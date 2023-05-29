//
//  GarbageListView.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/04/06.
//

import SwiftUI

struct GarbageListView: View {
    
    @ObservedObject var vm:GarbageVM
    
    var body: some View {
        VStack{
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        }.onAppear{
            vm.showInit(str: "ListView")
        }
    }
}

