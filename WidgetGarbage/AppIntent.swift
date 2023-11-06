//
//  AppIntent.swift
//  WidgetGarbage
//
//  Created by Yosuke Yoshida on 2023/11/06.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "設定"
    static var description = IntentDescription("ゴミカレンダーウィジェット")

    // An example configurable parameter.
    @Parameter(title: "明日の情報を表示", default: false)
    var isSetTomorrow: Bool
}
