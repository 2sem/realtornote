import Foundation
import SwiftData
import CoreData

@Model
final class Alarm {
    var id: Int64
    var enabled: Bool
    var time: Int64
    var title: String
    var weekdays: Int16
    var subjectId: String?
    
    init(id: Int64, enabled: Bool, time: Int64, title: String, weekdays: Int16, subjectId: String? = nil) {
        self.id = id
        self.enabled = enabled
        self.time = time
        self.title = title
        self.weekdays = weekdays
        self.subjectId = subjectId
    }
    
    convenience init(from coreDataAlarm: RNAlarmModel) {
        self.init(
            id: coreDataAlarm.id,
            enabled: coreDataAlarm.enabled,
            time: coreDataAlarm.time,
            title: coreDataAlarm.title ?? "",
            weekdays: coreDataAlarm.weekdays,
            subjectId: coreDataAlarm.subject?.objectID.uriRepresentation().absoluteString
        )
    }
}
