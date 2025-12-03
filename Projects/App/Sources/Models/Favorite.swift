import Foundation
import SwiftData
import CoreData

@Model
final class Favorite {
    @Attribute(.unique) var id: Int

    @Relationship(deleteRule: .noAction, inverse: \Part.favorite)
    var part: Part
    
    init(id: Int, part: Part) {
        self.id = id
        self.part = part
    }
}
