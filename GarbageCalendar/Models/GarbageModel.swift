//
//  GarbageModel.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/04/06.
//

import Foundation

struct GarbageModel {
    //ゴミの種類
    let garbageTypes:[String] = ["燃えるゴミ","燃えないゴミ","プラスチック","ビン・カン","燃えないゴミ",
                                "プラスチック","ペットボトル","古紙","ダンボール","資源ゴミ","粗大ごみ"]
    let schedules:[String] = ["毎週","各週","毎月","第○曜日","各週"]
    let yobis:[String] = ["月","火","水","木","金","土","日"]
    let days:[Int] = Array(1...31)
    let months:[Int] = Array(1...12)
    let weekOfMonths = ["第一", "第二", "第三", "第四", "第五"]
    var freqWeeks = ["二週に一回", "三週に一回", "四週に一回"]
    
    var garbageType:String?
    var schedule:String?
    var yobi:String?
    var day:String?
    var month:String?
    var weekOfMonth:String?
    var freqWeek:String?
    
}
