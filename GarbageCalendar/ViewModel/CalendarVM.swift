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
    //画面のリスト用変数
    @Published var eventsList: [Date: [String]] = [:]
    @Published var today: Date = Date()
    @Published var previousDay: Date = {
        let currentDate = Date()
        return Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
    }()
    
    let calendar: Calendar = Calendar.current
    let customLightGray = Color(red: 0.9, green: 0.9, blue: 0.9)
    
    var currentMonth: String {
        getFormattedDate(date: selectedDate, format: "MM")
    }
    
    var tmpSectionDate: String = ""
    
    //初期処理
    override init() {
        //ゴミ情報のロード
        self.garbageRegistModelList = loadGarbageRegistModels()
    }
    
    //初期表示時の処理
    func onapperInit(){
        saveDestination(Const.view_CalendarView)
    }
    
    //前月に移動
    func toPreviousMonth() {
        print("戻るボタン")
        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? Date()
        

    }
    
    //次月に移動
    func toNextMonth() {
        print("次へボタン")
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
        for _ in 0..<6 {
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
    func getGarbageEventImages(date: Date) -> [Image] {
        
        print(date)
        
        var events:[Image] = []
        
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
                    events.append(garbageTypeToImage(garbageType: model.garbageType))
                    addEventToEventsList(date: date, garbageType: model.garbageType)
                }
            case "隔週":
                // 隔週の場合、指定された頻度に応じてゴミの情報を追加
                switch model.freqWeek {
                case "二週に一回":
                    let weeks = Calendar.current.dateComponents([.weekOfYear], from: model.date, to: date).weekOfYear ?? 0
                    if weeks % 2 == 0 && model.yobi == weekdaySymbol {
                        events.append(garbageTypeToImage(garbageType: model.garbageType))
                        addEventToEventsList(date: date, garbageType: model.garbageType)
                    }
                case "三週に一回":
                    let weeks = Calendar.current.dateComponents([.weekOfYear], from: model.date, to: date).weekOfYear ?? 0
                    if weeks % 3 == 0 && model.yobi == weekdaySymbol {
                        events.append(garbageTypeToImage(garbageType: model.garbageType))
                        addEventToEventsList(date: date, garbageType: model.garbageType)
                    }
                case "四週に一回":
                    let weeks = Calendar.current.dateComponents([.weekOfYear], from: model.date, to: date).weekOfYear ?? 0
                    if weeks % 4 == 0 && model.yobi == weekdaySymbol {
                        events.append(garbageTypeToImage(garbageType: model.garbageType))
                        addEventToEventsList(date: date, garbageType: model.garbageType)
                    }
                default:
                    break
                }
            case "毎月":
                // 毎月の場合、指定された日にちと一致する場合にゴミの情報を追加
                let calendar = Calendar.current
                let dayOfMonth = calendar.component(.day, from: date)
                if model.day == dayOfMonth {
                    events.append(garbageTypeToImage(garbageType: model.garbageType))
                    addEventToEventsList(date: date, garbageType: model.garbageType)
                }
            case "第○曜日":
                
                //登録されたゴミ情報の曜日
                let weekdayIndex = weekdays.firstIndex(of: model.yobi) ?? 0
                //登録されたゴミ情報の第何周か
                let weekDayOfMonth = weekdaysOrdinals[model.weekOfMonth] ?? 0
                //処理対象の日付の曜日
                let targetWeekdayIndex = weekdays.firstIndex(of:weekdaySymbol ?? "") ?? 0
                
                if isMatchingWeekday(date: date, week: weekDayOfMonth, weekday: weekdayIndex) {
                    events.append(garbageTypeToImage(garbageType: model.garbageType))
                    addEventToEventsList(date: date, garbageType: model.garbageType)
                }

            default:
                break
            }
        }
        return events
    }
    
    func addEventToEventsList(date: Date, garbageType: String) {
        if var existingGarbageTypes = eventsList[date] {
            if !existingGarbageTypes.contains(garbageType) {
                existingGarbageTypes.append(garbageType)
                eventsList[date] = existingGarbageTypes.sorted()
            }
        } else {
            eventsList[date] = [garbageType]
        }

        // eventsListを日付の昇順でソートした新しい辞書を作成
        let sortedEventsList = eventsList.sorted { $0.key < $1.key }
        eventsList = Dictionary(uniqueKeysWithValues: sortedEventsList)
    }

    
    func garbageTypeToImage(garbageType: String) -> Image {
        switch garbageType {
        case "燃えるゴミ":
            return Image("gomi_mark01_moeru")
        case "燃えないゴミ":
            return Image("gomi_mark02_moenai")
        case "プラスチック":
            return Image("gomi_mark06_plastic")
        case "ビン・カン":
            return Image("gomi_mark04_can")
        case "ペットボトル":
            return Image("gomi_mark05_petbottle")
        case "古紙":
            return Image("gomi_mark11_kami")
        case "ダンボール":
            return Image("gomi_mark07_shigen")
        case "資源ゴミ":
            return Image("gomi_mark10_kinzoku")
        case "粗大ごみ":
            return Image("gomi_mark08_sodai")
        default:
            fatalError("Invalid garbage type: \(garbageType)")
        }
    }

    func getWeekdaySymbol(for date: Date) -> String? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday], from: date)
        if let weekday = components.weekday {
            return calendar.weekdaySymbols[weekday - 1]
        }
        return nil
    }
    
    func isMatchingWeekday(date: Date, week: Int, weekday: Int) -> Bool {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let calculatedWeek: Int
        
        if day <= 7 {
            calculatedWeek = 1
        } else if day <= 14 {
            calculatedWeek = 2
        } else if day <= 21 {
            calculatedWeek = 3
        } else if day <= 28 {
            calculatedWeek = 4
        } else {
            calculatedWeek = 5
        }
        
        let calculatedWeekday = (calendar.component(.weekday, from: date) + 5) % 7 + 1
        
        return calculatedWeek == week && calculatedWeekday == weekday
    }
}

struct GarbageEvent: Hashable,Identifiable {
    let id = UUID() // ユニークなID
    let date: Date
    let garbageType: String
}


