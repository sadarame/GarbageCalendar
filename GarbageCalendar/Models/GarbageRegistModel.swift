//
//  GarbageModel.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/04/06.
//

import Foundation
import SwiftUI

struct GarbageRegistModel:Identifiable,Codable{
    
    var id = UUID()
    //ゴミの種類
    var garbageType:String = "燃えるゴミ"
    var schedule:String = "毎週"
    var yobi:String = "月曜日"
    var day:Int = 1
    var month:Int = 1
    var date = Date()
    var weekOfMonth:String = "第一"
    var freqWeek:String = "二週に一回"
    
}
