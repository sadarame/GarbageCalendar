//
//  GarbageParentView.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/05/09.
//

import SwiftUI

struct GarbageParentView: View {
    
    @ObservedObject var vm = GarbageVM()
    @State var userAdr:AdrSetModel?
    
    var body: some View {
        VStack{
            Text(userAdr?.postalCode ?? "")
            //マップのVIEW
            GarbageMapView(vm:vm)
            //ゴミのリストのVIEW
            GarbageListView(vm:vm)
            
        }.onAppear{
            vm.showInit(str: "親")
        }
    }
}


