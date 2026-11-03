import SwiftUI

struct NotificationSetView: View {
    @StateObject var vm = NotificationSetVM()
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "bell.badge.fill").font(.system(size: 32)).foregroundStyle(CollectionStyle.accent)
                        Text("ちょうどいい時間に、お知らせ。")
                            .font(.title3.bold())
                        Text("収集するゴミがある日だけ通知します。")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }.padding(.vertical, 12)
                    Toggle("ゴミ出しの通知", isOn: $vm.model.isNotificationEnabled)
                        .onChange(of: vm.model.isNotificationEnabled) { _ in vm.checkNotificationPermission() }
                }
                Section {
                    Picker("通知する日", selection: $vm.model.dateType) {
                        ForEach(NotificationTiming.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.onChange(of: vm.model.dateType) { _ in vm.changeNotificateSetting() }
                    DatePicker("時刻", selection: $vm.model.notificateTime, displayedComponents: .hourAndMinute)
                        .onChange(of: vm.model.notificateTime) { _ in vm.changeNotificateSetting() }
                } header: { Text("タイミング") } footer: { Text("日本時間でお知らせします。通信状況によって届く時刻が前後する場合があります。") }
                .disabled(!vm.model.isNotificationEnabled)

                Section {
                    Button(action: vm.openAppSettings) {
                        Label("iPhoneの設定を開く", systemImage: "gearshape")
                    }
                } footer: {
                    Text("通知の許可・サウンド・バナーは、iPhoneの設定で変更できます。")
                }

            }
            .tint(CollectionStyle.accent)
            .navigationTitle("通知")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完了") { isPresented = false } } }
            .modifier(CommonViewModifier(vm: vm))
            .onAppear(perform: vm.onApperInit)
            .alert("通知を許可してください", isPresented: $vm.isShowNavigate) {
                Button("設定を開く", action: vm.openAppSettings)
                Button("あとで", role: .cancel) {}
            } message: { Text("iPhoneの設定で、このアプリからの通知を許可できます。") }
        }
    }
}
