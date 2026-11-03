import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        if loadDestination() == Const.view_CalendarView || !loadGarbageRegistModels().isEmpty {
            CalendarView()
        } else {
            CollectionSetupView()
        }
    }
}

struct CollectionSetupView: View {
    @StateObject private var location = UserAddressRegistVM()
    @State private var requestingPermission = false
    @State private var page = 0
    @State private var chooseArea = false
    private let titles = ["近くの収集日", "地域の収集日をかんたん設定", "ウィジェットで確認"]
    private let descriptions = [
        "位置情報を許可すると、\n近くの収集日を探せます。",
        "ほかの人が登録した収集日を選ぶだけ。\n種類や曜日を入力する手間が省けます。",
        "今日・明日のゴミ出しを、\nホーム画面でひと目で確認。"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TabView(selection: $page) {
                    ForEach(0..<3) { index in
                        ScrollView {
                            VStack(spacing: 22) {
                                illustration(index).frame(maxWidth: 300).frame(height: 320)
                                    .accessibilityElement(children: .ignore)
                                    .accessibilityLabel(titles[index])
                                Text(titles[index]).font(.system(size: 26, weight: .bold, design: .rounded))
                                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                                Text(descriptions[index])
                                    .font(.body).lineSpacing(5)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)

                            }.padding(.horizontal, 24).padding(.top, 32)
                        }.tag(index)
                    }
                }.tabViewStyle(.page(indexDisplayMode: .never))
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Button { withAnimation { page = index } } label: {
                            Capsule().fill(CollectionStyle.forest.opacity(page == index ? 1 : 0.2))
                                .frame(width: page == index ? 24 : 8, height: 8).padding(.vertical, 12)
                        }.accessibilityLabel("説明 \(index + 1) / 3")
                    }
                }
                Button(action: advance) {
                    HStack {
                        Text(page == 0 ? "位置情報を許可して次へ" : (page == 1 ? "次へ" : "はじめる")).fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }.frame(maxWidth: .infinity).padding(18).foregroundStyle(.white)
                        .background(CollectionStyle.forest, in: RoundedRectangle(cornerRadius: 18))
                }.disabled(requestingPermission).padding(.horizontal, 24).padding(.bottom, 24)

            }
            .foregroundStyle(CollectionStyle.forest)
            .background(CollectionStyle.onboarding.ignoresSafeArea())
            .tint(CollectionStyle.forest)
            .navigationDestination(isPresented: $chooseArea) { UserAddressRegistView() }
        }
    }

    private func advance() {
        if page == 0 {
            requestingPermission = true
            location.requestPermission {
                requestingPermission = false
                withAnimation { page = 1 }
            }
        } else if page == 1 { withAnimation { page = 2 } }
        else { chooseArea = true }
    }

    private func mapPin(_ type: String) -> some View {
        VStack(spacing: 0) {
            CollectionIcon(type: type, size: 38).padding(10)
                .background(.white, in: RoundedRectangle(cornerRadius: 18))
            Image(systemName: "triangle.fill").font(.system(size: 14))
                .rotationEffect(.degrees(180)).foregroundStyle(.white).offset(y: -3)
        }
    }

    @ViewBuilder private func illustration(_ index: Int) -> some View {
        if index == 0 {
            ZStack {
                RoundedRectangle(cornerRadius: 32).fill(.white.opacity(0.45))
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 95))
                    path.addLine(to: CGPoint(x: 300, y: 205))
                    path.move(to: CGPoint(x: 95, y: 0))
                    path.addLine(to: CGPoint(x: 190, y: 280))
                    path.move(to: CGPoint(x: 250, y: 0))
                    path.addLine(to: CGPoint(x: 40, y: 280))
                }.stroke(.white.opacity(0.85), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                Circle().fill(CollectionStyle.forest.opacity(0.12)).frame(width: 150, height: 150)
                Circle().fill(CollectionStyle.forest).frame(width: 18, height: 18)
                    .overlay(Circle().stroke(.white, lineWidth: 4))
                mapPin("燃えるゴミ").offset(x: -75, y: -70)
                mapPin("プラスチック").offset(x: 75, y: -15)
                mapPin("ビン・カン").offset(x: -30, y: 85)
            }.frame(width: 300, height: 280).clipShape(RoundedRectangle(cornerRadius: 32))
        } else if index == 1 {
            VStack(spacing: 16) {
                HStack(spacing: 46) {
                    ForEach(0..<3) { _ in
                        Image(systemName: "person.crop.circle.fill").font(.system(size: 42))
                    }
                }
                HStack(spacing: 70) {
                    Image(systemName: "arrow.down.right")
                    Image(systemName: "arrow.down")
                    Image(systemName: "arrow.down.left")
                }.font(.title2.bold())
                HStack(spacing: 14) {
                    ForEach(["燃えるゴミ", "プラスチック", "ビン・カン"], id: \.self) { type in
                        CollectionIcon(type: type, size: 46).padding(10)
                            .background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 18))
                    }
                }
                Image(systemName: "arrow.down").font(.title2.bold())
                Image(systemName: "calendar.badge.checkmark").font(.system(size: 48))
            }
        } else {
            VStack(spacing: 16) {
                Capsule().fill(CollectionStyle.forest).frame(width: 66, height: 7)
                VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("明日").font(.headline.bold())
                    Spacer()
                    Text(CollectionStyle.date(ScheduleEngine.calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date(), format: "M/d（E）"))
                        .font(.caption.weight(.semibold))
                }
                HStack(spacing: 8) {
                    ForEach(["燃えるゴミ", "プラスチック"], id: \.self) { type in
                        VStack(spacing: 6) {
                            CollectionIcon(type: type, size: 40)
                            Text(type).font(.caption.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }.padding(18).frame(maxWidth: 300)
                .background(CollectionStyle.onboarding, in: RoundedRectangle(cornerRadius: 28))
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(CollectionStyle.forest.opacity(0.15), lineWidth: 1))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                    ForEach(0..<8) { _ in
                        RoundedRectangle(cornerRadius: 10).fill(CollectionStyle.forest.opacity(0.12))
                            .frame(height: 34)
                    }
                }.padding(.horizontal, 8)
            }.padding(16).frame(width: 280)
                .background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 32))
                .overlay(RoundedRectangle(cornerRadius: 32).stroke(CollectionStyle.forest.opacity(0.3), lineWidth: 3))
        }
    }
}
