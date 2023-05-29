//
//  ParentView.swift
//  dustCalrendar
//
//  Created by Yosuke Yoshida on 2023/03/20.
//

import SwiftUI

struct ParentView: View {
    
    init() {
        //UserDefaultから値を取得して遷移先を決める
    }
    
    var body: some View {
        NavigationStack{
            //初起動時
            PermitPositionView()
            //        AdrSetView()
        }
        
    }
}

struct ｂんｈｊ: PreviewProvider {
    static var previews: some View {
        ParentView()
    }
}
