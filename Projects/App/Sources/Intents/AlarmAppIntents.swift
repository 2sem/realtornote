//
//  AlarmAppIntents.swift
//  realtornote
//
//  AppIntents for AlarmKit alarm interactions
//

import AlarmKit
import AppIntents
import Foundation

@available(iOS 26.0, *)
struct OpenStudyAppIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        // Stop the alarm
        try AlarmKit.AlarmManager.shared.stop(id: UUID(uuidString: alarmID)!)
        return .result()
    }

    static var title: LocalizedStringResource = "공부하기"
    static var description = IntentDescription("앱을 열어 공부를 시작합니다")
    static var openAppWhenRun = true

    @Parameter(title: "alarmID")
    var alarmID: String

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    init() {
        self.alarmID = ""
    }
}

@available(iOS 26.0, *)
struct StopStudyAlarmIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        // Stop the alarm
        try AlarmKit.AlarmManager.shared.stop(id: UUID(uuidString: alarmID)!)
        return .result()
    }

    static var title: LocalizedStringResource = "확인"
    static var description = IntentDescription("알람을 종료합니다")

    @Parameter(title: "alarmID")
    var alarmID: String

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    init() {
        self.alarmID = ""
    }
}
