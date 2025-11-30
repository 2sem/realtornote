import Foundation
import SwiftData
import CoreData

@Model
final class Favorite {
    var no: Int32
    var part: Part?
    
    init(no: Int32, part: Part? = nil) {
        self.no = no
        self.part = part
    }
}
