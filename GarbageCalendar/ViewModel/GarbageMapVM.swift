//
//  MapVM.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/05/09.
//

import Foundation

//
class GarbageMapVM: BaseVM {
    
    @Published var model:GarbageAreaConvModel = GarbageAreaConvModel()
    
    func showInit(str:String){
        print(str)
    }
    
    //TODO:　地名までで情報をひきに行く
    func getgarbageAreaConv(userAdr:AdrSetModel){
        
    }
    
    //リクエストパラメタを設定
    func setRequestParam (){
        let userUnfo = loadUserAddressRegistModel()
        model.postalCode = userUnfo?.postalCode
        model.administrativeArea = userUnfo?.administrativeArea
        model.locality = userUnfo?.thoroughfare
        model.postalCode = userUnfo?.postalCode
        
    }
    
    
//    func
    
}
    
