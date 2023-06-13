//
//  GarbageRegistView.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/05/30.
//

import SwiftUI

//メインView
struct GarbageRegistView: View {
    
    //VM
    @ObservedObject var vm:GarbageRegistVM = GarbageRegistVM()
    
    var body: some View {
        NavigationStack{
            ZStack {
                //ゴミ情報のリスト
                VStack{
            
                        //ゴミ情報リスト
                        GarbageInfoListView(vm: vm)
                        
                        
                    
                }
                //フロートボタン
                //次へボタン
//                ButtonToNextCal(action: vm.registData)
                    FloatButtonView(vm: vm)
                  
                
            }
            //初期処理
//            .onAppear(perform: vm.onApperInit)
            //ナビゲーション処理
            .navigationBarTitle(Text("ゴミ情報登録"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        vm.registData()
                    }) {
                        Text("登録")
                    }
                }
            }
        }
    }
}

//フロートボタン
struct FloatButtonView: View {
    @ObservedObject var vm: GarbageRegistVM
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                ButtonToNextCal(action: vm.registData)
                    .padding()
                FloatingAddButton {
                    // フロートボタンがタップされた時の処理
                    vm.addGarbageInfo()
                }
                .padding()
            }
        }
    }
}

//ゴミ情報のリスト
struct GarbageInfoListView: View {
    @ObservedObject var vm: GarbageRegistVM
    
    var body: some View {
        List{
//        ScrollView{
            ForEach(vm.garbageRegistModelList.indices, id: \.self) { index in
                    VStack {
                        //ゴミの種類
                        CreatePickerView(
                            title: "ゴミの種類",
                            selecteditem: $vm.garbageRegistModelList[index].garbageType,
                            items:vm.garbageTypes
                        )

                        //収集日
                        CreatePickerView(
                            title: "収集日",
                            selecteditem: $vm.garbageRegistModelList[index].schedule,
                            items:vm.schedules
                        )
                        
                        //収集間隔ごとの分岐
                        switch vm.garbageRegistModelList[index].schedule {
                        case "毎週":
                            CreatePickerView(
                                title: "曜日",
                                selecteditem: $vm.garbageRegistModelList[index].yobi,
                                items: vm.yobis
                            )
                        case "隔週":
                            //頻度
                            CreatePickerView(
                                title: "間隔",
                                selecteditem: $vm.garbageRegistModelList[index].freqWeek,
                                items: vm.freqWeeks
                            )
                            //曜日
                            CreatePickerView(
                                title: "曜日",
                                selecteditem: $vm.garbageRegistModelList[index].yobi,
                                items: vm.yobis
                            )
                            //日付
                            DatePicker(selection: $vm.garbageRegistModelList[index].date, displayedComponents: .date) {
                                Text("直近の収集日")
                            }
                            
                            .datePickerStyle(DefaultDatePickerStyle())
                            .environment(\.locale, Locale(identifier: "ja_JP"))
                            .onChange(of: vm.garbageRegistModelList[index].date) { newDate in
                                // 選択が変更されたときの処理
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

                                // Date型をString型に変換
                                vm.garbageRegistModelList[index].strDate = dateFormatter.string(from: newDate)
                                
                            }

                        case "毎月":
                            //毎月が選択されていた場合、日にちを表示する
                            Picker("日付", selection: $vm.garbageRegistModelList[index].day) {
                                ForEach(vm.days, id: \.self) { day in
                                    Text(String(day) + "日")
                                        .tag(day)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            
                        case "第○曜日":
                                //第○曜日が選択されていた場合、第○　と　曜日　を表示する
                                CreatePickerView(
                                    title: "第何週",
                                    selecteditem: $vm.garbageRegistModelList[index].weekOfMonth,
                                    items: vm.weekOfMonths
                                )
                                //曜日
                                CreatePickerView(
                                    title: "曜日",
                                    selecteditem: $vm.garbageRegistModelList[index].yobi,
                                    items: vm.yobis
                                )
                        default:
                            EmptyView()
                        }
                    }
            } .onDelete(perform: delete)
        }
        .navigationBarItems(leading: EditButton())
//        .listStyle(InsetGroupedListStyle())
    }
    private func delete(at offsets: IndexSet) {
        vm.garbageRegistModelList.remove(atOffsets: offsets)
        saveGarbageRegistModels(vm.garbageRegistModelList)
    }
}

//PickerViewを作成する汎用的なView
struct CreatePickerView: View {
    let title:String
    @Binding var selecteditem: String
    @State private var selectedOptionIndex = 0
    let items: [String]
    let label:String = ""
    
    var body: some View {
        Picker(title, selection: $selecteditem) {
            ForEach(items, id: \.self) { selection in
                Text(selection)
            }
        }
//        .onChange(of: selectedOptionIndex) { newValue in
//            // 選択が変更されたときの処理
//            print("Selected option changed to index: \(newValue)")
//        }
        .pickerStyle(MenuPickerStyle())
    }
}

struct ButtonToNextCal : View {
    
    var action: () -> Void
    
    var body: some View {
        VStack{
            Button(action: action) {
                Text("次へ")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .accentColor(Color.white)
                    .background(Color.blue)
                    .cornerRadius(.infinity)
            }
        }
    }
}

struct GarbageRegistView_Previews: PreviewProvider {
    static var previews: some View {
        GarbageRegistView()
    }
}
