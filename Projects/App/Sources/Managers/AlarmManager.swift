//
//  AlarmManager.swift
//  realtornote
//
//  SwiftData version of RNAlarmManager
//  Handles both UserNotifications (iOS 18-25) and AlarmKit (iOS 26+)
//

import Foundation
import SwiftData

/// Unified alarm manager for SwiftUI/SwiftData
/// Delegates to AlarmKitManager for iOS 26+, uses UserNotifications for iOS 18-25
final class AlarmManager {
    static let shared = AlarmManager()

    private init() {}

    // MARK: - Registration

    /// Register alarm (create or update notification/alarm)
    func register(_ alarm: Alarm) async {
        if #available(iOS 26.0, *) {
            await AlarmKitManager.shared.scheduleAlarm(alarm)
        } else {
            registerWithUserNotifications(alarm)
        }
    }

    // MARK: - Enable/Disable

    /// Enable alarm
    func enable(_ alarm: Alarm) async {
        alarm.enabled = true
        await register(alarm)
    }

    /// Disable alarm
    func disable(_ alarm: Alarm) async {
        alarm.enabled = false
        await unregister(alarm)
    }

    // MARK: - Unregister

    /// Unregister alarm (remove notification/alarm)
    func unregister(_ alarm: Alarm) async {
        if #available(iOS 26.0, *) {
            await AlarmKitManager.shared.unscheduleAlarm(alarm)
        } else {
            unregisterWithUserNotifications(alarm)
        }
    }

    // MARK: - Request Authorization (iOS 26+)

    /// Request AlarmKit authorization on iOS 26+
    /// Returns true if authorized or if running on iOS 18-25 (UserNotifications already authorized)
    @available(iOS 26.0, *)
    func requestAlarmKitAuthorization() async -> Bool {
        return await AlarmKitManager.shared.requestAuthorization()
    }

    /// Check if AlarmKit is available and can be used
    var isAlarmKitAvailable: Bool {
        if #available(iOS 26.0, *) {
            return AlarmKitManager.shared.isAlarmKitAvailable
        }
        return false
    }

    // MARK: - UserNotifications Implementation (iOS 18-25)

    private func registerWithUserNotifications(_ alarm: Alarm) {
        let notifications = [alarm.toNotification()]
        UserNotificationManager.shared.unregister(notifications: notifications) { (result, notis, error) in
            guard error == nil else {
                print("Failed to unregister notification: \(error?.localizedDescription ?? "unknown")")
                return
            }

            if alarm.enabled {
                UserNotificationManager.shared.register(notifications: notifications)
                print("✅ UserNotification registered for alarm \(alarm.id)")
            }
        }
    }

    private func unregisterWithUserNotifications(_ alarm: Alarm) {
        let notifications = [alarm.toNotification()]
        UserNotificationManager.shared.unregister(notifications: notifications) { (result, notis, error) in
            if let error = error {
                print("Failed to unregister notification: \(error.localizedDescription)")
            } else {
                print("✅ UserNotification unregistered for alarm \(alarm.id)")
            }
        }
    }
}
