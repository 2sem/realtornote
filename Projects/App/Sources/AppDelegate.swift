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

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (result, error) in
            guard result else {
                return
            }

            DispatchQueue.main.syncInMain {
                application.registerForRemoteNotifications()
            }
        }

        return true
    }

    // MARK: UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("receive push notification in foreground. identifier[\(notification.request.identifier)] title[\(notification.request.content.title)] body[\(notification.request.content.body)]")

        completionHandler([.alert, .sound])
    }
}

// MARK: MessagingDelegate

extension AppDelegate : MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(fcmToken ?? "")")
        let topic = "notice"

        messaging.subscribe(toTopic: topic) { (error) in
            print("fcm messaging error[\(error?.localizedDescription ?? "")]")
        }
    }
}
