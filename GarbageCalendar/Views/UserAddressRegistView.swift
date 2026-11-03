import SwiftUI

struct UserAddressRegistView: View {
    @StateObject var vm = UserAddressRegistVM()
    var onAreaSelected: (() -> Void)? = nil
    @FocusState private var inputFocused: Bool
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 32)).foregroundStyle(CollectionStyle.forest)
                    Text("収集日を探す")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }.padding(.top, 12)

                VStack(alignment: .leading, spacing: 16) {
                    Label("現在地から取得", systemImage: "location.fill").font(.headline)
                    Text("今いる場所の近くから、収集日を探します。")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Button {
                        inputFocused = false
                        vm.requestLocation()
                    } label: {
                        Text("現在地を取得する").font(.headline)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                    }.buttonStyle(SearchActionStyle())
                    if vm.permissionDenied {
                        Button("位置情報の設定を開く", action: vm.openAppSettings)
                            .buttonStyle(.bordered).controlSize(.large)
                    }
                }.padding(20)
                    .background(CollectionStyle.surface, in: RoundedRectangle(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 16) {
                    Label("郵便番号から指定", systemImage: "mappin.and.ellipse").font(.headline)
                    Text("郵便番号を入力して、地域の収集日を探します。")
                        .font(.subheadline).foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("郵便番号").font(.subheadline.weight(.semibold))
                        TextField("例：336-0911", text: $vm.postalQuery)
                            .accessibilityLabel("郵便番号")
                            .focused($inputFocused)
                            .keyboardType(.numbersAndPunctuation)
                            .submitLabel(.search).onSubmit(search)
                            .padding(.horizontal, 14).frame(minHeight: 56)
                            .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(inputFocused ? CollectionStyle.forest : Color(uiColor: .separator), lineWidth: inputFocused ? 2 : 1))
                    }
                    Button(action: search) {
                        Text("この郵便番号で探す").font(.headline)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                    }.buttonStyle(SearchActionStyle()).disabled(!canSearch)
                }.padding(20)
                    .background(CollectionStyle.surface, in: RoundedRectangle(cornerRadius: 24))
                if vm.isShowProgres {
                    ProgressView("検索中…").frame(maxWidth: .infinity)
                }
            }.padding(.horizontal, 24).padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(CollectionStyle.background.ignoresSafeArea())
        .disabled(vm.isShowProgres)
        .tint(CollectionStyle.accent)
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .modifier(CommonViewModifier(vm: vm))
        .navigationDestination(isPresented: Binding(get: { vm.activie && onAreaSelected == nil }, set: { vm.activie = $0 })) { GarbageMapView() }
        .sheet(isPresented: $vm.showPostalCandidates) {
            NavigationStack {
                List(Array(vm.postalCandidates.enumerated()), id: \.offset) { _, address in
                    Button(address.displayAddress) { vm.selectPostalAddress(address) }
                }
                .navigationTitle("住所を選択")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") { vm.showPostalCandidates = false }
                    }
                }
                .tint(CollectionStyle.accent)
            }
        }
        .onChange(of: vm.activie) { ready in
            if ready, let onAreaSelected { vm.activie = false; onAreaSelected() }
        }
    }
    private var canSearch: Bool {
        !vm.postalQuery
            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func search() {
        inputFocused = false
        vm.searchPostalCode()
    }

}

private struct SearchActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? Color.white : Color(uiColor: .secondaryLabel))
            .background(isEnabled ? CollectionStyle.forest : Color(uiColor: .systemGray4),
                        in: RoundedRectangle(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}
