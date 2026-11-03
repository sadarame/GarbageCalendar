import SwiftUI
import MessageUI
import StoreKit

struct CalendarView: View {
    @StateObject var vm = CalendarVM()
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase
    @State private var isMenuOpen = false
    @State private var isRegionSearchPresented = false
    @State private var showTutorial = false
    @State private var showAppRemoval = false
    @State private var showPrivacySettings = false
    @State private var showCollectionInfo = false
    @ObservedObject private var consent = AdvertisingConsent.shared
    @AppStorage("privacy.explained") private var privacyExplained = false
    @ObservedObject private var session = UserSession.shared

    var body: some View {
        NavigationStack {
            ZStack(alignment: .leading) {
                CollectionMonthView(vm: vm)
                if isMenuOpen {
                    Color.black.opacity(0.25).ignoresSafeArea().onTapGesture { isMenuOpen = false }
                    settings.frame(maxWidth: 290).background(Color(uiColor: .systemBackground))
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if consent.canShowAds {
                  VStack(spacing: 0) {
                    Divider()
                    AdMobBannerView()
                        .id(consent.adGeneration)
                        .frame(width: 320, height: 50)
                        .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .systemBackground))
                }
            }
            .tint(CollectionStyle.accent)
            .navigationTitle("ゴミ情報カレンダー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { isMenuOpen.toggle() } label: {
                        Image(systemName: "line.horizontal.3").frame(width: 44, height: 44)
                    }.accessibilityLabel(isMenuOpen ? "メニューを閉じる" : "メニューを開く")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { vm.isSheetPresented = true } label: {
                        Image(systemName: "bell").frame(width: 44, height: 44)
                    }.accessibilityLabel("通知設定")
                }
            }
            .navigationBarBackButtonHidden(true)
            .modifier(CommonViewModifier(vm: vm))
            .navigationDestination(isPresented: $vm.isGarbageRegistView) { GarbageRegistView() }
            .navigationDestination(isPresented: $isRegionSearchPresented) { UserAddressRegistView() }
            .sheet(isPresented: $showPrivacySettings, onDismiss: { consent.gather() }) { PrivacySettingsView() }
            .sheet(isPresented: $showCollectionInfo) {
                CollectionInfoView(name: loadGarbageInfoName() ?? "この地域の収集予定", reference: CollectionReference.load())
            }
            .sheet(isPresented: $showTutorial) { CollectionSetupView() }
            .sheet(isPresented: $vm.isShowingMailView) { MailView(isShowing: $vm.isShowingMailView) }
            .sheet(isPresented: $vm.isSheetPresented) { NotificationSetView(isPresented: $vm.isSheetPresented) }
            .disabled(session.isResetting)
            .overlay {
                if session.isResetting {
                    ProgressView("ユーザー情報を削除しています…")
                        .padding(24).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .alert("ユーザー情報を削除しますか？", isPresented: $showAppRemoval) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    Task { @MainActor in
                        do { try await session.reset() }
                        catch { vm.showPopup(withMessage: "初期化を完了できませんでした。通信を確認して再試行してください。端末のデータはまだ残っています。") }
                    }
                }
            } message: {
                Text("端末の予定・通知設定とサーバーのユーザー情報を削除します。共有した地域の予定は、ユーザーとの紐付けを外して残ります。共有予定の削除はお問い合わせからご連絡ください。この操作は取り消せません。")
            }
            .onAppear {
                vm.garbageRegistModelList = loadGarbageRegistModels()
                vm.onapperInit()
                if !privacyExplained { showPrivacySettings = true }
                else { consent.gather() }
            }
            .onChange(of: vm.isGarbageRegistView) { showing in
                if !showing { vm.garbageRegistModelList = loadGarbageRegistModels() }
            }
            .task(id: scenePhase) {
                guard scenePhase == .active else { return }
                if privacyExplained && !showPrivacySettings { consent.gather() }
                vm.garbageRegistModelList = loadGarbageRegistModels()
                guard !vm.garbageRegistModelList.isEmpty else { return }
                guard !session.isResetting else { return }
                do { try await CollectionAPI.shared.syncSavedContributionIfNeeded() }
                catch {
#if DEBUG
                    let failure = error as NSError
                    NSLog("[CollectionSync] %@ code=%ld: %@", failure.domain, failure.code, failure.localizedDescription)
#endif
                    guard !session.isResetting else { return }
                    vm.showPopup(withMessage: "収集予定をサーバーに保存できませんでした。端末の予定は残っています。")
                    return
                }
                guard !session.isResetting else { return }
                let policy = ReviewRequestPolicy()
                policy.recordUse()
                do { try await Task.sleep(for: .seconds(30)) } catch { return }
                guard !Task.isCancelled, scenePhase == .active, !session.isResetting,
                      !vm.garbageRegistModelList.isEmpty, !isMenuOpen, !showTutorial,
                      !vm.isSheetPresented, !vm.isShowingMailView, !vm.isGarbageRegistView, !isRegionSearchPresented,
                      !vm.isShowingPopup, !vm.isShowProgres, !vm.isLoading,
                      !vm.isAlertAppStore, !showAppRemoval, !showPrivacySettings, !showCollectionInfo, !consent.isBusy else { return }
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
                guard policy.isEligible(version: version) else { return }
                policy.recordRequest(version: version)
                requestReview()
            }
        }
    }

    private var settings: some View {
        List {
            Section("収集予定") {
                Button {
                    isMenuOpen = false
                    showCollectionInfo = true
                } label: {
                    Label("この収集情報について", systemImage: "info.circle")
                }
                Button {
                    saveTriggerFlg(Const.TRG_SIDE_MENU)
                    isMenuOpen = false
                    vm.isGarbageRegistView = true
                } label: {
                    Label("収集日を編集", systemImage: "calendar.badge.clock")
                }
                Button {
                    isMenuOpen = false
                    isRegionSearchPresented = true
                } label: {
                    Label("地域の予定を探す", systemImage: "map")
                }
            }
            Section("サポート") {
                Button {
                    isMenuOpen = false
                    showPrivacySettings = true
                } label: { Label("プライバシー設定", systemImage: "hand.raised") }
                Button("使い方・ウィジェット") { isMenuOpen = false; showTutorial = true }
                // Explicit requests use the review page: StoreKit may suppress automatic prompts.
                Link(destination: URL(string: "https://apps.apple.com/app/id6459478923?action=write-review")!) {
                    Label("アプリを評価する", systemImage: "star.bubble")
                }
                if MFMailComposeViewController.canSendMail() {
                    Button {
                        isMenuOpen = false
                        vm.isShowingMailView = true
                    } label: { Label("お問い合わせ", systemImage: "envelope") }
                } else {
                    Link(destination: URL(string: "mailto:sadarame@gmail.com")!) {
                        Label("お問い合わせ", systemImage: "envelope")
                    }
                }
                Button {
                    isMenuOpen = false
                    vm.openWebsite()
                } label: { Label("プライバシーポリシー", systemImage: "hand.raised") }
            }
            Section {
                Button {
                    isMenuOpen = false
                    showAppRemoval = true
                } label: {
                    Label("ユーザー情報を削除・初期化", systemImage: "trash").foregroundStyle(.red)
                }
            }
        }.scrollContentBackground(.hidden).background(CollectionStyle.background)
    }

}

