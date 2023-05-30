//
//  GarbageRegistrationVM.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/05/30.
//

import Foundation

class GarbageRegistVM : BaseVM {
    //モデルを変数
    @Published var garbageRegistModel:GarbageRegistModel = GarbageRegistModel()
    //モデル変数のリスト
    @Published var garbageRegistModelList:[GarbageRegistModel]=[]
    
    //
    func onApperInit(){
        //ユーザデフォルトからモデル変数リストを取得
        
        
    }
    
    //登録
    func registData(){
        //ユーザーデフォルトに登録
        
        //登録用のAPIを叩く
    }
    
    
    
    
}
