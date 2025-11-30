import Foundation
import SwiftData

@Model
final class Part {
    @Attribute(.unique) var id: Int
    var seq: Int
    var name: String
    var content: String
    
    var chapter: Chapter?
    
    init(id: Int, seq: Int, name: String, content: String, chapter: Chapter? = nil) {
        self.id = id
        self.seq = seq
        self.name = name
        self.content = content
        self.chapter = chapter
    }
    
    convenience init(from excelPart: RNExcelPart, chapter: Chapter?) {
        self.init(
            id: excelPart.id,
            seq: excelPart.seq,
            name: excelPart.name,
            content: excelPart.content,
            chapter: chapter
        )
    }
}
