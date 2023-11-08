//
//  WidgetGarbage.swift
//  WidgetGarbage
//
//  Created by Yosuke Yoshida on 2023/11/06.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(),garbageImgList: nil,garbageStrList: nil, dispCalDate: nil)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration,garbageImgList: nil,garbageStrList: nil,dispCalDate: nil)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        
        var manager = ContainerGroupManager()
        manager.setGarbageModels()
        
        var dispDate = Date()
        
        // ウィジェットの設定が明日の場合の分岐
        if configuration.isSetTomorrow {
            dispDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            manager.getGarbageEventImages(date: dispDate)
        } else {
            manager.getGarbageEventImages(date: Date())
        }

        // タイムラインの生成（1エントリだけ）
        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, configuration: configuration, garbageImgList: manager.garbageImgList, garbageStrList: manager.garbageStrList, dispCalDate: dispDate)
        
        entries.append(entry)

        // タイムラインのポリシーを設定して、毎日0時に更新
        let calendar = Calendar.current
        let nextMidnight = calendar.startOfDay(for: currentDate).addingTimeInterval(24 * 60 * 60)
        let refreshDate = calendar.dateComponents([.year, .month, .day], from: nextMidnight)
        let nextUpdate = calendar.date(from: refreshDate)!
        
        return Timeline(entries: entries, policy: .after(nextUpdate))
    }

}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let garbageImgList:[Image]?
    let garbageStrList:[String]?
    let dispCalDate:Date?
    
}

// MARK: - メインビュー
struct WidgetGarbageEntryView : View {
    @Environment(\.widgetFamily) var family: WidgetFamily
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
            
        case .systemMedium:
            MediumWidgetView(entry: entry)
            
        default:
            Text("Default")
        }
    }
}

// MARK: - スモールビュー
struct SmallWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            VStack(alignment: .leading,spacing: 0){
                if entry.configuration.isSetTomorrow {
                    Text("明日")
                        .fontWeight(.bold)  // 太字
                        .font(.system(size: 10))
                        .foregroundColor(.black)
                }
                HStack{
                    
                    
                    //日付：dd
                    Text(formatDate(entry.dispCalDate ?? Date()))
                        .fontWeight(.bold)  // 太字
                        .font(.system(size: 30))
                        .foregroundColor(.black)
                    
                    // 縦線を挿入
                    Divider()
                        .frame(width: 2, height: 30)
                    
                    //日付：曜日
                    Text(formatDateDay(entry.dispCalDate ?? Date()))
                        .fontWeight(.bold)
                        .foregroundColor(isWeekend(entry.date) ? .red : .black)
                    
                    
                    
                    Spacer()
                    
                    //ロゴ
                    Image("splash")
                        .resizable()
                        .frame(width: 35, height: 35)
                        .clipShape(Circle()) // 画像を丸くクリップ
                        .overlay(
                            Circle() // 白い線の円をオーバーレイ
                                .stroke(Color.white, lineWidth: 3) // 白い線の設定
                        )
                        .padding(.bottom, 4)
  
                }
                //ライン
                LineView().padding(.bottom)
                    .foregroundColor(.black)
                //ゴミの文字列リストエリア
                Group {
                    //アンラップ
                    
                    if let garbageStrList = entry.garbageStrList, !garbageStrList.isEmpty {
                        //ゴミ情報の登録件数分繰り返し
                        ForEach(garbageStrList.indices, id: \.self) { index in
                            
                            if index > 2 {
                                //３つ以上は表示しない
                            }
                            
                            else if index == 2 && garbageStrList.count > 2{
                                // 3回目のループかつ、３つ以上ゴミの登録がある場合
                                // 「・・・」を追加する
                                HStack {
                                    Text(garbageStrList[index])
                                        .font(.system(size: 15))
                                        .foregroundColor(.black)
                                    Text("他")
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                }
                            } else {
                                Text(garbageStrList[index])
                                    .font(.system(size: 15))
                                    .foregroundColor(.black)
                                
                            }
                        }
                    } else {
                        Text("ゴミの日はありません")
                            .font(.system(size: 15))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                }
            }
            
        }
            
    }
}

