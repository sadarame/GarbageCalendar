import SwiftUI

struct GarbageRegistView: View {
    @StateObject var vm = GarbageRegistVM()
    @State private var editingRule: GarbageRegistModel?
    @State private var isAdding = false
    @State private var addedIDs: Set<UUID> = []
    @State private var pendingFocusID: UUID?
    @State private var focusID: UUID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var focusedRuleID: UUID?

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                List {
                    Section {
                        if !vm.garbageInfoName.isEmpty || vm.reference?.url != nil {
                            HStack(spacing: 12) {
                                if !vm.garbageInfoName.isEmpty {
                                    Text(vm.garbageInfoName).font(.headline)
                                }
                                Spacer(minLength: 8)
                                if let url = vm.reference?.url {
                                    Link(destination: url) {
                                        Text("参考サイト")
                                            .underline()
                                            .font(.subheadline)
                                            .fixedSize()
                                            .frame(minHeight: 44)
                                    }
                                }
                            }
                        }
                    }
                    Section {
                        if vm.garbageRegistModelList.isEmpty && !vm.isLoadingSchedule {
                            VStack(spacing: 12) {
                                Image(systemName: "calendar.badge.plus").font(.largeTitle)
                                Text("収集日はまだ登録されていません").font(.headline)
                            }.foregroundStyle(.secondary).frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center).padding(.vertical, 28)
                        }
                        ForEach(vm.garbageRegistModelList) { rule in
                            Button {
                                isAdding = false
                                editingRule = rule
                            } label: {
                                HStack(spacing: 12) {
                                    CollectionIcon(type: rule.garbageType, iconType: rule.iconType)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(rule.garbageType).font(.headline).foregroundStyle(.primary)
                                        Text(scheduleDescription(rule)).font(.subheadline).foregroundStyle(.secondary)
                                        if addedIDs.contains(rule.id) {
                                            Label("追加しました", systemImage: "checkmark.circle.fill")
                                                .font(.caption.weight(.semibold)).foregroundStyle(CollectionStyle.accent)
                                        }
                                        if rule.duplicateError {
                                            Text("同じ予定があります。編集または削除してください。")
                                                .font(.caption).foregroundStyle(.red)
                                        }
                                    }
                                    Spacer()
                                    Label("編集", systemImage: "pencil").font(.subheadline).foregroundStyle(CollectionStyle.accent)
                                }.padding(.vertical, 6)
                            }.buttonStyle(.plain)
                                .accessibilityHint("タップして収集日を編集")
                                .accessibilityFocused($focusedRuleID, equals: rule.id)
                                .id(rule.id)
                                .listRowBackground(addedIDs.contains(rule.id)
                                    ? CollectionStyle.accent.opacity(0.14) : CollectionStyle.surface)
                                .swipeActions {
                                    Button("削除", role: .destructive) {
                                        vm.garbageRegistModelList.removeAll { $0.id == rule.id }
                                        vm.saveCalendarEdits()
                                    }
                                }
                        }
                    } header: { Text("登録する収集日（\(vm.garbageRegistModelList.count)件）") }
                    Section {
                        Button {
                            isAdding = true
                            editingRule = GarbageRegistModel()
                        } label: {
                            Label("ゴミの種類・収集日を追加", systemImage: "plus.circle.fill")
                                .font(.headline).frame(minHeight: 44)
                        }
                    }
                }
                .safeAreaInset(edge: .top, spacing: 0) {
                    if focusID != nil {
                        Label("収集日を\(addedIDs.count)件追加しました", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CollectionStyle.forest)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding().background(CollectionStyle.surface)
                    }
                }
                .task(id: focusID) {
                    guard let target = focusID else { return }
                    // Wait for the dismissed sheet and updated list to finish layout.
                    do { try await Task.sleep(for: .milliseconds(150)) } catch { return }
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                        proxy.scrollTo(target, anchor: .center)
                    }
                    do { try await Task.sleep(for: .milliseconds(350)) } catch { return }
                    focusedRuleID = target
                    do { try await Task.sleep(for: .seconds(4)) } catch { return }
                    addedIDs = []
                    focusID = nil
                }
                .sheet(item: $editingRule, onDismiss: {
                    if let target = pendingFocusID {
                        focusID = target
                        pendingFocusID = nil
                    }
                }) { rule in
                    CollectionRuleEditor(rule: rule, isAdding: isAdding,
                                         types: vm.garbageTypes.contains(rule.garbageType)
                                            ? vm.garbageTypes : [rule.garbageType] + vm.garbageTypes) { rules in
                        if isAdding {
                            focusID = nil
                            addedIDs = Set(rules.map(\.id))
                            pendingFocusID = rules.first?.id
                            vm.garbageRegistModelList.append(contentsOf: rules)
                        } else if let index = vm.garbageRegistModelList.firstIndex(where: { $0.id == rule.id }) {
                            vm.garbageRegistModelList[index] = rules[0]
                        }
                        vm.saveCalendarEdits()
                    }
                }
                .sheet(isPresented: $vm.needsArea) {
                    NavigationStack { UserAddressRegistView(onAreaSelected: { vm.needsArea = false; vm.registData() }) }
                }
                .disabled(vm.isShowProgres)
                Divider()
                Button(action: vm.registData) {
                    HStack {
                        if vm.isShowProgres { ProgressView().tint(.white) }
                        Text(vm.isLoadingSchedule ? "読み込み中…" : (vm.isShowProgres ? "保存しています…" : "保存して完了")).fontWeight(.semibold)
                    }.frame(maxWidth: .infinity).padding(17).foregroundStyle(.white)
                        .background(vm.garbageRegistModelList.isEmpty ? Color.gray : CollectionStyle.forest,
                                    in: RoundedRectangle(cornerRadius: 18))
                }.buttonStyle(.plain).disabled(vm.isShowProgres || vm.garbageRegistModelList.isEmpty)
                    .padding(.horizontal, 20).padding(.vertical, 10).background(.bar)
            }
            .background(CollectionStyle.background)
            .overlay {
                if vm.isLoadingSchedule {
                    ZStack {
                        CollectionStyle.background.opacity(0.85)
                        ProgressView("収集情報を読み込み中…")
                            .progressViewStyle(.circular)
                            .tint(CollectionStyle.accent)
                            .padding(28)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
            .tint(CollectionStyle.accent)
            .navigationTitle("収集日の設定").navigationBarTitleDisplayMode(.inline)
            .modifier(CommonViewModifier(vm: vm))
            .navigationDestination(isPresented: $vm.toNextPage) { CalendarView() }
            .onAppear { vm.onApperInit() }
        }
    }
}

