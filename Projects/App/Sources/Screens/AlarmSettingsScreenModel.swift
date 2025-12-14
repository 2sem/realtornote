//
//  AlarmSettingsScreenModel.swift
//  realtornote
//
//  Created for SwiftUI migration
//

import Foundation
import SwiftData
import LSExtensions

@Observable
final class AlarmSettingsScreenModel {
    var selectedWeekDays: DateComponents.DateWeekDay
    var selectedTime: DateComponents
    var showError: Bool = false
    
    private let alarm: Alarm?
    private let subject: Subject?
    private let modelContext: ModelContext
    private let onSave: ((DateComponents.DateWeekDay, DateComponents) -> Void)?
    
    let allWeekDays = DateComponents.DateWeekDay.allWeekDays
    
    init(
        alarm: Alarm? = nil,
        subject: Subject? = nil,
        modelContext: ModelContext,
        onSave: ((DateComponents.DateWeekDay, DateComponents) -> Void)? = nil
    ) {
        self.alarm = alarm
        self.subject = subject
        self.modelContext = modelContext
        self.onSave = onSave
        
        // Initialize state from existing alarm or defaults
        if let alarm = alarm {
            self.selectedWeekDays = alarm.alarmWeekDays
            self.selectedTime = alarm.alarmTime
        } else {
            self.selectedWeekDays = .All
            let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
            self.selectedTime = now
        }
    }
    
    func toggleWeekDay(_ weekDay: DateComponents.DateWeekDay) {
        if selectedWeekDays.contains(weekDay) {
            selectedWeekDays.subtract(weekDay)
        } else {
            selectedWeekDays.insert(weekDay)
        }
        showError = false
    }
    
    func toggleAll() {
        if selectedWeekDays == .All {
            selectedWeekDays = DateComponents.DateWeekDay(rawValue: 0)
        } else {
            selectedWeekDays = .All
        }
    }
    
    func applySettings() -> Bool {
        guard selectedWeekDays.days.count > 0 else {
            showError = true
            return false
        }
        
        if let onSave = onSave {
            // Use the callback for custom behavior (e.g., from AlarmListScreen)
            onSave(selectedWeekDays, selectedTime)
            return true
        } else if let alarm = alarm {
            // Update existing alarm (legacy path)
            alarm.alarmWeekDays = selectedWeekDays
            alarm.alarmTime = selectedTime
            
            do {
                try modelContext.save()
                // TODO: Register notification via RNAlarmManager
            } catch {
                print("Failed to save alarm: \(error)")
                return false
            }
        } else {
            // Create new alarm (legacy path when called from MainScreen with subject)
            let newAlarm = Alarm(
                id: Int64(Date().timeIntervalSince1970),
                enabled: true,
                time: 0,
                title: subject?.name ?? "",
                weekdays: 0,
                subject: subject
            )
            newAlarm.alarmWeekDays = selectedWeekDays
            newAlarm.alarmTime = selectedTime
            
            modelContext.insert(newAlarm)
            
            do {
                try modelContext.save()
                // TODO: Register notification via RNAlarmManager
            } catch {
                print("Failed to create alarm: \(error)")
                return false
            }
        }
        
        return true
    }
}