// MARK: - ミドルビュー
struct MediumWidgetView: View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            HStack {
                VStack(alignment: .leading,spacing: 0) {
                    if entry.configuration.isSetTomorrow {
                        Text("明日")
                            .fontWeight(.bold)  // 太字
                            .font(.system(size: 10))
                            .foregroundColor(.black)
                    }
                    //日付のエリア
                    HStack{
                        //日付：dd
                        Text(formatDate(entry.dispCalDate ?? Date()))
                            .fontWeight(.bold)  // 太字
                            .font(.system(size: 40))
                            .foregroundColor(.black)
                        
                        // 縦線を挿入
                        Divider()
                            .frame(width: 2, height: 30)
                            .foregroundColor(.black)
                        
                        //日付：曜日
                        Text(formatDateDay(entry.dispCalDate ?? Date()))
                            .fontWeight(.bold)
                            .foregroundColor(isWeekend(entry.date) ? .red : .black)
                        
                        
                        Spacer()
                        
                        Image("splash")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle()) // 画像を丸くクリップ
                            .overlay(
                                Circle() // 白い線の円をオーバーレイ
                                    .stroke(Color.white, lineWidth: 3) // 白い線の設定
                            )
                        
                    }
                    //ライン
                    LineView().padding(.bottom)
                    //ゴミの文字列リストエリア
                    Group {
                        //アンラップ
                        
                        if let garbageStrList = entry.garbageStrList, !garbageStrList.isEmpty {
                            //ゴミ情報の登録件数分繰り返し
                            ForEach(garbageStrList.indices, id: \.self) { index in
                                
                                if index > 2 {
                                    //３つ以上は表示しない
                                }
                                
                                else if index == 2 && garbageStrList.count > 2{
                                    // 3回目のループかつ、３つ以上ゴミの登録がある場合
                                    // 「・・・」を追加する
                                    HStack {
                                        Text(garbageStrList[index])
                                            .font(.system(size: 20))
                                            .foregroundColor(.black)
                                        Text("他")
                                            .fontWeight(.bold)
                                            .foregroundColor(.black)
                                    }
                                } else {
                                    Text(garbageStrList[index])
                                        .font(.system(size: 20))
                                        .foregroundColor(.black)
                                    
                                }
                            }
                        } else {
                            Text("ゴミの日はありません")
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                    }
                }
                //イメージ画像のエリア
                Group{
                    if let firstImage = entry.garbageImgList?.first {
                        firstImage
                            .resizable()
                            .frame(width: 100, height: 100)
                    } else {
                        Image("gomi_mark13_Nodata")
                            .resizable()
                            .frame(width: 100, height: 100)
                    }
                    
                }
            }
        }
    }
}

// MARK: - 設定
struct WidgetGarbage: Widget {
    let kind: String = "ゴミカレンダー"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            WidgetGarbageEntryView(entry: entry)
//                .containerBackground(.fill.tertiary, for: .widget)
                .containerBackground(Color("WidgetBackground"), for: .widget)
        }
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("ゴミカレンダー")
        .description("ゴミ情報を表示します。")
    }
}

// MARK: - ゴミ情報取得ロジック
struct ContainerGroupManager {
    var garbageList:[GarbageRegistModel] = []
    var garbageStrList:[String] = []
    var garbageImgList:[Image] = []
    
    mutating func setGarbageModels(){
        guard let encodedData = UserDefaults(suiteName: "group.yosuke.garbagecal.widget")?.object(forKey: "garbageRegistModels")else{
            return
        }
        
        self.garbageList = try! JSONDecoder().decode([GarbageRegistModel].self, from: encodedData as! Data)
        
    }
    
