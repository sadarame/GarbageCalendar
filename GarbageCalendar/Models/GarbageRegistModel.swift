//
//  GarbageModel.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/04/06.
//

import Foundation
import SwiftUI

struct GarbageRegistModel:Identifiable,Codable{
    
    //id
    var id = UUID()
    //ゴミの種類
    var garbageType:String = "燃えるゴミ"
    
    var garbageInfoName:String = ""
    //スケジュール
    //この項目が変更になったら他項目に初期値を設定し直す
    var schedule:String = "毎週" {didSet {setDefaultValues()}}
    //曜日
    var yobi:String = "月曜日"
    //日付(日にちだけ)
    var day:Int = 1
    //日付
    //日付の形式を変更するのと文字列用の項目に設定
    var date: Date { didSet { resetTimeOfDate() } }
    //第何周目
    var weekOfMonth:String = "第一"
    //各週の間隔
    var freqWeek:String = "二週に一回"
    //日付設定の用の文字列
    var strDate = ""
    //エラー用
    var duplicateError = false
    
    //初期処理
    init(date: Date = Date()) {
        self.date = date
        resetTimeOfDate()
    }
    
    //日付の形式を変更する
    private mutating func resetTimeOfDate() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self.date)
        
        // 時間を0時0分0秒に設定する
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        guard let resetDate = calendar.date(from: components) else {
            return
        }
        
        if resetDate != date {
            date = resetDate
            
            // 選択が変更されたときの処理
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            // Date型をString型に変換
            strDate = dateFormatter.string(from: date)
        }
    }
    
    //スケジュールが変更された場合に他の項目に初期値をセットする。
    private mutating func setDefaultValues() {
        
        switch schedule {
        case "毎週":
            // 毎週の場合の初期値の設定
            self.day = 1
            self.date = Date()
            self.weekOfMonth = "第一"
            self.freqWeek = "二週に一回"
        case "隔週":
            self.day = 1
        case "毎月":
            self.yobi = "月曜日"
            self.date = Date()
            self.weekOfMonth = "第一"
            self.freqWeek = "二週に一回"
        case "第○曜日":
            self.day = 1
            self.date = Date()
            self.freqWeek = "二週に一回"
            // 他のケースも同様に処理する
        default:
            break
        }
    }
}
