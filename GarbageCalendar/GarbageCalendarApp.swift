//
//  GarbageCalendarApp.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/04/05.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import AppVersionMonitorSwiftUI
import GoogleMobileAds

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        Messaging.messaging().delegate = self
        
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.reduce("") { $0 + String(format: "%02X", $1) }
        print("APNS Token: \(token)")
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func
    messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM Token: \(fcmToken)")
        saveFCMToken(fcmToken ?? "")
    }
    
    // Other delegate methods and app lifecycle handling here...
}

@main
struct GarbageCalendarApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    //    @StateObject private var appVersionMonitor = AppVersionMonitor(id: 1570395606)
    
    
    var body: some Scene {
        WindowGroup {
            LaunchScreenView()
//            CalendarView()
            }
    }
    
}
