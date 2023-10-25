import SwiftUI

struct NotificationSetView: View {
    
    @ObservedObject var vm = NotificationSetVM()
    @Binding var isPresented: Bool
    
    
    init(isPresented: Binding<Bool>) {
        _isPresented = isPresented //
        // UIKitのUINavigationBarの外観を設定
        UINavigationBar.appearance().barTintColor = UIColor.white // 背景色
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.black] // タイトル色
        UINavigationBar.appearance().tintColor = .white // backボタン色
    }
    
    var body: some View {
        NavigationStack {
            ZStack{
                Form {
                    Toggle("通知を有効にする", isOn: $vm.model.isNotificationEnabled)
                        .onChange(of: vm.model.isNotificationEnabled) { newValue in
                            // 通知の有効状態が変更されたら許可ステータスを確認
                            vm.checkNotificationPermission()
                        }
                    
                    RadioArea(vm:vm)
                    
                    DatePicker("日時を選択", selection: $vm.model.notificateTime, displayedComponents: .hourAndMinute)
                        .onChange(of: vm.model.notificateTime) { newDate in
                            // 変更内容を保存する
                            vm.changeNotificateSetting()
                        }
                }
                //ナビゲーション
                if vm.isShowNavigate {
                    PopupMessageView(vm: vm)
                }
            }
            .onAppear(perform: vm.onApperInit)
            .navigationTitle("通知設定") // サイドメニューのタイトル
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

//struct RadioArea: View {
//
//    @ObservedObject var vm: NotificationSetVM
//
//    private let selectNames = ["当日", "前日"]
//    @State private var selectedIndex = 0
//
//    var body: some View {
//        HStack() {
//            Text("通知する日付を選択")
//            Spacer()
//
//            VStack(spacing: 0) {
//                ForEach(0..<selectNames.count, id: \.self, content: { index in
//                    HStack {
//                        Text(selectNames[index])
//                        // 解説1
//                        Image(systemName: selectedIndex == index ? "checkmark.circle.fill" : "circle")
//                        //                                .foregroundColor(.blue)
//                    }
//                    .foregroundColor(selectedIndex == index ? .blue : .primary)
//                    .frame(height: 40)
//                    // 解説2
//                    .onTapGesture {
//                        selectedIndex = index
//                    }
//                })
//
//            }
//        }
//    }
//}
struct RadioArea: View {

    @ObservedObject var vm: NotificationSetVM
    

    var body: some View {
        HStack() {
            Text("通知する日付を選択")
            Spacer()

            VStack(spacing: 0) {
                ForEach(NotificationTiming.allCases, id: \.self) { timing in
                    HStack {
                        Text(timing.rawValue)
                        Image(systemName: vm.model.dateType == timing ? "checkmark.circle.fill" : "circle")
                    }
                    .foregroundColor(vm.model.dateType == timing ? .blue : .primary)
                    .frame(height: 40)
                    .onTapGesture {
                        vm.model.dateType = timing
                        //設定を保存
                        vm.changeNotificateSetting()
                    }
                }

            }
        }
    }
}
