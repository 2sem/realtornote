//
//  AppDelegate.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 24..
//  Copyright © 2017년 leesam. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications
import LSExtensions
import FirebaseMessaging

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()

        // Set up Messaging delegate for FCM
        Messaging.messaging().delegate = self

        // Set up notification center delegate
        UNUserNotificationCenter.current().delegate = self

        // Request notification permission on iOS < 26
        // On iOS 26+, AlarmKit will be used and permission will be requested when needed
        if #unavailable(iOS 26.0) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (result, error) in
                defer {
                    RNAlarmManager.shared.sync()
                }

                guard result else {
                    return
                }

                DispatchQueue.main.syncInMain {
                    application.registerForRemoteNotifications()
                }
            }
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers
        print("app enter background")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state
        print("app enter foreground")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused
        print("app become active")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate
    }

    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Device token registration handled by Firebase Messaging
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs registration failed: \(error)")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Remote notification handling
        completionHandler(.noData)
    }

    // MARK: UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("receive push notification in foreground. identifier[\(notification.request.identifier)] title[\(notification.request.content.title)] body[\(notification.request.content.body)]")

        completionHandler([.alert, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("receive push. title[\(response.notification.request.content.title)] body[\(response.notification.request.content.body)]")

        // Handle notification action if needed
        // Note: Alarm-related notifications are now handled by Alarm models

        completionHandler()
    }
}

// MARK: MessagingDelegate

extension AppDelegate : MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("fcm device[\(fcmToken ?? "")]")
        let topic = "notice"

        messaging.subscribe(toTopic: topic) { (error) in
            print("fcm messaging error[\(error?.localizedDescription ?? "")]")
        }
    }
}