private func scheduleDescription(_ rule: GarbageRegistModel) -> String {
    switch rule.schedule {
    case "指定日のみ": return "指定日のみ：\((rule.specificDates ?? []).joined(separator: "、"))"
    case "毎月": return "毎月 \(rule.day)日"
    case "第○曜日": return "毎月 \(rule.weekOfMonth)\(rule.yobi)"
    case "隔週": return "\(rule.freqWeek)・\(rule.yobi)（基準日 \(CollectionStyle.date(rule.date, format: "M/d"))）"
    default: return "毎週 \(rule.yobi)"
    }
}

private struct CollectionRuleEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var rule: GarbageRegistModel
    let isAdding: Bool
    let types: [String]
    let onSave: ([GarbageRegistModel]) -> Void
    @State private var selectedDays: Set<String> = []
    private let weekdays = ["月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日", "日曜日"]

    var body: some View {
        NavigationStack {
            Form {
                Section("1. ゴミの種類") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 8) {
                        ForEach(types, id: \.self) { type in
                            Button { rule.garbageType = type } label: {
                                HStack(spacing: 6) {
                                    CollectionIcon(type: type, size: 28)
                                    Text(type).font(.subheadline).foregroundStyle(.primary)
                                    Spacer(minLength: 0)
                                    if rule.garbageType == type { Image(systemName: "checkmark.circle.fill") }
                                }.padding(10).frame(maxWidth: .infinity, minHeight: 52)
                                    .background(rule.garbageType == type ? CollectionStyle.accent.opacity(0.14) : Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                            }.buttonStyle(.plain)
                                .accessibilityAddTraits(rule.garbageType == type ? .isSelected : [])
                        }
                    }.padding(.vertical, 4)
                }
                Section("2. 収集日") {
                    Picker("繰り返し", selection: $rule.schedule) {
                        Text("毎週").tag("毎週")
                        Text("毎月 第○曜日").tag("第○曜日")
                        if rule.schedule == "指定日のみ" { Text("指定日のみ").tag("指定日のみ") }
                        Text("2〜4週ごと").tag("隔週")
                        Text("毎月 決まった日").tag("毎月")
                    }
                    if rule.schedule == "第○曜日" {
                        Picker("第何週", selection: $rule.weekOfMonth) {
                            ForEach(["第一", "第二", "第三", "第四", "第五"], id: \.self) { Text($0).tag($0) }
                        }
                    }
                    if rule.schedule == "隔週" {
                        Picker("間隔", selection: $rule.freqWeek) {
                            ForEach(["二週に一回", "三週に一回", "四週に一回"], id: \.self) { Text($0).tag($0) }
                        }
                        DatePicker("収集の開始日", selection: $rule.date, displayedComponents: .date)
                            .onChange(of: rule.date) { date in
                                rule.strDate = CollectionStyle.date(date, format: "yyyy-MM-dd")
                            }
                        Text("開始日以降、最初に来る指定曜日から繰り返します。")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if rule.schedule == "毎月" {
                        Picker("日にち", selection: $rule.day) {
                            ForEach(1...31, id: \.self) { Text("\($0)日").tag($0) }
                        }
                        Text("指定日がない月は収集予定が表示されません。")
                            .font(.caption).foregroundStyle(.secondary)
                    } else if isAdding && rule.schedule == "毎週" {
                        Text("収集曜日（複数選択できます）").font(.subheadline)
                        ForEach(weekdays, id: \.self) { day in
                            Button {
                                if selectedDays.contains(day) { selectedDays.remove(day) }
                                else { selectedDays.insert(day) }
                            } label: {
                                HStack {
                                    Text(day).foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: selectedDays.contains(day) ? "checkmark.circle.fill" : "circle")
                                }.frame(minHeight: 36).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                                .accessibilityAddTraits(selectedDays.contains(day) ? .isSelected : [])
                        }
                    } else {
                        Picker("曜日", selection: $rule.yobi) {
                            ForEach(weekdays, id: \.self) { Text($0).tag($0) }
                        }
                    }
                }
                Section("登録内容") {
                    Text(rule.garbageType).font(.headline)
                    Text(preview).foregroundStyle(.secondary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    Label(isAdding ? "この収集日を追加" : "変更を完了", systemImage: "checkmark.circle.fill")
                        .font(.headline).frame(maxWidth: .infinity).padding(14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAdding && rule.schedule == "毎週" && selectedDays.isEmpty)
                .padding(.horizontal).padding(.vertical, 8).background(.bar)
            }
            .navigationTitle(isAdding ? "収集日を追加" : "収集日を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isAdding ? "追加" : "完了") { save() }
                        .fontWeight(.semibold)
                        .disabled(isAdding && rule.schedule == "毎週" && selectedDays.isEmpty)
                }
            }
            .tint(CollectionStyle.accent)
        }
    }

    private var preview: String {
        if isAdding && rule.schedule == "毎週" {
            return selectedDays.isEmpty ? "収集曜日を選んでください" : "毎週 " + weekdays.filter { selectedDays.contains($0) }.joined(separator: "・")
        }
        return scheduleDescription(rule)
    }

    private func save() {
        rule.duplicateError = false
        if isAdding && rule.schedule == "毎週" {
            onSave(weekdays.filter { selectedDays.contains($0) }.map { day in
                var copy = rule
                copy.id = UUID()
                copy.yobi = day
                return copy
            })
        } else { onSave([rule]) }
        dismiss()
    }
}
