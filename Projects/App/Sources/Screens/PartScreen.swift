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
    @State private var keyboardPadding: CGFloat = 0
    @State private var searchBarHeight: CGFloat = 0
    @State private var fontSize: CGFloat = 17
    @State private var lastMagnification: CGFloat = 1.0
    @Environment(KeyboardState.self) private var keyboardState
    
    // Font size constraints matching UIKit implementation
    private let minFontSize: CGFloat = 14
    private let maxFontSize: CGFloat = 30

    // Page indicator height (dots at bottom in PartListScreen's TabView)
    private let pageIndicatorHeight: CGFloat = 22
    
    // Format content using LSDocumentRecognizer (like UIKit version)
    private var formattedContent: String {
        let paragraphs = LSDocumentRecognizer.shared.recognize(doc: part.content)
        return LSDocumentRecognizer.shared.toString(paragraphs)
    }

    // Handle scroll position changes
    private func handleScroll(_ offset: CGFloat) {
        LSDefaults.setLastContentOffSet(part: Int(part.id), value: Float(offset))
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

            // Content using UITextView wrapper with pinch-to-zoom
            GeometryReader { geometry in
                SwiftUITextView(
                    text: formattedContent,
                    font: .systemFont(ofSize: fontSize),
                    textColor: .label,
                    backgroundColor: .clear,
                    isEditable: false,
                    isScrollEnabled: true,
                    scrollOffset: $scrollOffset,
                    onScroll: handleScroll,
                    showSearchBar: $isSearching,
                    contentBottomInset: pageIndicatorHeight + (isSearching ? searchBarHeight : 0),
                    searchBarHeight: $searchBarHeight
                )
                .padding(.bottom, keyboardPadding)
                .simultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                            // Calculate font size change based on magnification delta
                            let delta = value - lastMagnification
                            let increment: CGFloat = delta > 0 ? 1 : -1
                            
                            // Only update if magnification changed significantly (threshold to prevent jitter)
                            if abs(delta) > 0.1 {
                                let newSize = fontSize + increment
                                fontSize = min(maxFontSize, max(minFontSize, newSize))
                                lastMagnification = value
                                
                                // Save to persistent storage
                                LSDefaults.ContentSize = Float(fontSize)
                            }
                        }
                        .onEnded { _ in
                            // Reset magnification tracking
                            lastMagnification = 1.0
                        }
                )
                .keyboardWillShow { notification in
                    guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                          let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                        return
                    }
                    
                    // Calculate overlap: text view bottom - keyboard top
                    let viewBottom = geometry.frame(in: .global).maxY
                    let keyboardTop = keyboardFrame.minY
                    let overlap = max(0, viewBottom - keyboardTop)
                    
                    // Subtract find bar height from padding (content can scroll under transparent bar)
                    let adjustedPadding = max(0, overlap - searchBarHeight)
                    
                    withAnimation(.easeOut(duration: animationDuration)) {
                        keyboardPadding = adjustedPadding
                    }
                }
                .keyboardWillHide { notification in
                    guard let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                        keyboardPadding = 0
                        return
                    }
                    
                    // Reset padding and search bar height
                    withAnimation(.easeOut(duration: animationDuration)) {
                        keyboardPadding = 0
                    }
                    
                    // Dismiss search when keyboard hides
                    if isSearching {
                        isSearching = false
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: isSearching) { oldValue, newValue in
            // Update keyboard visibility when find navigator changes
            keyboardState.isVisible = newValue
        }
        .task {
            // Load saved font size
            let savedSize = LSDefaults.ContentSize
            if savedSize > 0 {
                fontSize = CGFloat(savedSize)
            }
            
            // Load saved scroll position when view appears
            let savedOffset = LSDefaults.getLastContentOffset(Int(part.id))
            scrollOffset = CGFloat(savedOffset)
        }
    }
}
