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
    var searchText: String = ""
    var isSearching: Bool = false
    var searchResults: [NSRange] = []
    var currentSearchIndex: Int = 0
    var highlightedContent: NSAttributedString?
    
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
    
    // MARK: - Search
    
    /// Start searching
    func startSearch() {
        isSearching = true
    }
    
    /// End searching and clear results
    func endSearch() {
        isSearching = false
        searchText = ""
        searchResults = []
        currentSearchIndex = 0
        highlightedContent = nil
    }
    
    /// Perform search and highlight matches
    func performSearch(in text: String) {
        guard !searchText.isEmpty else {
            searchResults = []
            highlightedContent = nil
            return
        }
        
        do {
            let regex = try NSRegularExpression(pattern: searchText, options: .caseInsensitive)
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
            
            searchResults = matches.map { $0.range }
            currentSearchIndex = 0
            
            // Create attributed string with highlights
            let attributedString = NSMutableAttributedString(string: text)
            
            for (index, range) in searchResults.enumerated() {
                let color: UIColor = index == 0 ? .systemGreen : .systemYellow
                attributedString.addAttribute(.backgroundColor, value: color, range: range)
            }
            
            highlightedContent = attributedString
        } catch {
            print("Search error: \(error)")
            searchResults = []
            highlightedContent = nil
        }
    }
    
    /// Move to next search result
    func nextSearchResult(in text: String) -> NSRange? {
        guard !searchResults.isEmpty else { return nil }
        
        let range = searchResults[currentSearchIndex]
        
        // Move to next index
        currentSearchIndex = (currentSearchIndex + 1) % searchResults.count
        
        // Update highlighting
        updateHighlighting(in: text)
        
        return range
    }
    
    /// Move to previous search result
    func previousSearchResult(in text: String) -> NSRange? {
        guard !searchResults.isEmpty else { return nil }
        
        // Move to previous index (with wrapping)
        currentSearchIndex = (currentSearchIndex - 1 + searchResults.count) % searchResults.count
        
        let range = searchResults[currentSearchIndex]
        
        // Update highlighting
        updateHighlighting(in: text)
        
        return range
    }
    
    /// Update highlighting for current search index
    private func updateHighlighting(in text: String) {
        let attributedString = NSMutableAttributedString(string: text)
        
        for (index, range) in searchResults.enumerated() {
            let color: UIColor = index == currentSearchIndex ? .systemGreen : .systemYellow
            attributedString.addAttribute(.backgroundColor, value: color, range: range)
        }
        
        highlightedContent = attributedString
    }
}