    // MARK: - 日付と合致するゴミの画像に変更
    mutating func getGarbageEventImages(date: Date) {
        
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
        
        for model in self.garbageList {
            switch model.schedule {
            case "毎週":
                // 毎週の場合、指定された曜日と一致する場合にゴミの情報を追加
                if model.yobi == weekdaySymbol {
                    self.garbageImgList.append(garbageTypeToImage(garbageType: model.garbageType))
                    self.garbageStrList.append(model.garbageType)
                }
            case "隔週":
                // 隔週の場合、指定された頻度に応じてゴミの情報を追加
                switch model.freqWeek {
                case "二週に一回":
                    let weeks = Calendar.current.dateComponents([.weekOfYear], from: model.date, to: date).weekOfYear ?? 0
                    if weeks % 2 == 0 && model.yobi == weekdaySymbol {
                        self.garbageImgList.append(garbageTypeToImage(garbageType: model.garbageType))
                        self.garbageStrList.append(model.garbageType)
                       
                    }
                case "三週に一回":
                    let weeks = Calendar.current.dateComponents([.weekOfYear], from: model.date, to: date).weekOfYear ?? 0
                    if weeks % 3 == 0 && model.yobi == weekdaySymbol {
                        self.garbageImgList.append(garbageTypeToImage(garbageType: model.garbageType))
                        self.garbageStrList.append(model.garbageType)
                    }
                case "四週に一回":
                    let weeks = Calendar.current.dateComponents([.weekOfYear], from: model.date, to: date).weekOfYear ?? 0
                    if weeks % 4 == 0 && model.yobi == weekdaySymbol {
                        self.garbageImgList.append(garbageTypeToImage(garbageType: model.garbageType))
                        self.garbageStrList.append(model.garbageType)
                        
                    }
                default:
                    break
                }
            case "毎月":
                // 毎月の場合、指定された日にちと一致する場合にゴミの情報を追加
                let calendar = Calendar.current
                let dayOfMonth = calendar.component(.day, from: date)
                if model.day == dayOfMonth {
                    self.garbageImgList.append(garbageTypeToImage(garbageType: model.garbageType))
                    self.garbageStrList.append(model.garbageType)
                   
                }
            case "第○曜日":
                
                //登録されたゴミ情報の曜日
                let weekdayIndex = weekdays.firstIndex(of: model.yobi) ?? 0
                //登録されたゴミ情報の第何周か
                let weekDayOfMonth = weekdaysOrdinals[model.weekOfMonth] ?? 0
                //処理対象の日付の曜日
                let targetWeekdayIndex = weekdays.firstIndex(of:weekdaySymbol ?? "") ?? 0
                
                if isMatchingWeekday(date: date, week: weekDayOfMonth, weekday: weekdayIndex) {
                    self.garbageImgList.append(garbageTypeToImage(garbageType: model.garbageType))
                    self.garbageStrList.append(model.garbageType)
                   
                }

            default:
                break
            }
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
            fatalError("Invalid garbage type: \(garbageType)")
        }
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

func isWeekend(_ date: Date) -> Bool {
    let calendar = Calendar.current
    let dayOfWeek = calendar.component(.weekday, from: date)
    return dayOfWeek == 1 || dayOfWeek == 7 // 1は日曜日、7は土曜日
}

func formatDate(_ date: Date) -> String {
    // 日付をフォーマットするロジックを実装
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "d"
    return dateFormatter.string(from: date)
}

func formatDateDay(_ date: Date) -> String {
    // 日付をフォーマットするロジックを実装
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEE"
    return dateFormatter.string(from: date)
}

func formatDateWithDayOfWeek(_ date: Date) -> String {
    // 年月と曜日をフォーマットするロジックを実装
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEEE"
    return dateFormatter.string(from: date)
}

// MARK: - ライン
struct LineView: View {
    var body: some View {
        Rectangle()
            .frame(height: 1) // 線の高さを調整
            .background(Color.gray.opacity(0.8))// 線の色を指定
    }
}

// MARK: - データモデル
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


extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.isSetTomorrow = true
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.isSetTomorrow = false
        return intent
    }
}

#Preview(as: .systemSmall) {
    WidgetGarbage()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley,garbageImgList: nil,garbageStrList: nil, dispCalDate: nil)
    SimpleEntry(date: .now, configuration: .starEyes,garbageImgList: nil,garbageStrList: nil, dispCalDate: nil)
}
