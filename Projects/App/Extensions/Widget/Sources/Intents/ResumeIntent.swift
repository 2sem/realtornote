//
//  ResumeIntent.swift
//  Widget
//
//  Created by 영준 이 on 12/25/25.
//

import AlarmKit
import AppIntents

struct ResumeIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        try AlarmKit.AlarmManager.shared.resume(id: UUID(uuidString: alarmID)!)
        return .result()
    }

    static var title: LocalizedStringResource = "재개"
    static var description = IntentDescription("알람을 재개합니다")

    @Parameter(title: "alarmID")
    var alarmID: String

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    init() {
        self.alarmID = ""
    }
}
