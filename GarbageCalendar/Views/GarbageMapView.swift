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
//        NavigationStack{
            ZStack {
                VStack(spacing: 0) {
                    //マップエリア
                    MapAreaView(vm:vm)
                    //リストエリア
                    ListView(vm:vm)
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
//        }
    }
}

struct MapAreaView : View {
    
    @ObservedObject var vm: GarbageMapVM
    
    var body: some View {
        ZStack{
            MapView(region: $vm.region, pinList: $vm.pinList)
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
    
    func makeUIView(context: Context) -> MKMapView {
        MKMapView(frame: .zero)
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
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
            Section(header: Text("近くのゴミ情報")) {
                ForEach(vm.modelList.indices, id: \.self) { index in
                    HStack{
                        Text(vm.modelList[index].garbageInfoName ?? "") // モデルのプロパティを表示
                        Spacer()
                        HStack{
                            Text("使用回数:")//あとでアイコン
                            Text(vm.modelList[index].usageCount ?? "0")
                        }
                        //ToDo公式フラグが立っていたらアイコン表示
                        if vm.modelList[index].officialFlag ?? false {
                            Text("公式フラグ:")//あとでアイコン
                        }
                    }
                    .contentShape(Rectangle())  
                    .onTapGesture {
                         // 要素がクリックされたときのイベント処理をここに書く
                        vm.handleElementTap(model: vm.modelList[index])
                     }
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
}


