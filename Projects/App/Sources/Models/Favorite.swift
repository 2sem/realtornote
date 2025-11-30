import Foundation
import SwiftData
import CoreData

@Model
final class Favorite {
    var no: Int32
    var partId: String
    
    init(no: Int32, partId: String) {
        self.no = no
        self.partId = partId
    }
    
    convenience init(from coreDataFavorite: RNFavoriteInfo) {
        self.init(
            no: coreDataFavorite.no,
            partId: coreDataFavorite.part?.objectID.uriRepresentation().absoluteString ?? ""
        )
    }
}
