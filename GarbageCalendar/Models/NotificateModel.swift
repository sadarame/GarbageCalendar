//
//  NotificateModel.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/09/22.
//

import Foundation

class NotificateModel: Identifiable, Codable {
    var id: UUID
    var isNotificationEnabled: Bool // 通知の有効設定の有無
    var selectedDate: NotificationTiming // 通知するタイミング（前日か当日か）
    var selectionDate = Date() // 通知する時間（時分のみ）
    
    

    init(id: UUID = UUID(),
         isNotificationEnabled: Bool = false,
         notificationTiming: NotificationTiming = .onTheDay
         ) {
        self.id = id
        self.isNotificationEnabled = isNotificationEnabled
        self.selectedDate = notificationTiming
       
    }
}

enum NotificationTiming: String, Codable, CaseIterable {
    case onTheDay = "当日"
    case theDayBefore = "前日"
}



