//
//  PartScreenModel.swift
//  App
//
//  Created by Claude on 12/3/25.
//

import SwiftUI
import SwiftData

@Observable
final class PartScreenModel {
    var isFavorited: Bool = false
    
    private let part: Part
    private let modelContext: ModelContext
    
    init(part: Part, modelContext: ModelContext) {
        self.part = part
        self.modelContext = modelContext
        checkFavoriteStatus()
    }
    
    /// Check if the current part is favorited
    private func checkFavoriteStatus() {
        // Use the 1:1 relationship directly
        isFavorited = part.favorite != nil
    }
    
    /// Toggle favorite status for the current part
    func toggleFavorite() {
        do {
            if let existingFavorite = part.favorite {
                // Remove from favorites using 1:1 relationship
                modelContext.delete(existingFavorite)
                isFavorited = false
            } else {
                // Add to favorites
                let newFavorite = Favorite(id: part.id, part: part)
                modelContext.insert(newFavorite)
                isFavorited = true
            }
            
            try modelContext.save()
        } catch {
            print("Error toggling favorite: \(error)")
        }
    }
}
