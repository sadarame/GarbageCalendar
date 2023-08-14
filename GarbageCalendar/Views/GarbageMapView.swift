//
//  GarbageParentView.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/05/09.
//

import SwiftUI
import MapKit

struct GarbageMapView: View {
    //VM
    @ObservedObject var vm:GarbageMapVM = GarbageMapVM()
    
    var body: some View {
            ZStack {
                VStack(spacing: 0) {
                    //マップエリア
                    MapAreaView(vm:vm)
                    //リストエリア
                    ListView(vm:vm)
                    //ボタンエリア
                    ButtonAreaVeiw(vm:vm)
                        .frame(width: UIScreen.main.bounds.width * 0.9)
                }
                //位置情報取得中にプログレスを全面表示する
                if vm.isShowProgres {EffectProgressView(10)}
            }
            //画面遷移処理
            .navigationDestination(isPresented: $vm.toNextPage, destination: {
                GarbageRegistView()
            })
            //エラーメッセージ表示用モディファイア
            .modifier(CommonViewModifier(vm: vm))
            //ナビゲーション処理
            .navigationBarTitle(Text("エリア検索"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear{
                vm.onAppearInit()
            }
    }
}

struct MapAreaView : View {
    
    @ObservedObject var vm: GarbageMapVM
    
    var body: some View {
        ZStack{
            MapView(region: $vm.region, pinList: $vm.pinList,vm:vm)
            // マップ上の右下にボタンを表示
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Button(action: {
                        vm.getUserMapInfo()
                    }) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                            .padding()
                    }
                    .background(Color.white)
                    .clipShape(Circle())
                    .padding()
                }
            }
        }
    }
}

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var pinList: [MKPointAnnotation]
    @ObservedObject var vm: GarbageMapVM
    
    func makeUIView(context: Context) -> MKMapView {
        MKMapView(frame: .zero)
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        print("MapView")
            uiView.setRegion(region, animated: true)
            
            // 既存のピンを削除
            let existingAnnotations = uiView.annotations
            uiView.removeAnnotations(existingAnnotations)
            
            // 新しいピンを追加
            uiView.addAnnotations(pinList)
       }
}

struct ListView: View {
    @ObservedObject var vm: GarbageMapVM
    
   
    
    var body: some View {
        List {
            //公式フラグがあった場合
            if vm.modelList.contains(where: { $0.officialFlag == "1" }) {
                //公式用セクション
                Section(header: Text("公式")) {
                    ForEach(vm.modelList.filter { $0.officialFlag == "1" }, id: \.self) { model in
                        
                        HStack{
                            Text(model.garbageInfoName ?? "") // モデルのプロパティを表示
                            Spacer()
                            HStack{
                                Text("使用回数:")//あとでアイコン
                                Text(model.usageCount ?? "0")
                            }
                        }
                        
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // 要素がクリックされたときのイベント処理をここに書く
                            vm.handleElementTap(model: model)
                        }
                    }
                }
            }
            //一般人セクション
            Section(header: Text("近くのゴミ情報")) {
                ForEach(vm.modelList.filter { $0.officialFlag != "1" }, id: \.self) { model in
                    
                        HStack{
                            Text(model.garbageInfoName ?? "") // モデルのプロパティを表示
                            Spacer()
                            HStack{
                                Text("使用回数:")//あとでアイコン
                                Text(model.usageCount ?? "0")
                            }
                        }
                    
                    .contentShape(Rectangle())  
                    .onTapGesture {
                         // 要素がクリックされたときのイベント処理をここに書く
                        vm.handleElementTap(model: model)
                     }
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
}

struct ButtonAreaVeiw : View {
    
    @ObservedObject var vm: GarbageMapVM
    
    var body: some View {
        VStack{
            Button(action: {
                //ボタン押下のイベント
                vm.tapNextButton()
            
            }) {
                Text("次へ（該当なし）")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .accentColor(Color.white)
                    .background(Color.blue)
                    .cornerRadius(.infinity)
            }
        }
    }
}


