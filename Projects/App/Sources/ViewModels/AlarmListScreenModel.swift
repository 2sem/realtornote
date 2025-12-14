//
//  AlarmListScreenModel.swift
//  realtornote
//
//  Created by Claude Code
//

import Foundation
import SwiftData
import LSExtensions

@Observable
final class AlarmListScreenModel {
    var showDeleteAlert: Bool = false
    var alarmToDelete: Alarm?
    
    private let modelContext: ModelContext
    private var alarms: [Alarm]
    
    init(modelContext: ModelContext, alarms: [Alarm]) {
        self.modelContext = modelContext
        self.alarms = alarms
    }
    
    func updateAlarms(_ alarms: [Alarm]) {
        self.alarms = alarms
    }
    
    func toggleAlarm(_ alarm: Alarm, enabled: Bool) {
        alarm.enabled = enabled

        do {
            try modelContext.save()
            // Register/unregister notification following RNAlarmManager pattern
            if enabled {
                registerNotification(for: alarm)
            } else {
                unregisterNotification(for: alarm)
            }
        } catch {
            print("Failed to toggle alarm: \(error)")
            // Rollback
            alarm.enabled = !enabled
        }
    }
    
    func showDeleteConfirmation(for alarm: Alarm) {
        alarmToDelete = alarm
        showDeleteAlert = true
    }
    
    func deleteAlarm(_ alarm: Alarm) {
        // Unregister notification before deleting
        unregisterNotification(for: alarm)

        modelContext.delete(alarm)

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete alarm: \(error)")
        }

        alarmToDelete = nil
    }
    
    func createAlarm(weekDays: DateComponents.DateWeekDay, time: DateComponents) {
        let newAlarm = Alarm(
            id: Int64(Date().timeIntervalSince1970),
            enabled: true,
            time: 0,
            title: "",
            weekdays: 0,
            subject: nil
        )
        newAlarm.alarmWeekDays = weekDays
        newAlarm.alarmTime = time

        modelContext.insert(newAlarm)

        do {
            try modelContext.save()
            // Register notification following RNAlarmManager.create pattern
            registerNotification(for: newAlarm)
        } catch {
            print("Failed to create alarm: \(error)")
        }
    }
    
    func updateAlarm(_ alarm: Alarm, weekDays: DateComponents.DateWeekDay, time: DateComponents) {
        alarm.alarmWeekDays = weekDays
        alarm.alarmTime = time

        do {
            try modelContext.save()
            // Update notification following RNAlarmManager.update pattern
            registerNotification(for: alarm)
        } catch {
            print("Failed to update alarm: \(error)")
        }
    }

    // MARK: - Notification Management

    private func registerNotification(for alarm: Alarm) {
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

    private func unregisterNotification(for alarm: Alarm) {
        let notifications = [alarm.toNotification()]
        UserNotificationManager.shared.unregister(notifications: notifications, completion: nil)
    }
}
