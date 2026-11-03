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
        SimpleEntry(date: Date(), configuration: configuration,garbageImgList: nil,garbageStrList: ["燃えるゴミ", "プラスチック"],dispCalDate: Date())
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        
        var manager = ContainerGroupManager()
        manager.setGarbageModels()
        
        var dispDate = Date()
        
        // ウィジェットの設定が明日の場合の分岐
        if configuration.isSetTomorrow {
            dispDate = ScheduleEngine.calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            manager.getGarbageEventImages(date: dispDate)
        } else {
            manager.getGarbageEventImages(date: Date())
        }

        // タイムラインの生成（1エントリだけ）
        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, configuration: configuration, garbageImgList: manager.garbageImgList, garbageStrList: manager.garbageStrList, dispCalDate: dispDate, iconTypes: manager.iconTypes)
        
        entries.append(entry)

        // タイムラインのポリシーを設定して、毎日0時に更新
        let calendar = ScheduleEngine.calendar
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
    var iconTypes: [String: String] = [:]
    
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

struct SmallWidgetView: View {
    var entry: Provider.Entry
    var body: some View { CollectionWidgetCard(entry: entry, spacious: false) }
}
struct MediumWidgetView: View {
    var entry: Provider.Entry
    var body: some View { CollectionWidgetCard(entry: entry, spacious: true) }
}
struct CollectionWidgetCard: View {
    var entry: Provider.Entry
    var spacious: Bool
    private var types: [String] { entry.garbageStrList ?? [] }
    private var date: Date { entry.dispCalDate ?? entry.date }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.configuration.isSetTomorrow ? "明日" : "今日")
                    .font(.headline.bold())
                Spacer(minLength: 4)
                Text(CollectionStyle.date(date, format: "M/d（E）"))
                    .font(.caption.weight(.semibold))
            }
            if types.isEmpty {
                Spacer(minLength: 0)
                HStack(spacing: 8) {
                    Image(systemName: "leaf.fill").font(.title2)
                    Text("収集なし").font(.headline)
                }
                Spacer(minLength: 0)
            } else if spacious {
                HStack(spacing: 8) {
                    ForEach(Array(types.prefix(3)), id: \.self) { type in
                        VStack(spacing: 6) {
                            CollectionIcon(type: type, size: 40, iconType: entry.iconTypes[type])
                            Text(type)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1).minimumScaleFactor(0.75)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 4)
                        .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                if types.count > 3 { overflow }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(types.prefix(3)), id: \.self) { type in
                        HStack(spacing: 6) {
                            CollectionIcon(type: type, size: 24, iconType: entry.iconTypes[type])
                            Text(type)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1).minimumScaleFactor(0.75)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                if types.count > 3 { overflow }
            }
        }
        .foregroundStyle(CollectionStyle.forest)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var overflow: some View {
        Text("ほか\(types.count - 3)種類")
            .font(.system(size: 10, weight: .medium))
            .lineLimit(1)
    }
}

// MARK: - 設定
struct WidgetGarbage: Widget {
    let kind: String = "ゴミカレンダー"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            WidgetGarbageEntryView(entry: entry)
.containerBackground(CollectionStyle.onboarding, for: .widget)
        }
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("ゴミカレンダー")
        .description("今日・明日のゴミ出しをホーム画面で確認できます。")
    }
}

// MARK: - ゴミ情報取得ロジック
struct ContainerGroupManager {
    var garbageList:[GarbageRegistModel] = []
    var garbageStrList:[String] = []
    var garbageImgList:[Image] = []
    var iconTypes: [String: String] = [:]
    
    mutating func setGarbageModels(){
        guard let encodedData = UserDefaults(suiteName: "group.yosuke.garbagecal.widget")?.object(forKey: "garbageRegistModels")else{
            return
        }
        
        guard let data = encodedData as? Data, let models = try? JSONDecoder().decode([GarbageRegistModel].self, from: data) else { return }
        self.garbageList = models
        
    }
    
    // MARK: - 日付と合致するゴミの画像に変更
    mutating func getGarbageEventImages(date: Date) {
        let matching = garbageList.filter { ScheduleEngine.matches($0, on: date) }
        garbageStrList = Array(Set(matching.map(\.garbageType))).sorted()
        iconTypes = [:]
        for type in garbageStrList {
            iconTypes[type] = CollectionStyle.iconType(for: type, on: date, models: matching)
        }
        garbageImgList = garbageStrList.map { Image(systemName: CollectionStyle.symbol($0)) }
    }

    func getWeekdaySymbol(for date: Date) -> String? {
        let calendar = ScheduleEngine.calendar
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
            return Image(systemName: "trash")
        }
    }
    
    func isMatchingWeekday(date: Date, week: Int, weekday: Int) -> Bool {
        let calendar = ScheduleEngine.calendar
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
}

func isWeekend(_ date: Date) -> Bool {
    let calendar = ScheduleEngine.calendar
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
    var iconType: String?
    
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
    // Optional fields preserve decoding of schedules saved by older releases.
    var validFrom: String?
    var validTo: String?
    var specificDates: [String]?
    var excludedDates: [String]?
    var additionalDates: [String]?
    
    //初期処理
    init(date: Date = Date()) {
        self.date = date
        resetTimeOfDate()
    }
    
    //日付の形式を変更する
    private mutating func resetTimeOfDate() {
        let calendar = ScheduleEngine.calendar
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

#Preview(as: .systemMedium) {
    WidgetGarbage()
} timeline: {
    SimpleEntry(date: .now, configuration: .starEyes, garbageImgList: nil,
                garbageStrList: ["燃えるゴミ", "プラスチック", "ペットボトル"], dispCalDate: .now)
    SimpleEntry(date: .now, configuration: .smiley, garbageImgList: nil,
                garbageStrList: ["燃えるゴミ", "プラスチック", "ペットボトル", "古紙"], dispCalDate: .now)
}
