import SwiftUI
import MessageUI

struct CalendarView: View {
    @StateObject var vm = CalendarVM()
    @State private var isMenuOpen = false // サイドメニューの表示状態
    @State private var isShowingMailView = false // サイドメニューの表示状態
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    // カレンダーエリア
                    CalendarArea(vm: vm)
                    // リストエリア
                    GarbageListArea(vm: vm)
                    //広告エリア
                    AdMobBannerView().frame(width: 320, height: 50)
                        .background(Color.clear)
                }
                //サイドバーの表示制御
                SideMenuView(vm:vm,isOpen: $isMenuOpen)
                    .edgesIgnoringSafeArea(.all)
                // エラーメッセージ表示用モディファイア
                    .modifier(CommonViewModifier(vm: vm))
                
            }
            .sheet(isPresented: $vm.isShowingMailView) {
                MailView(isShowing: $vm.isShowingMailView)
                       }
            
            .navigationDestination(isPresented: $vm.isGarbageRegistView, destination: {
                GarbageRegistView()
            })
            
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
                    .foregroundColor(getDateTextColor())
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            
            // eventsをすべて表示
            if eventImages.count == 1 {
                eventImages[0]
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            
            if eventImages.count == 2 {
                HStack(spacing: 0) {
                    eventImages[0]
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    eventImages[1]
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    
                }
            }
            if eventImages.count == 3 {
                
                HStack(spacing: 0) {
                    eventImages[0]
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    eventImages[1]
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    
                }
                HStack(spacing: 0) {
                    eventImages[2]
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    
                }
                
            }
            
            if eventImages.count > 3 {
                
                HStack(spacing: 0) {
                    eventImages[0]
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    eventImages[1]
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    
                }
                HStack(spacing: 0) {
                    eventImages[2]
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    Image("gomi_mark13_blank")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
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
    
    func getDateTextColor() -> Color {
        if isDateSunday() {
            return customLightRed
        } else if isDateSaturday() {
            return customLightBlue
        } else {
            return customLightGray
        }
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
                    //カレンダーの表示月と今月が一致していた場合
                    if isInSameMonth(vm.today, as: vm.selectedDate){
                        //Listの月と今月が一致しているかつ、Listの日付が今日の日付よりあとの場合
                        if isInSameMonth(date, as: vm.today) && date >= vm.previousDay{
                            Section(header: Text(
                                createSectionLabel(date: date))) {
                                    ForEach(vm.eventsList[date] ?? [], id: \.self) { event in
                                        Text(event)
                                    }
                                }
                        }
                        //カレンダーの表示月と今月が一致してない場合
                    } else {
                        //カレンダーの表示月とListの日付の月が一致してた場合
                        if isInSameMonth(date, as: vm.selectedDate) {
                            Section(header: Text(
                                createSectionLabel(date: date))) {
                                    ForEach(vm.eventsList[date] ?? [], id: \.self) { event in
                                        Text(event)
                                    }
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
    @StateObject var vm:CalendarVM
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
                    
                    //ゴミ情報登録
                    Button(action: {
                        // ボタンがタップされたときにアクティブにする
                        saveTriggerFlg(Const.TRG_SIDE_MENU)
                        isOpen = false
                        vm.isGarbageRegistView = true
                        
                    }) {
                        SideMenuContentView(systemName: "pencil.line", text: "ゴミ情報登録")
                    }
                    
                    //通知設定
                    Button(action: {
                        // ボタンがタップされたときにアクティブにする
                        
                    }) {
                        SideMenuContentView(systemName: "bell", text: "通知設定（工事中）")
                    }
                    
                    //問い合わせ
                    Button(action: {
                        // ボタンがタップされたときにアクティブにする
                        vm.isShowingMailView = true
                        
                    }) {
                        SideMenuContentView(systemName: "mail.fill", text: "問い合わせ")
                    }
                    
                    //プラポリ
                    Button(action: {
                        // ボタンがタップされたときにアクティブにする
                        vm.openWebsite()
                        
                    }) {
                        SideMenuContentView(systemName: "network", text: "プライバシーポリシー")
                    }
                    Spacer()
                }
                .frame(width: width)
                .background(Color(UIColor.systemGray6))
                .offset(x: self.isOpen ? 0 : -self.width)
                .animation(.easeIn(duration: 0.25))
                .gesture(
                                DragGesture()
                                    .onEnded { gesture in
                                        // 左スワイプした場合にメニューバーを非表示にする
                                        if gesture.translation.width < -50 {
                                            isOpen = false
                                        }
                                    }
                            )
                Spacer()
            }
        }
    }
}

// MARK: - サイドバーのビュー
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

// MARK: - メールバーのビュー

struct MailView: UIViewControllerRepresentable {
    @Binding var isShowing: Bool

    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> UIViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setSubject("【問い合わせ】ゴミ出しカレンダー")
        controller.setToRecipients(["sadarame@gmail.com"])
        controller.setMessageBody("", isHTML: false)
        return controller
    }

    func makeCoordinator() -> MailView.Coordinator {
        return Coordinator(parent: self)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate {
        let parent: MailView
        init(parent: MailView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            // 終了時の処理あれこれ

            self.parent.isShowing = false
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<MailView>) {
    }
}



