import SwiftUI

struct CalendarView: View {
    @StateObject var vm = CalendarVM()
    var body: some View {
        VStack {
            //カレンダーエリア
            CalendarArea(vm:vm)
            //リストエリア
            GarbageListArea()
        }
    }
}

// MARK: - カレンダーエリア

struct CalendarArea: View {
    @StateObject var vm:CalendarVM
    // カスタムの薄い灰色を定義
    let customLightGray = Color(red: 0.9, green: 0.9, blue: 0.9)
    //薄い赤
    let customLightRed = Color(red: 1.0, green: 0.5, blue: 0.5)
    
    var body: some View {
        
        VStack(spacing: 0)  {
            
            HStack {
                Button(action: {
                    vm.selectedDate = vm.calendar.date(byAdding: .month, value: -1, to: vm.selectedDate) ?? Date()
                }) {
                    Text("＜\(getFormattedDate(date: vm.calendar.date(byAdding: .month, value: -1, to: vm.selectedDate) ?? Date(), format: "MM"))月")
                }
                Spacer()
                
                Text(getFormattedDate(date: vm.selectedDate, format: "yyyy年MM月"))
                    .font(.title)
                Spacer()
                Button(action: {
                    vm.selectedDate = vm.calendar.date(byAdding: .month, value: 1, to: vm.selectedDate) ?? Date()
                }) {
                    Text("\(getFormattedDate(date: vm.calendar.date(byAdding: .month, value: 1, to: vm.selectedDate) ?? Date(), format: "MM"))月＞")
                }
            }
//            .padding(.horizontal)
            
            HStack(spacing: 0) {
                ForEach(vm.calendar.shortWeekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .frame(width: UIScreen.main.bounds.width / 7, height: 40)
                        .foregroundColor(weekday == "土" ? Color.blue:weekday == "日" ? customLightRed : .primary)
                }
            }
            
            VStack(spacing: 0) {
                ForEach(vm.getCalendarDays(), id: \.self) { week in
                    HStack(spacing: 0) {
                        ForEach(week, id: \.self) { date in
                            VStack(spacing: 0) {
                                // MARK: - カレンダーセルの呼び出し
                                CalendarCell(vm:vm,date: date, currentMonth: getFormattedDate(date: vm.selectedDate, format: "MM")) // 追加：現在表示している月を渡す
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
        let firstDayOfMonth = vm.calendar.date(from: vm.calendar.dateComponents([.year, .month], from: vm.calendar.startOfDay(for: vm.selectedDate)))
        let startOfWeek = vm.calendar.date(from: vm.calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: firstDayOfMonth!))
        var date = startOfWeek!
        var weeks: [[Date]] = []
        
        // 5週間分の日付を取得
        for _ in 0..<5 {
            var week: [Date] = []
            for _ in 0..<7 {
                week.append(date)
                date = vm.calendar.date(byAdding: .day, value: 1, to: date)!
            }
            weeks.append(week)
        }
        
        return weeks
    }
}

// MARK: - カレンダーセル
struct CalendarCell: View {
    @StateObject var vm:CalendarVM
    // セル作成の日
    let date: Date
    // 現在表示している月
    let currentMonth: String
    
    @State var events:[String] = []
    
    let customLightGray = Color(red: 0.4, green: 0.4, blue: 0.4)
    let customLightGrayBack = Color(red: 0.8, green: 0.8, blue: 0.8)
    let customLightBlue = Color(red: 0.5, green: 0.5, blue: 1.0)
    let customLightRed = Color(red: 1.0, green: 0.5, blue: 0.5)
    let customLightBlue1 = Color(red: 0.7, green: 0.7, blue: 1.0)
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(getFormattedDate(date: date, format: "d"))
                    .font(.headline)
//                    .foregroundColor(isDateSelected() ? .white :  isDateInCurrentMonth() ? .primary : .secondary)
                                    .foregroundColor(isDateSunday() ? customLightRed :  isDateSaturday() ? customLightBlue : customLightGray)
                
//                    .background(isDateSelected() ? Color.blue : Color.clear)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            // eventsをすべて表示
            VStack(spacing: 4) {
                
                ForEach(events, id: \.self) { event in
                    Text(event)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }
        .background(isDateSelected() ? customLightBlue1: isDateInCurrentMonth() ? .clear : customLightGrayBack)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .background(Color.clear)
        .border(Color.gray, width: 0.2)
        .onAppear {
            // ViewModelのイベント情報を更新する
            events = vm.getGarbageEvents(date: date) // ここで適切な方法でイベント情報を更新する必要があります
        }
    }
    
    //引数の日付が現在表示している月のものか判定
    private func isDateInCurrentMonth() -> Bool {
        let cellMonth = Calendar.current.component(.month, from: date)
        let selectedMonth = Calendar.current.component(.month, from: vm.selectedDate)
        return selectedMonth == cellMonth
    }
    
    //選択されている日かどうか
    private func isDateSelected() -> Bool {
        return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .day)
    }

    private func getFormattedDate(date: Date, format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
    
    // 日曜日かどうかを判定
    private func isDateSunday() -> Bool {
        let weekdaySymbol = vm.getWeekdaySymbol(for: date)
        return weekdaySymbol == "日曜日"
    }
    
    // 日曜日かどうかを判定
    private func isDateSaturday() -> Bool {
        let weekdaySymbol = vm.getWeekdaySymbol(for: date)
        return weekdaySymbol == "土曜日"
    }
}

// MARK: - Lsitエリア
struct GarbageListArea: View {
    var body: some View {
        VStack {
            
        }
    }
}
