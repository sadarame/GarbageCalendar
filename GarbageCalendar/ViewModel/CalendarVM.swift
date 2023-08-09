//
//  CalenderVM.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/08/04.
//

import Foundation
import SwiftUI

class CalendarVM: BaseVM {
    //モデル変数のリスト
    @Published var garbageRegistModelList:[GarbageRegistModel] = []
    @Published var selectedDate: Date = Date()
    
    let calendar: Calendar = Calendar.current
    let customLightGray = Color(red: 0.9, green: 0.9, blue: 0.9)
    
    var currentMonth: String {
        getFormattedDate(date: selectedDate, format: "MM")
    }
    
    //初期処理
    override init() {
        //ゴミ情報のロード
        self.garbageRegistModelList = loadGarbageRegistModels()
    }
    
    //初期表示時の処理
    func onapperInit(){
        
    }
    
    //前月に移動
    func previousMonth() {
        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? Date()
    }
    
    //次月に移動
    func nextMonth() {
        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? Date()
    }
    
    //フォーマット変換
    func getFormattedDate(date: Date, format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
    
    //５週間分の日付の配列を作って返す
    func getCalendarDays() -> [[Date]] {
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: calendar.startOfDay(for: selectedDate)))
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: firstDayOfMonth!))
        var date = startOfWeek!
        var weeks: [[Date]] = []
        
        // 5週間分の日付を取得
        for _ in 0..<5 {
            var week: [Date] = []
            for _ in 0..<7 {
                week.append(date)
                date = calendar.date(byAdding: .day, value: 1, to: date)!
            }
            weeks.append(week)
        }
        
        return weeks
    }
    
    // MARK: - 日付を引数で受け取って、ゴミの情報を返す
    // Todo:-戻り値を画像を返す
    func getGarbageEvents(date: Date) -> [String] {
        
        var events:[String] = []
        
        // 引数の日付に対応する曜日を取得
        let weekdaySymbol = getWeekdaySymbol(for: date)
        
        // 曜日の定義（日曜日から土曜日）
        let weekdays: [String] = ["日曜日", "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日"]
        
        // "第○曜日"の順序に対応する数値（第一: 1, 第二: 2, 第三: 3, 第四: 4, 第五: 5）
        let weekdaysOrdinals: [String: Int] = [
            "第一": 1,
            "第二": 2,
            "第三": 3,
            "第四": 4,
            "第五": 5
        ]
        
        for model in garbageRegistModelList {
            switch model.schedule {
            case "毎週":
                // 毎週の場合、指定された曜日と一致する場合にゴミの情報を追加
                if model.yobi == weekdaySymbol {
                    events.append(model.garbageType)
                }
            case "隔週":
                // 隔週の場合、指定された頻度に応じてゴミの情報を追加
                switch model.freqWeek {
                case "二週に一回":
                    let weeks = Calendar.current.dateComponents([.weekOfYear], from: model.date, to: date).weekOfYear ?? 0
                    if weeks % 2 == 0 && model.yobi == weekdaySymbol {
                        events.append(model.garbageType)
                    }
                case "三週に一回":
                    let weeks = Calendar.current.dateComponents([.weekOfYear], from: model.date, to: date).weekOfYear ?? 0
                    if weeks % 3 == 0 && model.yobi == weekdaySymbol {
                        events.append(model.garbageType)
                    }
                case "四週に一回":
                    let weeks = Calendar.current.dateComponents([.weekOfYear], from: model.date, to: date).weekOfYear ?? 0
                    if weeks % 4 == 0 && model.yobi == weekdaySymbol {
                        events.append(model.garbageType)
                    }
                default:
                    break
                }
            case "毎月":
                // 毎月の場合、指定された日にちと一致する場合にゴミの情報を追加
                let calendar = Calendar.current
                let dayOfMonth = calendar.component(.day, from: date)
                if model.day == dayOfMonth {
                    events.append(model.garbageType)
                }
            case "第○曜日":
                // 第○曜日の場合、指定された週と曜日に応じてゴミの情報を追加
                let weekdayIndex = weekdays.firstIndex(of: model.yobi) ?? 0
                let targetWeekday = (weekdayIndex + 1) % 7
                let firstWeekdayOfMonth = calendar.component(.weekday, from: calendar.date(from: calendar.dateComponents([.year, .month], from: date))!)
                
                // 第一週の場合
                if firstWeekdayOfMonth == targetWeekday && model.weekOfMonth == "第一" {
                    events.append(model.garbageType)
                }
                
                // 第○週目の場合
                let ordinalWeekdayOfMonth = (firstWeekdayOfMonth - 1) / 7 + 1
                if ordinalWeekdayOfMonth > 1 && ordinalWeekdayOfMonth <= 5 && ordinalWeekdayOfMonth == weekdaysOrdinals[model.weekOfMonth] {
                    events.append(model.garbageType)
                }
            default:
                break
            }
        }
        
        return events
    }

    func getWeekdaySymbol(for date: Date) -> String? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday], from: date)
        if let weekday = components.weekday {
            return calendar.weekdaySymbols[weekday - 1]
        }
        return nil
    }
}

