//
//  AlarmKitManager.swift
//  realtornote
//
//  AlarmKit integration for iOS 26+
//  Falls back to UserNotifications for iOS 18-25
//

import Foundation
import SwiftData
import AlarmKit
import SwiftUI
import AppIntents

/// Manager for scheduling alarms using AlarmKit (iOS 26+) or UserNotifications (iOS 18-25)
@available(iOS 26.0, *)
final class AlarmKitManager {
    static let shared = AlarmKitManager()
    
#if DEBUG
    private let pretimerDuration: TimeInterval = 30
    private let postponeDuration: TimeInterval = 30
#else
    private let pretimerDuration: TimeInterval = 60 * 5
    private let postponeDuration: TimeInterval = 60 * 15
#endif

    private init() {}

    // MARK: - Authorization

    /// Request alarm authorization
    func requestAuthorization() async -> Bool {
        let manager = AlarmKit.AlarmManager.shared
        switch manager.authorizationState {
            case .notDetermined:
                do {
                    return try await manager.requestAuthorization() == .authorized
                } catch {
                    print("AlarmKit authorization failed: \(error)")
                    return false
                }
            case .authorized:
                return true
            case .denied:
                return false
            @unknown default:
                return false
        }
    }

    /// Check if AlarmKit is available and authorized
    var isAlarmKitAvailable: Bool {
        return AlarmKit.AlarmManager.shared.authorizationState == .authorized
    }

    // MARK: - Alarm Scheduling

    /// Schedule an alarm using AlarmKit
    func scheduleAlarm(_ alarm: Alarm) async {
        if isAlarmKitAvailable {
            await scheduleWithAlarmKit(alarm)
        } else {
            scheduleWithUserNotifications(alarm)
        }
    }

    /// Unschedule an alarm
    func unscheduleAlarm(_ alarm: Alarm) async {
        if isAlarmKitAvailable {
            await unscheduleWithAlarmKit(alarm)
        } else {
            unscheduleWithUserNotifications(alarm)
        }
    }

    // MARK: - AlarmKit Implementation

    private func scheduleWithAlarmKit(_ alarm: Alarm) async {
        let alarmID = UUID(uuidString: String(alarm.id)) ?? UUID()

        // Create schedule based on alarm settings
        let schedule = createSchedule(for: alarm)

        // Create metadata
        let metadata = StudyAlarmMetadata(
            title: alarm.subject?.name ?? "공부 시간",
            subtitle: "공인중개사 공부하실 시간입니다"
        )

        // Create presentation with alert and secondary button
        let alertContent = AlarmKit.AlarmPresentation.Alert(
            title: "공부시간",
            stopButton: AlarmKit.AlarmButton(
                text: "확인",
                textColor: .white,
                systemImageName: "checkmark.circle"
            ),
            secondaryButton: AlarmKit.AlarmButton(
                text: "15분 연기",
                textColor: .black,
                systemImageName: "repeat"
            ),
            secondaryButtonBehavior: .countdown
        )

        // Create alarm configuration with attributes and intents
        let configuration = AlarmKit.AlarmManager.AlarmConfiguration(
            countdownDuration: .init(
                preAlert: pretimerDuration,
                postAlert: postponeDuration),
            schedule: schedule,
            attributes: .init(
                presentation: .init(
                    alert: alertContent,
//                    countdown: countdownContent,
//                    paused: pausedContent
                ),
                metadata: metadata,
                tintColor: .yellow,//Color(red: 0.506, green: 0.831, blue: 0.980)
            ),
//            stopIntent: StopStudyAlarmIntent(alarmID: alarmID.uuidString),
//            secondaryIntent: OpenStudyAppIntent(alarmID: alarmID.uuidString)
        )

        do {
            try await AlarmKit.AlarmManager.shared.schedule(id: alarmID, configuration: configuration)
            print("✅ AlarmKit scheduled: \(alarmID)")
        } catch {
            print("❌ AlarmKit scheduling failed: \(error)")
            // Fallback to UserNotifications
            scheduleWithUserNotifications(alarm)
        }
    }

    private func unscheduleWithAlarmKit(_ alarm: Alarm) async {
        let alarmID = UUID(uuidString: String(alarm.id)) ?? UUID()

        do {
            try AlarmKit.AlarmManager.shared.cancel(id: alarmID)
            print("✅ AlarmKit unscheduled: \(alarmID)")
        } catch {
            print("❌ AlarmKit unscheduling failed: \(error)")
        }
    }

    private func createSchedule(for alarm: Alarm) -> AlarmKit.Alarm.Schedule {
        let timeComponents = alarm.alarmTime
        let weekdays = alarm.alarmWeekDays

        // Create time from components
        let time = AlarmKit.Alarm.Schedule.Relative.Time(
            hour: timeComponents.hour ?? 0,
            minute: timeComponents.minute ?? 0
        )

        // Check if recurring (has weekdays) or one-time
        if weekdays.days.isEmpty {
            // One-time alarm: no recurrence
            return .relative(
                AlarmKit.Alarm.Schedule.Relative(
                    time: time,
                    repeats: .never
                )
            )
        }

        // Recurring alarm with weekdays
        // Convert weekdays to Locale.Weekday format
        let localeWeekdays: [Locale.Weekday] = weekdays.days.compactMap { day -> Locale.Weekday? in
            switch day.weekday {
            case 1: return .sunday
            case 2: return .monday
            case 3: return .tuesday
            case 4: return .wednesday
            case 5: return .thursday
            case 6: return .friday
            case 7: return .saturday
            default: return nil
            }
        }

        // Create recurring schedule
        return .relative(
            AlarmKit.Alarm.Schedule.Relative(
                time: time,
                repeats: .weekly(localeWeekdays)
            )
        )
    }

    // MARK: - UserNotifications Fallback

    private func scheduleWithUserNotifications(_ alarm: Alarm) {
        let notifications = [alarm.toNotification()]
        UserNotificationManager.shared.unregister(notifications: notifications) { (result, notis, error) in
            guard error == nil else {
                return
            }

            if alarm.enabled {
                UserNotificationManager.shared.register(notifications: notifications)
            }
        }
    }

    private func unscheduleWithUserNotifications(_ alarm: Alarm) {
        let notifications = [alarm.toNotification()]
        UserNotificationManager.shared.unregister(notifications: notifications, completion: nil)
    }
}
