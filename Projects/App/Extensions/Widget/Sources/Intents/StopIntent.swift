//
//  StopIntent.swift
//  Widget
//
//  Created by 영준 이 on 12/25/25.
//

import AlarmKit
import AppIntents

struct StopIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        try AlarmManager.shared.stop(id: UUID(uuidString: alarmID)!)
        return .result()
    }

    static var title: LocalizedStringResource = "정지"
    static var description = IntentDescription("알람을 정지합니다")

    @Parameter(title: "alarmID")
    var alarmID: String

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    init() {
        self.alarmID = ""
    }
}
