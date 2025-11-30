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
    var subject: Subject?
    
    init(id: Int64, enabled: Bool, time: Int64, title: String, weekdays: Int16, subject: Subject? = nil) {
        self.id = id
        self.enabled = enabled
        self.time = time
        self.title = title
        self.weekdays = weekdays
        self.subject = subject
    }
}
