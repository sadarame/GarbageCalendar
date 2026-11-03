//
//  CalenderVM.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/08/04.
//

import Foundation
import SwiftUI
import MessageUI
import WidgetKit



class CalendarVM: BaseVM {
    //モデル変数のリスト
    @Published var garbageRegistModelList:[GarbageRegistModel] = []
    @Published var selectedDate: Date = Date()
    //画面のリスト用変数
    @Published var eventsList: [Date: [String]] = [:]
    @Published var today: Date = Date()
    //前日
    @Published var previousDay: Date = {
        let currentDate = Date()
        return Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
    }()
    
    //画面遷移用のフラグ
    @Published var isGarbageMapView = false
    @Published var isGarbageRegistView = false
    @Published var isUserAddresRegistView = false
    @Published var isShowingMailView:Bool = false
    @Published var isSheetPresented = false
    
    
    let calendar: Calendar = ScheduleEngine.calendar
    let customLightGray = Color(red: 0.9, green: 0.9, blue: 0.9)
    
    let dateFormatter_yyyyMMdd = DateFormatter()
    
    var currentMonth: String {
        getFormattedDate(date: selectedDate, format: "MM")
    }
    var tmpSectionDate: String = ""
    
    // MARK: 初期処理
    override init() {
        dateFormatter_yyyyMMdd.dateFormat = "yyyy-MM-dd HH:mm:ss"
        //ゴミ情報のロード
        self.garbageRegistModelList = loadGarbageRegistModels()
    }
    
    // MARK: 初期表示時の処理
    func onapperInit(){
        //画面遷移の制御
        saveDestination(Const.view_CalendarView)
        //トークン更新
        updateFcmToken()
        
        //アプリのアプデ用（Widget対策）
        saveGarbageRegistModels(loadGarbageRegistModels())
        
        //Widget更新
        WidgetCenter.shared.reloadAllTimelines()
        
        // 初回も予定を先に表示し、通知設定はホームから任意で開く。
        if !loadIsFisrstOpenCalendar(){
            saveIsFisrstOpenCalendar(true)
        }
        
    }
    
    // MARK: トークン更新
    func updateFcmToken() {
        Task { @MainActor in NotificationServerSync.shared.enqueue() }
    }

    // MARK: 前月に移動
    func toPreviousMonth() {
        print("戻るボタン")
        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? Date()
        

    }
    
    // MARK: 次月に移動
    func toNextMonth() {
        print("次へボタン")
        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? Date()
    
    }
    
    // MARK: フォーマット変換
    func getFormattedDate(date: Date, format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
    
    // MARK: ５週間分の日付の配列を作って返す
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
    // MARK: -戻り値を画像を返す
    func getGarbageEventImages(date: Date) -> [Image] {
        let matching = garbageRegistModelList.filter { ScheduleEngine.matches($0, on: date) }
        eventsList[date] = Array(Set(matching.map(\.garbageType))).sorted()
        return matching.map { garbageTypeToImage(garbageType: $0.garbageType) }
    }
    
    // MARK: Lsitエリア作成
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

    // MARK: カレンダー画像変換
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
        case "危険・有害":
            return Image("gomi_mark14")
        case "繊維":
            return Image("繊維")
        default:
            return Image(systemName: "trash")
        }
    }

    // MARK: 日付→曜日変換
    func getWeekdaySymbol(for date: Date) -> String? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday], from: date)
        if let weekday = components.weekday {
            return calendar.weekdaySymbols[weekday - 1]
        }
        return nil
    }
    
    // MARK: 月内一致
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
        
        let calculatedWeekday = calendar.component(.weekday, from: date) - 1
        
        return calculatedWeek == week && calculatedWeekday == weekday
    }
    
    func openWebsite() {
        if let url = URL(string: Const.URL_PRIVACY_POLISCY) {
            UIApplication.shared.open(url)
        }
    }
    
}

struct GarbageEvent: Hashable,Identifiable {
    let id = UUID() // ユニークなID
    let date: Date
    let garbageType: String
    
}

