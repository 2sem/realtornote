import Foundation
import SwiftData

@Model
final class Subject {
    @Attribute(.unique) var id: Int
    var name: String
    var detail: String
    
    @Relationship(deleteRule: .cascade, inverse: \Chapter.subject)
    var chapters: [Chapter] = []
    
    init(id: Int, name: String, detail: String) {
        self.id = id
        self.name = name
        self.detail = detail
    }
    
    convenience init(from excelSubject: RNExcelSubject) {
        self.init(
            id: excelSubject.id,
            name: excelSubject.name,
            detail: excelSubject.detail
        )
    }
}
