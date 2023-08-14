import SwiftUI

struct CalendarView: View {
    @StateObject var vm = CalendarVM()
    @State private var isMenuOpen = false // サイドメニューの表示状態

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    // カレンダーエリア
                    CalendarArea(vm: vm)
                    // リストエリア
                    GarbageListArea(vm: vm)
                }
                // エラーメッセージ表示用モディファイア
                .modifier(CommonViewModifier(vm: vm))
                
                SideMenuView(isOpen: $isMenuOpen)
                                .edgesIgnoringSafeArea(.all)
            }
            
            .onAppear(perform: vm.onapperInit)
            
            // ヘッダー
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // メニューを表示するアクション
                       isMenuOpen.toggle()
                    }) {
                        Image(systemName: "line.horizontal.3") // メニューアイコン
                    }
                }
            }
            
            // サイドメニュー
            .navigationViewStyle(StackNavigationViewStyle()) // サイドメニューを表示するために必要なスタイル
            .listStyle(SidebarListStyle()) // サイドメニューのスタイル
            .navigationTitle("ゴミ情報カレンダー") // サイドメニューのタイトル
            .navigationBarTitleDisplayMode(.inline)
            
            // バックボタン非表示
            .navigationBarBackButtonHidden(true)
        }
    }
    
}



// MARK: - カレンダーエリア
struct CalendarArea: View {
    @StateObject var vm:CalendarVM
    
    var body: some View {
        
        VStack(spacing: 0)  {
            //ヘッダービュー
            CalendarHeaderArea(vm:vm)
            //メイン
            CalendarMainArea(vm:vm)
        }
    }
}

// MARK: - ヘッダーエリア
struct CalendarHeaderArea: View {
    @StateObject var vm:CalendarVM
    var body: some View {
        
        HStack {
            Button(action: {
                vm.toPreviousMonth()
            }) {
                Text("＜\(vm.getFormattedDate(date: vm.calendar.date(byAdding: .month, value: -1, to: vm.selectedDate) ?? Date(), format: "MM"))月")
            }
            Spacer()
            
            Text(vm.getFormattedDate(date: vm.selectedDate, format: "yyyy年MM月"))
                .font(.title)
            Spacer()
            Button(action: {
                vm.toNextMonth()
            }) {
                Text("\(vm.getFormattedDate(date: vm.calendar.date(byAdding: .month, value: 1, to: vm.selectedDate) ?? Date(), format: "MM"))月＞")
            }
        }
        .padding(.horizontal)
    }
    
}

// MARK: - メインエリア
struct CalendarMainArea: View {
    @StateObject var vm:CalendarVM
    var body: some View {
        //曜日
        HStack(spacing: 0) {
            ForEach(vm.calendar.shortWeekdaySymbols, id: \.self) { weekday in
                Text(weekday)
                    .frame(width: UIScreen.main.bounds.width / 7, height: 40)
                    .foregroundColor(weekday == "土" ? Color.blue:weekday == "日" ? Color("customLightRed") : .primary)
            }
        }
        //日付
        VStack(spacing: 0) {
            ForEach(vm.getCalendarDays(), id: \.self) { week in
                HStack(spacing: 0) {
                    ForEach(week, id: \.self) { date in
                        VStack(spacing: 0) {
                            // MARK: - カレンダーセルの呼び出し
                            CalendarCell(vm:vm,date: date, currentMonth: vm.getFormattedDate(date: vm.selectedDate, format: "MM")) // 追加：現在表示している月を渡す
                                .frame(height: 60)
                        }
                    }
                }
            }
        }
    }
    
}

// MARK: - カレンダーセル
struct CalendarCell: View {
    @StateObject var vm:CalendarVM
    // セル作成の日
    let date: Date
    // 現在表示している月
    let currentMonth: String
    
