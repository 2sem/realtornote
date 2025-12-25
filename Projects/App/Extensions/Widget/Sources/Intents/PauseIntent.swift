//
//  PauseIntent.swift
//  Widget
//
//  Created by 영준 이 on 12/25/25.
//

import AlarmKit
import AppIntents

struct PauseIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        try AlarmKit.AlarmManager.shared.pause(id: UUID(uuidString: alarmID)!)
        return .result()
    }

    static var title: LocalizedStringResource = "일시정지"
    static var description = IntentDescription("알람을 일시정지합니다")

    @Parameter(title: "alarmID")
    var alarmID: String

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    init() {
        self.alarmID = ""
    }
}
