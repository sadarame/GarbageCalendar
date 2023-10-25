//
//  NotificateModel.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/09/22.
//

import Foundation

class NotificateModel: Identifiable, Codable {
    var id: UUID
    // 通知の有効設定の有無
    var isNotificationEnabled: Bool
    // 通知するタイミング（前日か当日か）
    var dateType: NotificationTiming
    // 通知する時間（時分のみ）
    var notificateTime:Date

    
    

    init(id: UUID = UUID(),
         isNotificationEnabled: Bool = false,
         notificationTiming: NotificationTiming = .onTheDay) {
        self.id = id
        self.isNotificationEnabled = isNotificationEnabled
        self.dateType = notificationTiming

        // notificateTimeを7時に設定
        let calendar = Calendar.current
        let now = Date()
        self.notificateTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now) ?? now
    }
}

enum NotificationTiming: String, Codable, CaseIterable {
    case onTheDay = "当日"
    case theDayBefore = "前日"
}