    @State var eventImages: [Image] = [] // 画像の配列
    
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
                    .foregroundColor(isDateSunday() ? customLightRed :  isDateSaturday() ? customLightBlue : customLightGray)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            // eventsをすべて表示
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    ForEach(0..<2, id: \.self) { row in
                        HStack(spacing: 4) {
                            ForEach(0..<2, id: \.self) { column in
                                let index = row * 2 + column
                                if index < eventImages.count {
                                    eventImages[index]
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                } else {
                                    Color.clear // 空のビューを挿入してスペースを確保
                                }
                            }
                        }
                    }
                }
                Spacer()
            }
        }
        .background(isDateSelected() ? customLightBlue1: isDateInCurrentMonth() ? .clear : customLightGrayBack)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .background(Color.clear)
        .border(Color.gray, width: 0.2)
        .onAppear {
            // ViewModelのイベント情報を更新する
            eventImages = vm.getGarbageEventImages(date: date) //
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
    
    // 土曜日かどうかを判定
    private func isDateSaturday() -> Bool {
        let weekdaySymbol = vm.getWeekdaySymbol(for: date)
        return weekdaySymbol == "土曜日"
    }
}

// MARK: - Lsitエリア
struct GarbageListArea: View {
    @ObservedObject var vm: CalendarVM
    @State private var scrollToTop = false

    var body: some View {
        ScrollViewReader { scrollProxy in
            List {
                ForEach(vm.eventsList.keys.sorted(), id: \.self) { date in
                    if isInSameMonth(date, as: vm.selectedDate) && date >= vm.previousDay {
                        Section(header: Text(
                            createSectionLabel(date: date))) {
                            ForEach(vm.eventsList[date] ?? [], id: \.self) { event in
                                Text(event)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .onChange(of: scrollToTop) { _ in
                scrollProxy.scrollTo(0, anchor: .top)
            }
        }
    }
    
    private func createSectionLabel(date:Date)->String{
        var labelStr = vm.getFormattedDate(date: date, format: "yyyy/MM/dd")
        labelStr = labelStr + "(" + (vm.getWeekdaySymbol(for: date) ?? "") + ")"

        return labelStr
    }
    
    
    private func isInSameMonth(_ date1: Date, as date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, equalTo: date2, toGranularity: .month)
    }
}

// MARK: - サイドバー
struct SideMenuView: View {
    @Binding var isOpen: Bool
    let width: CGFloat = 270

    var body: some View {
        ZStack {
            // リスト部分
            HStack {
                VStack() {
                    NavigationLink(destination: UserAddressRegistView(), isActive: .constant(false)) {
                        SideMenuContentView(topPadding: 100, systemName: "house", text: "住所登録")
                    }
                    NavigationLink(destination: GarbageMapView(), isActive: .constant(false)) {
                        SideMenuContentView(systemName: "mappin", text: "ゴミエリア検索")
                    }
                    NavigationLink(destination: GarbageRegistView(), isActive: .constant(false)) {
                        SideMenuContentView(systemName: "pencil.line", text: "ゴミ情報登録")
                    }
                    
                    Button(action: {
                        // ボタンがタップされたときにアクティブにする
                        
                    }) {
                        SideMenuContentView(systemName: "bell", text: "通知設定（工事中）")
                    }
                    Spacer()
                }
                .frame(width: width)
                .background(Color(UIColor.systemGray6))
                .offset(x: self.isOpen ? 0 : -self.width)
                .animation(.easeIn(duration: 0.25))
                Spacer()
            }
        }
    }
}

// MARK: - セルのビュー
struct SideMenuContentView: View {
    let topPadding: CGFloat
    let systemName: String
    let text: String

    init(topPadding: CGFloat = 30, systemName: String, text: String) {
        self.topPadding = topPadding
        self.systemName = systemName
        self.text = text
    }

    var body: some View {
        HStack {
            Image(systemName: systemName)
                .foregroundColor(.gray)
                .imageScale(.large)
                .frame(width: 32.0)
            Text(text)
                .foregroundColor(.gray)
                .font(.headline)
            Spacer()
        }
        .padding(.top, topPadding)
        .padding(.leading, 32)
    }
}




