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
            // TODO: Register/unregister notification via RNAlarmManager
            if enabled {
                // RNAlarmManager.shared.enable(alarm) { error, _ in }
            } else {
                // RNAlarmManager.shared.disable(alarm) { error, _ in }
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
        modelContext.delete(alarm)
        
        do {
            try modelContext.save()
            // TODO: Unregister notification via RNAlarmManager
            // RNAlarmManager.shared.remove(alarm) { error, _ in }
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
            // TODO: Register notification via RNAlarmManager
            // RNAlarmManager.shared.create(weekDays: weekDays, time: time, enabled: true)
        } catch {
            print("Failed to create alarm: \(error)")
        }
    }
    
    func updateAlarm(_ alarm: Alarm, weekDays: DateComponents.DateWeekDay, time: DateComponents) {
        alarm.alarmWeekDays = weekDays
        alarm.alarmTime = time
        
        do {
            try modelContext.save()
            // TODO: Update notification via RNAlarmManager
            // RNAlarmManager.shared.update(alarm, weekday: weekDays, time: time) { error, _ in }
        } catch {
            print("Failed to update alarm: \(error)")
        }
    }
}
