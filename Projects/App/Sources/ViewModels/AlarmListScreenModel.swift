//
//  AlarmListScreenModel.swift
//  realtornote
//
//  Created by Claude Code
//

import Foundation
import SwiftData
import LSExtensions
import UserNotifications

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
        do {
            try modelContext.save()
            // AlarmManager handles both iOS 26+ (AlarmKit) and iOS 18-25 (UserNotifications)
            Task {
                if enabled {
                    await AlarmManager.shared.enable(alarm)
                } else {
                    await AlarmManager.shared.disable(alarm)
                }
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
        // Unregister alarm before deleting
        Task {
            await AlarmManager.shared.unregister(alarm)
        }

        modelContext.delete(alarm)

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete alarm: \(error)")
        }

        alarmToDelete = nil
    }
    
    func createAlarm(weekDays: DateComponents.DateWeekDay, time: DateComponents) async {
        // Request appropriate permission before creating first alarm
        if #available(iOS 26.0, *) {
            // Request AlarmKit authorization on iOS 26+
            _ = await AlarmManager.shared.requestAlarmKitAuthorization()
        } else {
            // Request UserNotifications permission on iOS < 26
            await requestUserNotificationsPermission()
        }

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
            // Register alarm
            await AlarmManager.shared.register(newAlarm)
        } catch {
            print("Failed to create alarm: \(error)")
        }
    }
    
    func updateAlarm(_ alarm: Alarm, weekDays: DateComponents.DateWeekDay, time: DateComponents) async {
        alarm.alarmWeekDays = weekDays
        alarm.alarmTime = time

        do {
            try modelContext.save()
            // Re-register alarm with new settings
            await AlarmManager.shared.register(alarm)
        } catch {
            print("Failed to update alarm: \(error)")
        }
    }

    private func requestUserNotificationsPermission() async {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error = error {
                    print("UserNotifications authorization failed: \(error)")
                }
                continuation.resume()
            }
        }
    }
}
