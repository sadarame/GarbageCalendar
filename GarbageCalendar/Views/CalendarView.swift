import SwiftUI

struct CalendarView: View {
    //VM
    @ObservedObject var vm:CalendarVM = CalendarVM()
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        VStack {
            //カレンダーエリア
            CalendarArea()
            //リストエリア
            GarbageListArea()
        }
    }
}

// MARK: - カレンダーエリア
struct CalendarArea: View {
    private let calendar: Calendar = Calendar.current
    @State private var selectedDate: Date = Date()
    // カスタムの薄い灰色を定義
    let customLightGray = Color(red: 0.9, green: 0.9, blue: 0.9)
    
    var body: some View {
        VStack(spacing: 0)  {
            Text("カレンダー")
                .font(.title)
                .padding()
            
            HStack {
                Button("<") {
                    self.selectedDate = self.calendar.date(byAdding: .month, value: -1, to: self.selectedDate) ?? Date()
                }
                Spacer()
                Text("\(getFormattedDate(date: selectedDate, format: "MM"))" + "月")
                Spacer()
                Button(">") {
                    self.selectedDate = self.calendar.date(byAdding: .month, value: 1, to: self.selectedDate) ?? Date()
                }
            }
            .padding(.horizontal)
            
            HStack(spacing: 0) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                    //曜日のサイズをフルにする変更
                        .frame(width: UIScreen.main.bounds.width / 7, height: 40)
                        .foregroundColor(weekday == "土" || weekday == "日" ? .white : .primary)
                        .background(weekday == "土" ? Color.blue : weekday == "日" ? Color.red : customLightGray)
                        .border(Color.gray, width: 0.5)
                }
            }
            //            .padding(.bottom, 5)
            .border(Color.gray, width: 0.5)
            
            VStack(spacing: 0) {
                ForEach(getCalendarDays(), id: \.self) { week in
                    HStack(spacing: 0) {
                        ForEach(week, id: \.self) { date in
                            VStack(spacing: 0) {
                                CalendarCell(date: date, selectedDate: $selectedDate, currentMonth: getFormattedDate(date: selectedDate, format: "MM")) // 追加：現在表示している月を渡す
                                    .frame(height: 60)
                            }
                        }
                    }
                }
            }
            
        }
    }
    
    private func getFormattedDate(date: Date, format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
    
    private func getCalendarDays() -> [[Date]] {
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: calendar.startOfDay(for: selectedDate)))
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: firstDayOfMonth!))
        var date = startOfWeek!
        var weeks: [[Date]] = []
        
        // 5週間分の日付を取得
        for _ in 0..<5 {
            var week: [Date] = []
            for day in 0..<7 {
                week.append(date)
                date = calendar.date(byAdding: .day, value: 1, to: date)!
            }
            weeks.append(week)
        }
        
        return weeks
    }
}

struct CalendarCell: View {
    let date: Date
    @Binding var selectedDate: Date
    let currentMonth: String // 追加：現在表示している月
    
    private let customLightGray = Color(red: 0.9, green: 0.9, blue: 0.9)
    private let events: [String: String] = [
        "2023-08-01": "誕生日",
        "2023-08-10": "会議",
        "2023-08-15": "祝日"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(getFormattedDate(date: date, format: "d"))
                    .font(.headline)
                    .foregroundColor(isDateSelected() ? .white : isDateOutOfRange() ? customLightGray : isDateInCurrentMonth() ? .primary : isDateInNextMonth() ? customLightGray : customLightGray)
                    .background(isDateSelected() ? Color.blue : Color.clear)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            if let event = events[getFormattedDate(date: date, format: "yyyy-MM-dd")] { // 修正：イベントがある場合のみ表示
                         Text(event)
                             .font(.caption)
                             .foregroundColor(.gray)
                     }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .background(Color.clear)
        .border(Color.gray, width: 0.5)
    }
    
    private func isDateInCurrentMonth() -> Bool {
        let cellMonth = Calendar.current.component(.month, from: date)
        return currentMonth == String(format: "%02d", cellMonth) // 修正：表示されている月と日付の月を比較
    }
    
    private func isDateInNextMonth() -> Bool {
        let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate)!
        return Calendar.current.isDate(date, equalTo: nextMonth, toGranularity: .month)
    }
    
    private func isDateSelected() -> Bool {
        return Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
    
    private func isDateOutOfRange() -> Bool {
        let currentDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        return date < currentDate
    }
    
    private func getFormattedDate(date: Date, format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
}

// MARK: - Lsitエリア
struct GarbageListArea: View {
    var body: some View {
        VStack {
      
        }
    }
}
