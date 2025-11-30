import Foundation
import SwiftData

@Model
final class Chapter {
    @Attribute(.unique) var id: Int
    var seq: Int
    var name: String
    
    var subject: Subject?
    
    @Relationship(deleteRule: .cascade, inverse: \Part.chapter)
    var parts: [Part] = []
    
    init(id: Int, seq: Int, name: String, subject: Subject? = nil) {
        self.id = id
        self.seq = seq
        self.name = name
        self.subject = subject
    }
    
    convenience init(from excelChapter: RNExcelChapter, subject: Subject?) {
        self.init(
            id: excelChapter.id,
            seq: excelChapter.seq,
            name: excelChapter.name,
            subject: subject
        )
    }
}
