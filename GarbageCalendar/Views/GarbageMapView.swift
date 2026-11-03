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
    @StateObject var vm:GarbageMapVM = GarbageMapVM()
    
    var body: some View {
        GeometryReader { geometry in
        ZStack {
            VStack(spacing: 0) {
                //マップエリア
                MapAreaView(vm:vm).frame(height: min(280, geometry.size.height * 0.34))
                if !vm.searchMessage.isEmpty {
                    Text(vm.searchMessage).font(.footnote).padding(8)
                }
                if vm.selectedPin != nil {
                    HStack {
                        Text("選択した場所：\(vm.visibleModels.count)件").font(.subheadline)
                        Spacer()
                        Button("すべて表示") { vm.selectedPin = nil }
                    }.padding(.horizontal).padding(.vertical, 6)

                }
                //リストエリア
                ListView(vm:vm)
                //ボタンエリア
                ButtonAreaVeiw(vm:vm)
                    .frame(width: UIScreen.main.bounds.width * 0.9)
                
                // Search and setup stay focused on selecting a schedule.
                //                        .background(Color.clear)
            }.background(CollectionStyle.background).tint(CollectionStyle.accent)
            //位置情報取得中にプログレスを全面表示する
            if vm.isShowProgres {EffectProgressView(10)}

        }
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
                        vm.callGetGarbageAreaAPI()
                    }) {
                        Image(systemName: "location.fill")
                            .foregroundStyle(CollectionStyle.accent)
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
        let map = MKMapView(frame: .zero)
        map.delegate = context.coordinator
        return map
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        init(_ parent: MapView) { self.parent = parent }
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            DispatchQueue.main.async { self.parent.region = mapView.region }
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let pin = view.annotation as? ScheduleMapAnnotation else { return }
            parent.vm.selectedPin = pin
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: "schedule") as? MKMarkerAnnotationView)
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "schedule")
            view.annotation = annotation
            view.canShowCallout = true
            return view
        }
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        context.coordinator.parent = self
        if abs(uiView.region.center.latitude - region.center.latitude) > 0.00001 ||
            abs(uiView.region.center.longitude - region.center.longitude) > 0.00001 {
            uiView.setRegion(region, animated: true)
        }
        
        // Preserve annotation identity so selecting a pin survives SwiftUI updates.
        let existing = uiView.annotations.filter { !($0 is MKUserLocation) }
        let removed = existing.filter { old in !pinList.contains { $0 === old } }
        let added = pinList.filter { pin in !existing.contains { $0 === pin } }
        uiView.removeAnnotations(removed)
        uiView.addAnnotations(added)
        if vm.selectedPin == nil {
            for annotation in uiView.selectedAnnotations {
                uiView.deselectAnnotation(annotation, animated: false)
            }
        }
    }
}

struct ListView: View {
    @ObservedObject var vm: GarbageMapVM
    @State private var selectedCategory: ScheduleRegistrationCategory = .master
    @ScaledMetric(relativeTo: .subheadline) private var usageColumnWidth = 92

    private var items: [GarbageAreaConvModel] {
        vm.visibleModels.filter { $0.registrationCategory == selectedCategory }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(ScheduleRegistrationCategory.allCases, id: \.self) { category in
                    let count = vm.visibleModels.filter { $0.registrationCategory == category }.count
                    let title = category == .master ? "公式確認済み収集日" : "利用者登録の収集日"
                    Button { selectedCategory = category } label: {
                        VStack(spacing: 4) {
                            Text(title)
                                .font(.caption.weight(.semibold))
                                .fixedSize(horizontal: false, vertical: true)
                            Text("\(count)件")
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .padding(.horizontal, 4)
                        .foregroundStyle(selectedCategory == category ? Color.white : CollectionStyle.forest)
                        .background(selectedCategory == category ? CollectionStyle.forest : CollectionStyle.forest.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedCategory == category ? .isSelected : [])
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            if items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.title2)
                    Text("該当する収集日はありません")
                        .font(.subheadline)
                    Text("別のタブや地図の場所を選んでください")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Text("地域・収集日")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("利用者数")
                            .frame(width: usageColumnWidth, alignment: .trailing)
                        Color.clear.frame(width: 8, height: 1)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(CollectionStyle.forest.opacity(0.08))
                    Divider()

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(items, id: \.self) { model in
                                Button { vm.handleElementTap(model: model) } label: {
                                    HStack(spacing: 12) {
                                        Text(model.garbageInfoName ?? "名称なし")
                                            .font(.subheadline.weight(.medium))
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        VStack(alignment: .trailing, spacing: 3) {
                                            Text(model.usageCount.map { "\($0)人" } ?? "未集計")
                                                .font(.subheadline.weight(.semibold))
                                                .monospacedDigit()
                                            if model.usageCount == nil, let legacy = model.legacyUsageCount {
                                                Text("過去 \(legacy)件")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .frame(width: usageColumnWidth, alignment: .trailing)
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .frame(width: 8)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .frame(minHeight: 56)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("収集日を確認します")
                                Divider().padding(.leading, 16)
                            }
                        }
                    }
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                if items.contains(where: { $0.usageCount == nil && $0.legacyUsageCount != nil }) {
                    Text("過去の件数は旧版での利用実績です。現在の利用者数とは異なります。")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
            }
        }
        .onAppear(perform: selectAvailableCategory)
        .onChange(of: vm.visibleModels) { _ in selectAvailableCategory() }
    }

    private func selectAvailableCategory() {
        // When a search or pin changes, show an available category if this one is empty.
        if items.isEmpty, let first = vm.visibleModels.first {
            selectedCategory = first.registrationCategory
        }
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
                Text("手動で登録する")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .background(CollectionStyle.forest)
                    .cornerRadius(.infinity)
            }
        }
    }
}


