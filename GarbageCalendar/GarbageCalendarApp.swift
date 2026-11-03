//
//  GarbageCalendarApp.swift
//  GarbageCalendar
//
//  Created by Yosuke Yoshida on 2023/04/05.
//

import SwiftUI
import FirebaseCore
import FirebaseAppCheck
import FirebaseMessaging
import AppVersionMonitorSwiftUI
import FirebaseAnalytics

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AppCheck.setAppCheckProviderFactory(GarbageAppCheckFactory())
        FirebaseApp.configure()
        
        UNUserNotificationCenter.current().delegate = self
        // Register only if permission was already granted; ask in notification settings.
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if loadNotificateModel()?.isNotificationEnabled == true,
               settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
                DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
            }
        }

        Messaging.messaging().delegate = self
        
        Analytics.setAnalyticsCollectionEnabled(UserDefaults.standard.bool(forKey: "privacy.analyticsEnabled"))
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func
    messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let tokenChanged = loadFCMToken() != fcmToken
        saveFCMToken(fcmToken ?? "")
        if tokenChanged {
            Task { @MainActor in NotificationServerSync.shared.enqueue() }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
}

@main
struct GarbageCalendarApp: App {
    @StateObject private var session = UserSession.shared
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    //    @StateObject private var appVersionMonitor = AppVersionMonitor(id: 1570395606)
    
    
    var body: some Scene {
        WindowGroup {
            LaunchScreenView()
                .id(session.generation)
                .onChange(of: scenePhase) { phase in
                    if phase == .active {
                        NotificationServerSync.shared.enqueue()
                    }
                }
//            CalendarView()
            }
    }
    
}

final class GarbageAppCheckFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
#if targetEnvironment(simulator)
        return AppCheckDebugProviderFactory().createProvider(with: app)
#else
        return AppAttestProvider(app: app)
#endif
    }
}
