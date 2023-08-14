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
        ScrollViewReader { scrollViewProxy in
            ZStack {
                //ゴミ情報のリスト
                VStack{
                    //ゴミ情報名称エリア
                    GarbageInfoNameAreaView(vm: vm)
                    //ゴミ情報リスト
                    GarbageInfoListView(vm: vm)
                    //ボタンエリア
                    HStack(spacing: 10) {
                        //次へボタン
                        ButtonToNextCal(action: vm.registData)
                            .frame(width: UIScreen.main.bounds.width * 0.7)
                        //プラスボタン
                        ButtonToAdd(action: vm.addGarbageInfo)
                            .frame(width: UIScreen.main.bounds.width * 0.1)
                    }
                }
                //位置情報取得中にプログレスを全面表示する
                if vm.isShowProgres {EffectProgressView(10)}
            }
            .onAppear {
                vm.onApperInit()
            }
            //画面遷移処理
            .navigationDestination(isPresented: $vm.toNextPage, destination: {
                CalendarView()
            })
            //エラーメッセージ表示用モディファイア
            .modifier(CommonViewModifier(vm: vm))
            //ナビゲーション処理
            .navigationBarTitle(Text("ゴミ情報登録"))
            .navigationBarTitleDisplayMode(.inline)
            
        }
    }
}

//ゴミ情報の名称エリア
struct GarbageInfoNameAreaView: View {
    @ObservedObject var vm: GarbageRegistVM
    
    var body: some View {
        //ゴミ名称エリア
      
        HStack(spacing: 10){
            Text("名称")
                .font(.headline)
            TextField("名称", text: $vm.garbageInfoName)
                .padding(8)
                .clipShape(RoundedRectangle(cornerRadius: 15.0))
                .background(Color(red: 239.0/255.0, green: 243.0/255, blue: 244.0/255.0, opacity:1.0))
                .textFieldStyle(.plain)
        }.padding(8)
    }
}


// MARK: - ゴミ情報のScrollView
struct GarbageInfoListView: View {
    @ObservedObject var vm: GarbageRegistVM
    
    var body: some View {
        
        ScrollViewReader { scrollViewProxy in
            ScrollView{
                //モデルリストの件数文繰り返し
                ForEach(vm.garbageRegistModelList.indices, id: \.self) { index in
                    
                    VStack {
                        if index < vm.garbageRegistModelList.count {
                            CardView(vm: vm, index: index)
                        }
                    }
                    //カード形式の外の余白
                    .padding(.horizontal,16)
                    .padding(.bottom, 16)
                    .onAppear {
                           // Automatically scroll to the bottom when new elements are added
                           if index == vm.garbageRegistModelList.count - 1 {
                               scrollViewProxy.scrollTo(index, anchor: .bottom)
                           }
                       }
                }
            }
            
        }
    }
}

// MARK: - カード形式
struct CardView: View {
    @ObservedObject var vm: GarbageRegistVM
    
