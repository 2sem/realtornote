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
    @State private var isSearching: Bool = false
    @Environment(KeyboardState.self) private var keyboardState
    
    // Format content using LSDocumentRecognizer (like UIKit version)
    private var formattedContent: String {
        let paragraphs = LSDocumentRecognizer.shared.recognize(doc: part.content)
        return LSDocumentRecognizer.shared.toString(paragraphs)
    }

    // Handle scroll position changes
    private func handleScroll(_ offset: CGFloat) {
        LSDefaults.setLastContentOffSet(part: Int(part.id), value: Float(offset))
    }

    // Handle search dismissal
    private func handleSearchDismissed() {
        isSearching = false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title header with search and favorite buttons
            HStack {
                Text("\(part.seq). \(part.name)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Search button - opens native Find Navigator
                Button(action: {
                    isSearching = true
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

            // Content using UITextView wrapper with native Find
            SwiftUITextView(
                text: formattedContent,
                font: .systemFont(ofSize: 17),
                textColor: .label,
                backgroundColor: .clear,
                isEditable: false,
                isScrollEnabled: true,
                scrollOffset: $scrollOffset,
                onScroll: handleScroll,
                showSearchBar: isSearching,
                onSearchDismissed: handleSearchDismissed
            )
        }
        .onChange(of: isSearching) { oldValue, newValue in
            // Update keyboard visibility when find navigator changes
            keyboardState.isVisible = newValue
        }
        .task {
            // Load saved scroll position when view appears
            let savedOffset = LSDefaults.getLastContentOffset(Int(part.id))
            scrollOffset = CGFloat(savedOffset)
        }
    }
}
