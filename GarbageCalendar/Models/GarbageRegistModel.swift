//
//  GarbageModel.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/04/06.
//

import Foundation
import SwiftUI

struct GarbageRegistModel:Identifiable{
    
    let id = UUID()
    
    //ゴミの種類
    let garbageTypes:[String] = ["燃えるゴミ","燃えないゴミ","プラスチック","ビン・カン",
                                "ペットボトル","古紙","ダンボール","資源ゴミ","粗大ごみ"]
    let schedules:[String] = ["毎週","各週","毎月","第○曜日"]
    let yobis:[String] = ["月曜日","火曜日","水曜日","木曜日","金曜日","土曜日","日曜日"]
    let days:[Int] = Array(1...31)
    let months:[Int] = Array(1...12)
    let weekOfMonths = ["第一", "第二", "第三", "第四", "第五"]
    var freqWeeks = ["二週に一回", "三週に一回", "四週に一回"]
    
    
    var garbageType:String = "燃えるゴミ"
    var schedule:String = "毎週"
    var yobi:String = "月曜日"
    var day:Int = 1
    var month:Int = 1
    var date = Date()
    var weekOfMonth:String = "第一"
    var freqWeek:String = "二週に一回"
    
}
