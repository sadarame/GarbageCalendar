//
//  CalenderVM.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/08/04.
//

import Foundation

class CalendarVM: BaseVM {
    //モデル変数のリスト
    @Published var garbageRegistModelList:[GarbageRegistModel] = []
    //カレンダー日付
    @Published var selectedDate:Date = Date()
    
    //初期処理
    override init() {
        //ゴミ情報のロード
        garbageRegistModelList = loadGarbageRegistModels()
    }
    
    //初期表示時の処理
    func onapperInit(){

    }
}
   
