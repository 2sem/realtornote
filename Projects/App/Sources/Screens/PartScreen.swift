//
//  PartScreen.swift
//  App
//
//  Created by 영준 이 on 11/30/25.
//


import SwiftUI
import SwiftData

struct PartScreen: View {
    let part: Part
    @Bindable var viewModel: PartScreenModel

    @State private var scrollOffset: CGFloat = 0
    @State private var scrollToRange: NSRange? = nil
    @FocusState private var isSearchFieldFocused: Bool
    
    // Format content using LSDocumentRecognizer (like UIKit version)
    private var formattedContent: String {
        let paragraphs = LSDocumentRecognizer.shared.recognize(doc: part.content)
        return LSDocumentRecognizer.shared.toString(paragraphs)
    }

    // Handle scroll position changes
    private func handleScroll(_ offset: CGFloat) {
        LSDefaults.setLastContentOffSet(part: Int(part.id), value: Float(offset))
    }
    
    // Handle search submission (next result)
    private func handleSearchSubmit() {
        if let range = viewModel.nextSearchResult(in: formattedContent) {
            scrollToRange = range
            // Reset after scrolling
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                scrollToRange = nil
            }
        }
    }
    
    // Handle previous search result
    private func handleSearchPrevious() {
        if let range = viewModel.previousSearchResult(in: formattedContent) {
            scrollToRange = range
            // Reset after scrolling
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                scrollToRange = nil
            }
        }
    }
    
    // Handle next search result
    private func handleSearchNext() {
        if let range = viewModel.nextSearchResult(in: formattedContent) {
            scrollToRange = range
            // Reset after scrolling
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                scrollToRange = nil
            }
        }
    }
    
    // Handle search cancellation
    private func handleSearchCancel() {
        viewModel.endSearch()
        isSearchFieldFocused = false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Custom Search Bar (shown when searching)
            if viewModel.isSearching {
                SearchBar(
                    searchText: $viewModel.searchText,
                    isFocused: $isSearchFieldFocused,
                    hasResults: !viewModel.searchResults.isEmpty,
                    onCancel: handleSearchCancel,
                    onSubmit: handleSearchSubmit,
                    onPrevious: handleSearchPrevious,
                    onNext: handleSearchNext
                )
            }
            
            // Title header with search and favorite buttons (shown when not searching)
            if !viewModel.isSearching {
                HStack {
                    Text("\(part.seq). \(part.name)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Search button
                    Button(action: {
                        viewModel.startSearch()
                        // Focus search field after short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isSearchFieldFocused = true
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    
                    // Favorite button
                    Button(action: viewModel.toggleFavorite) {
                        Image(systemName: viewModel.isFavorited ? "bookmark.fill" : "bookmark")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.506, green: 0.831, blue: 0.980))
            }

            // Content using UITextView wrapper for performance
            SwiftUITextView(
                text: formattedContent,
                attributedText: viewModel.highlightedContent,
                font: .systemFont(ofSize: 17),
                textColor: .label,
                backgroundColor: .clear,
                isEditable: false,
                isScrollEnabled: true,
                scrollOffset: $scrollOffset,
                onScroll: handleScroll,
                scrollToRange: scrollToRange
            )
        }
        .onChange(of: viewModel.searchText) { oldValue, newValue in
            viewModel.performSearch(in: formattedContent)
            // Reset scroll to range when search text changes
            scrollToRange = nil
        }
        .task {
            // Load saved scroll position when view appears
            let savedOffset = LSDefaults.getLastContentOffset(Int(part.id))
            scrollOffset = CGFloat(savedOffset)
        }
    }
}