/// Persistent request history, not a record of ratings or completed reviews.
struct ReviewRequestPolicy {
    var defaults: UserDefaults = .standard
    var calendar: Calendar = .current
    private let prefix = "reviewRequest.v1."

    func recordUse(now: Date = Date()) {
        if defaults.object(forKey: prefix + "firstUse") == nil {
            defaults.set(now, forKey: prefix + "firstUse")
        }
        if let last = defaults.object(forKey: prefix + "lastUse") as? Date,
           calendar.isDate(last, inSameDayAs: now) { return }
        defaults.set(now, forKey: prefix + "lastUse")
        defaults.set(defaults.integer(forKey: prefix + "days") + 1, forKey: prefix + "days")
    }

    func isEligible(version: String, now: Date = Date()) -> Bool {
        guard let first = defaults.object(forKey: prefix + "firstUse") as? Date,
              now.timeIntervalSince(first) >= 7 * 86400,
              defaults.integer(forKey: prefix + "days") >= 3,
              defaults.string(forKey: prefix + "version") != version else { return false }
        if let last = defaults.object(forKey: prefix + "lastRequest") as? Date,
           now.timeIntervalSince(last) < 180 * 86400 { return false }
        return true
    }

    func recordRequest(version: String, now: Date = Date()) {
        defaults.set(version, forKey: prefix + "version")
        defaults.set(now, forKey: prefix + "lastRequest")
    }
}

