//
//  GarbageRegistView.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/05/30.
//

import SwiftUI

struct GarbageRegistView: View {
    
    //VM
    @ObservedObject var vm:GarbageRegistVM = GarbageRegistVM()
    
    //日付用
    @State private var selectedDate = Date()
    @State private var selectionDate = Date()
 
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: selectedDate)
    }
    
    
    //各週で使う日付FMT用
    var df:DateFormatter{
        let df = DateFormatter()
        df.dateFormat = "yyyy/MM/dd"
        df.locale = Locale(identifier: "ja_JP")
        return df
    }
    
    var body: some View {
        ZStack {
//            ScrollView {
                List{
                    ForEach(vm.garbageRegistModelList.indices, id: \.self) { index in
                        VStack {
                            //ゴミの種類
                            Picker("ゴミの種類", selection: $vm.garbageRegistModelList[index].garbageType) {
                                ForEach(vm.garbageRegistModelList[index].garbageTypes, id: \.self) { selection in
                                    Text(selection)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            
                            //スケジュール
                            Picker("収集日", selection: $vm.garbageRegistModelList[index].schedule) {
                                ForEach(vm.garbageRegistModelList[index].schedules, id: \.self) { selection in
                                    Text(selection)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            
                            
                            //毎週が選択されていた場合、曜日を表示
                            if vm.garbageRegistModelList[index].schedule == "毎週" {
                                Picker("選択肢", selection: $vm.garbageRegistModelList[index].yobi) {
                                    ForEach(vm.garbageRegistModelList[index].yobis, id: \.self) { selection in
                                        Text(selection)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            if vm.garbageRegistModelList[index].schedule == "各週" {
                                
                                
                                //間隔
                                Picker("間隔", selection: $vm.garbageRegistModelList[index].freqWeek) {
                                    ForEach(vm.garbageRegistModelList[index].freqWeeks, id: \.self) { selection in
                                        Text(selection)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                
                                //曜日
                                Picker("曜日", selection: $vm.garbageRegistModelList[index].yobi) {
                                    ForEach(vm.garbageRegistModelList[index].yobis, id: \.self) { selection in
                                        Text(selection)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                
                                DatePicker(selection: $selectedDate, displayedComponents: .date) {
                                    Text("直近の収集日")
                                }
                                .datePickerStyle(DefaultDatePickerStyle())
                                
        
                            }
                            
                        
                            
                            
                            //毎月が選択されていた場合、日にちを表示する
                            if vm.garbageRegistModelList[index].schedule == "毎月" {
                                Picker("日付", selection: $vm.garbageRegistModelList[index].day) {
                                    ForEach(vm.garbageRegistModelList[index].days, id: \.self) { day in
                                        Text(String(day) + "日").tag(day)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            //第○曜日が選択されていた場合、第○　と　曜日　を表示する
                            if vm.garbageRegistModelList[index].schedule == "第○曜日" {
                                HStack{
                                    Picker("第○", selection: $vm.garbageRegistModelList[index].weekOfMonth) {
                                        ForEach(vm.garbageRegistModelList[index].weekOfMonths, id: \.self) { selection in
                                            Text(selection)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    
                                    //曜日
                                    Picker("曜日", selection: $vm.garbageRegistModelList[index].yobi) {
                                        ForEach(vm.garbageRegistModelList[index].yobis, id: \.self) { selection in
                                            Text(selection)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                }
                            }
                        }
                    } .onDelete(perform: delete)
                }
                .navigationTitle("People")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
//                    }
                }
            }
            
            // 他のビュー要素
            // ...
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton {
                        // フロートボタンがタップされた時の処理
                            vm.addGarbageInfo()
                    }
                    .padding()
                }
            }
        }
    }
    
    private func delete(at offsets: IndexSet) {
        vm.garbageRegistModelList.remove(atOffsets: offsets)
    }
}

struct GarbageRegistView_Previews: PreviewProvider {
    static var previews: some View {
        GarbageRegistView()
    }
}
