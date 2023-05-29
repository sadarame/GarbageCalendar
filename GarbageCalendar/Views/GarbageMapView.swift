//
//  MapView.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/05/09.
//

import SwiftUI

struct GarbageMapView: View {
    
    @ObservedObject var vm:GarbageVM
    
    var body: some View {
        VStack{
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        }.onAppear{
            vm.showInit(str: "Map View")
            
        }
        
    }
}