// MARK: - カレンダーエリア
struct CollectionMonthView: View {
    @ObservedObject var vm: CalendarVM
    @State private var reference = CollectionReference.load()
    @State private var selection = ScheduleEngine.calendar.startOfDay(for: Date())
    @State private var periodStart = Self.startOfMonth(containing: Date())
    @ScaledMetric(relativeTo: .subheadline) private var dayNumberHeight: CGFloat = 20
    private let columns = Array(repeating: GridItem(.flexible(minimum: 0), spacing: 0), count: 7)
    private var isSaitama: Bool {
        // Use the selected schedule's municipality before the device user's address.
        let locality = loadGarbageAreaConvModel()?.locality ?? loadUserAddressRegistModel()?.locality ?? ""
        return locality.hasPrefix("さいたま市")
    }
    private func resourceSummary(_ type: String) -> String? {
        guard isSaitama else { return nil }
        let name = type.folding(options: .widthInsensitive, locale: Locale(identifier: "ja_JP"))
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "一", with: "1")
            .replacingOccurrences(of: "二", with: "2")
        switch name {
        case "資源1類", "資源物1類": return "びん・缶・ペットボトル・プラスチック"
        case "資源2類", "資源物2類": return "紙類・古着・タオルなど"
        default: return nil
        }
    }
    private func collectionLabel(_ type: String, on date: Date) -> some View {
        HStack(alignment: .top, spacing: 6) {
            CollectionIcon(type: type, size: 24, iconType: CollectionStyle.iconType(for: type, on: date, models: vm.garbageRegistModelList))
            VStack(alignment: .leading, spacing: 3) {
                Text(type).font(.subheadline.weight(.medium))
                if let summary = resourceSummary(type) {
                    Text(summary).font(.caption).foregroundStyle(.secondary)
                }
            }.fixedSize(horizontal: false, vertical: true)
        }
    }
    private var resourceGuide: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("さいたま市の資源物の分け方", systemImage: "info.circle").font(.headline)
            Text("1類：びん・缶・ペットボトル・プラスチック")
                .font(.subheadline.bold())
            Text("汚れをすすぎ、種類ごとに別の透明袋へ。ペットボトルのキャップとラベルは外してプラスチック資源へ。")
            Text("2026年10月から、プラスチック100％で30cm未満の製品も対象です。油や落ちない汚れがあるプラスチックは、もえるごみへ。")
            Link("1類の詳しい出し方（市公式）", destination: URL(string: "https://www.city.saitama.lg.jp/001/006/010/003/p001909.html")!)
            Divider()
            Text("2類：紙類・古着・タオルなど").font(.subheadline.bold())
            Text("新聞・段ボール・牛乳パック・雑誌・古着などを、種類ごとにひもで縛ります。雨の日は次週に出すか、ぬれないよう透明袋へ。")
            Link("2類の詳しい出し方（市公式）", destination: URL(string: "https://www.city.saitama.lg.jp/001/006/010/003/p001910.html")!)
        }
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 12)
    }
    private func types(_ date: Date) -> [String] {
        Array(Set(vm.garbageRegistModelList.filter { ScheduleEngine.matches($0, on: date) }.map(\.garbageType))).sorted()
    }
    private func collectionCard(on date: Date, highlighted: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 2) {
                Text(CollectionStyle.date(date, format: "d")).font(.title2.bold())
                Text(CollectionStyle.date(date, format: "（E）")).font(.caption.bold())
            }.foregroundStyle(weekdayColor(date)).frame(width: 42)
            if types(date).isEmpty {
                Text("収集予定はありません")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], alignment: .leading, spacing: 8) {
                    ForEach(types(date), id: \.self) { type in
                        collectionLabel(type, on: date)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
        }.padding(14)
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                if highlighted {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(CollectionStyle.accent.opacity(0.35), lineWidth: 1)
                }
            }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    HStack {
                        Button { movePeriod(-1) } label: {
                            Image(systemName: "chevron.left").frame(width: 44, height: 44)
                        }.accessibilityLabel("前の月")
                        Spacer(minLength: 0)
                        Text(CollectionStyle.date(periodStart, format: "yyyy年M月"))
                            .font(.title2.bold())
                        Spacer(minLength: 0)
                        Button { movePeriod(1) } label: {
                            Image(systemName: "chevron.right").frame(width: 44, height: 44)
                        }.accessibilityLabel("次の月")
                    }.padding(.horizontal)
                    VStack(spacing: 0) {
                        LazyVGrid(columns: columns, spacing: 0) {
                            ForEach(Array(days.prefix(7)), id: \.self) { date in
                                Text(CollectionStyle.date(date, format: "E"))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(weekdayColor(date))
                                    .lineLimit(1).minimumScaleFactor(0.5)
                                    .frame(maxWidth: .infinity).frame(height: dayNumberHeight + 4)
                            }
                        }
                        LazyVGrid(columns: columns, spacing: 0) {
                            ForEach(days, id: \.self) { date in dayCell(date) }
                        }
                    }
                    if !ScheduleEngine.calendar.isDate(periodStart, inSameDayAs: Self.startOfMonth(containing: Date())) ||
                        !ScheduleEngine.calendar.isDate(selection, inSameDayAs: Date()) {
                        Button("今日へ戻る") {
                            let today = ScheduleEngine.calendar.startOfDay(for: Date())
                            periodStart = Self.startOfMonth(containing: today)
                            selection = today
                        }.buttonStyle(.bordered).frame(minHeight: 44)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text(ScheduleEngine.calendar.isDateInToday(selection) ? "本日の収集予定" : "選択日の収集予定")
                            .font(.headline).padding(.top, 4)
                        collectionCard(on: selection, highlighted: true)
                    }.padding(.horizontal, 12).id("selection")
                    if isSaitama && vm.garbageRegistModelList.contains(where: { resourceSummary($0.garbageType) != nil }) {
                        resourceGuide
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text(CollectionStyle.date(periodStart, format: "M月の収集日"))
                            .font(.headline).padding(.top, 4)
                        let collectionDays = days.filter { isDisplayedMonth($0) && !types($0).isEmpty }
                        if collectionDays.isEmpty {
                            Text("この月の収集予定はありません")
                                .foregroundStyle(.secondary).padding(.vertical, 12)
                        }
                        ForEach(collectionDays, id: \.self) { date in
                            collectionCard(on: date)
                        }
                    }.padding(.horizontal, 12).padding(.bottom, 16)
                }.frame(maxWidth: 640).frame(maxWidth: .infinity)
            }.background(Color(uiColor: .systemBackground))
        }
        .task {
            reference = CollectionReference.load()
            // Recover the selection for calendars saved before references were supported.
            if reference == nil, let selected = loadGarbageAreaConvModel(),
               selected.garbageInfoName == loadGarbageInfoName(),
               let id = selected.garbageGroupId {
                reference = CollectionReference(scheduleId: id)
            }
            guard let current = reference else { return }
            do {
                let response: SharedScheduleResponse = try await CollectionAPI.shared.call(
                    "getSharedScheduleV2", data: ["id": current.scheduleId])
                guard !Task.isCancelled, !UserSession.shared.isResetting else { return }
                let updated = CollectionReference(scheduleId: response.id, sourceUrl: response.sourceUrl)
                reference = updated
                CollectionReference.save(updated)
            } catch {
                // A cached reference remains available while offline.
            }
        }
    }
    private static func startOfMonth(containing date: Date) -> Date {
        let calendar = ScheduleEngine.calendar
        return calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
    }
    private func isDisplayedMonth(_ date: Date) -> Bool {
        ScheduleEngine.calendar.isDate(date, equalTo: periodStart, toGranularity: .month)
    }
    private static func startOfWeek(containing date: Date) -> Date {
        let calendar = ScheduleEngine.calendar
        let day = calendar.startOfDay(for: date)
        let daysSinceSunday = calendar.component(.weekday, from: day) - 1
        return calendar.date(byAdding: .day, value: -daysSinceSunday, to: day)!
    }
    private var days: [Date] {
        let calendar = ScheduleEngine.calendar
        let gridStart = Self.startOfWeek(containing: periodStart)
        let leadingDays = calendar.dateComponents([.day], from: gridStart, to: periodStart).day!
        let monthDays = calendar.range(of: .day, in: .month, for: periodStart)!.count
        let cellCount = ((leadingDays + monthDays + 6) / 7) * 7
        return (0..<cellCount).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }
    private func movePeriod(_ offset: Int) {
        guard let date = ScheduleEngine.calendar.date(byAdding: .month, value: offset, to: periodStart) else { return }
        periodStart = date
        selection = date
    }
    private func weekdayColor(_ date: Date) -> Color {
        let weekday = ScheduleEngine.calendar.component(.weekday, from: date)
        return weekday == 1 ? .red : weekday == 7 ? .blue : .primary
    }
    private func needsSecondIconRow(inWeekOf date: Date) -> Bool {
        let start = Self.startOfWeek(containing: date)
        return (0..<7).contains { offset in
            guard let day = ScheduleEngine.calendar.date(byAdding: .day, value: offset, to: start) else { return false }
            return types(day).count > 2
        }
    }
    private func dayCell(_ date: Date) -> some View {
        let selected = ScheduleEngine.calendar.isDate(date, inSameDayAs: selection)
        let today = ScheduleEngine.calendar.isDateInToday(date)
        let entries = types(date)
        // Every day in the week reserves the same icon rows, including empty days.
        // A minimum height lets intrinsic content exceed it at smaller text sizes.
        let iconRows = needsSecondIconRow(inWeekOf: date) ? 2 : 1
        let iconAreaHeight = CGFloat(iconRows * 22 + (iconRows - 1) * 2)
        return Button { selection = date } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .top, spacing: 0) {
                    Text(CollectionStyle.date(date, format: "d"))
                        .font(.subheadline.bold())
                        .foregroundStyle(weekdayColor(date))
                        .lineLimit(1).minimumScaleFactor(0.5)
                        .frame(height: dayNumberHeight)
                    Spacer(minLength: 0)
                    if entries.count > 4 {
                        Text("+\(entries.count - 4)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
                GeometryReader { geometry in
                    let iconSize = min(22, max(1, (geometry.size.width - 2) / 2))
                    VStack(spacing: 2) {
                        ForEach(0..<iconRows, id: \.self) { row in
                            HStack(spacing: 2) {
                                ForEach(Array(entries.dropFirst(row * 2).prefix(2)), id: \.self) { type in
                                    CollectionIcon(type: type, size: iconSize, iconType: CollectionStyle.iconType(for: type, on: date, models: vm.garbageRegistModelList))
                                }
                            }
                            .frame(maxWidth: .infinity).frame(height: 22)
                        }
                    }
                }.frame(height: iconAreaHeight)
            }
                .padding(2)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .frame(height: dayNumberHeight + 2 + iconAreaHeight + 4, alignment: .topLeading)
                .opacity(isDisplayedMonth(date) ? 1 : 0.4)
                .background(today ? CollectionStyle.accent.opacity(0.12) : Color(uiColor: .systemBackground))
                .overlay(Rectangle().strokeBorder(Color.secondary.opacity(0.5), lineWidth: selected ? 2 : 0.5))
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
            .accessibilityLabel(CollectionStyle.date(date) + "、" + (entries.isEmpty ? "収集なし" : entries.joined(separator: "、")))
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

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

struct CollectionInfoView: View {
    let name: String
    let reference: CollectionReference?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("表示中の収集予定") {
                    Text(name).font(.headline)
                }
                Section {
                    if let url = reference?.url {
                        Link(destination: url) {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("参考サイトを開く")
                                    Text(url.host ?? "").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }.padding(.vertical, 4)
                        }
                    } else {
                        Text("参考サイトは登録されていません").foregroundStyle(.secondary)
                    }
                } header: { Text("収集情報の出典") }
                  footer: { Text("必要に応じて確認してください。") }
            }
            .navigationTitle("この収集情報について")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("閉じる") { dismiss() } }
            }
            .tint(CollectionStyle.accent)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