    @State var index: Int
    var body: some View {
        if index < vm.garbageRegistModelList.count {
            VStack(alignment: .leading) {
                VStack{
                    HStack {
                        Text("ゴミの種類")
                            .font(.headline)
                        
                        Spacer()
                        
                        
                        CreatePickerView(
                            selecteditem: $vm.garbageRegistModelList[index].garbageType,
                            items: vm.garbageTypes
                        )
                    }
                    
                    HStack {
                        Text("収集日")
                            .font(.headline)
                        
                        
                        Spacer()
                        
                        CreatePickerView(
                            selecteditem: $vm.garbageRegistModelList[index].schedule,
                            items: vm.schedules
                        )
                    }
                    
                    switch vm.garbageRegistModelList[index].schedule {
                    case "毎週":
                        HStack {
                            Text("曜日")
                                .font(.headline)
                            
                            
                            Spacer()
                            
                            CreatePickerView(
                                selecteditem: $vm.garbageRegistModelList[index].yobi,
                                items: vm.yobis
                            )
                        }
                        
                    case "隔週":
                        HStack {
                            Text("間隔")
                                .font(.headline)
                            
                            
                            Spacer()
                            
                            CreatePickerView(
                                selecteditem: $vm.garbageRegistModelList[index].freqWeek,
                                items: vm.freqWeeks
                            )
                        }
                        
                        HStack {
                            Text("曜日")
                                .font(.headline)
                            
                            
                            Spacer()
                            
                            CreatePickerView(
                                selecteditem: $vm.garbageRegistModelList[index].yobi,
                                items: vm.yobis
                            )
                        }
                        
                        HStack {
                            Text("直近の収集日")
                                .font(.headline)
                            
                            
                            Spacer()
                            
                            DatePicker(selection: $vm.garbageRegistModelList[index].date, displayedComponents: .date) {
                                EmptyView()
                            }
                            .datePickerStyle(DefaultDatePickerStyle())
                            .environment(\.locale, Locale(identifier: "ja_JP"))
                        }
                        
                    case "毎月":
                        HStack {
                            Text("日付")
                                .font(.headline)
                            
                            
                            Spacer()
                            
                            Picker("日付", selection: $vm.garbageRegistModelList[index].day) {
                                ForEach(vm.days, id: \.self) { day in
                                    Text(String(day) + "日")
                                        .tag(day)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                    case "第○曜日":
                        HStack {
                            Text("第何週")
                                .font(.headline)
                                .padding(.trailing, 8) // 右側に8ポイントの余白を追加
                            
                            Spacer()
                            
                            CreatePickerView(
                                selecteditem: $vm.garbageRegistModelList[index].weekOfMonth,
                                items: vm.weekOfMonths
                            )
                        }
                        
                        HStack {
                            Text("曜日")
                                .font(.headline)
                                .padding(.trailing, 8) // 右側に8ポイントの余白を追加
                            
                            Spacer()
                            
                            CreatePickerView(
                                selecteditem: $vm.garbageRegistModelList[index].yobi,
                                items: vm.yobis
                            )
                        }
                        
                    default:
                        EmptyView()
                    }
                }.padding(.horizontal,16)
            }
                    .modifier(
                        CardStyle(
                            //重複エラーのフラグを渡す
                            duplicateError: vm.garbageRegistModelList[index].duplicateError,
                            deleteCard: {
                                //削除用のメソッドを渡す
                                vm.deleteCard(at: index)
                            }
                        )
                    )
        }
    }
}

//カードViewのモディファイアを定義
struct CardStyle: ViewModifier {
    
    var duplicateError: Bool
    var deleteCard: (() -> Void)
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(duplicateError ? Color.red.opacity(0.5) : Color(red: 239.0/255.0, green: 243.0/255.0, blue: 244.0/255.0))
            .cornerRadius(10)
            .shadow(color: Color.gray.opacity(0.3), radius: 3, x: 0, y: 2)
            .frame(maxWidth: .infinity)
            //閉じるボタン押下時の処理
            .overlay(
                Button(action: {
                    deleteCard()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                }
                    .padding(8)
                    .offset(x: 5, y: -0), // ボタンを右上にオフセット
                alignment: .topTrailing // ボタンの配置を右上に指定
            )
    }
}

//PickerViewを作成する汎用的なView
struct CreatePickerView: View {
    //タイトル
    let title:String
    //選択値
    @Binding var selecteditem: String
    //選択肢
    let items: [String]
    //イベント
    var selectionChanged: (() -> Void)? = nil
    
    
    init(title: String = "", selecteditem: Binding<String>, items: [String], selectionChanged: (() -> Void)? = nil) {
        self.title = title
        self._selecteditem = selecteditem
        self.items = items
        self.selectionChanged = selectionChanged
    }
    
    var body: some View {
        Picker(title, selection: $selecteditem) {
            ForEach(items, id: \.self) { selection in
                Text(selection)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .onChange(of: selecteditem) { _ in
            selectionChanged?()
        }
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
struct ButtonToAdd : View {
    
    var action: () -> Void
    
    var body: some View {
        VStack{
            Button(action: action) {
                Image(systemName: "plus")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .accentColor(Color.white)
                    .background(Color.blue)
                    .cornerRadius(.infinity)
            }
        }
    }
}


