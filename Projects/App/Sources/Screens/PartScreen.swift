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
    @State private var canPersistScrollOffset: Bool = false
    @State private var pendingRestoreOffset: CGFloat? = nil
    @State private var restoreAttemptCount: Int = 0
    @State private var lastPersistedOffset: CGFloat = 0
    @State private var scrollToRange: NSRange? = nil
    @State private var isSearching: Bool = false
    @State private var keyboardPadding: CGFloat = 0
    @State private var searchBarHeight: CGFloat = 0
    @State private var fontSize: CGFloat = 17
    @State private var lastMagnification: CGFloat = 1.0
    @State private var showSettings: Bool = false
    @Environment(KeyboardState.self) private var keyboardState
    
    // Font size constraints matching UIKit implementation
    private let minFontSize: CGFloat = 14
    private let maxFontSize: CGFloat = 30

    // Page indicator height (dots at bottom in PartListScreen's TabView)
    private let pageIndicatorHeight: CGFloat = 22
    private static let restoreDelays: [Int] = [0, 200, 400, 800]
    
    // Format content using LSDocumentRecognizer (like UIKit version)
    private var formattedContent: String {
        let paragraphs = LSDocumentRecognizer.shared.recognize(doc: part.content)
        return LSDocumentRecognizer.shared.toString(paragraphs)
    }

    // Handle scroll position changes
    private func handleScroll(_ offset: CGFloat) {
        let adjustedOffset = max(0, offset)
        scrollOffset = adjustedOffset

        if let target = pendingRestoreOffset {
            let isCloseEnough = abs(target - adjustedOffset) <= 1
            let maxAttemptsReached = restoreAttemptCount >= Self.restoreDelays.count - 1
            if isCloseEnough || maxAttemptsReached {
                pendingRestoreOffset = nil
                canPersistScrollOffset = true
                lastPersistedOffset = adjustedOffset
                LSDefaults.setLastContentOffSet(part: Int(part.id), value: Float(adjustedOffset))
                return
            }
        }

        guard canPersistScrollOffset else { return }
        guard abs(adjustedOffset - lastPersistedOffset) > 0.5 else { return }

        lastPersistedOffset = adjustedOffset
        LSDefaults.setLastContentOffSet(part: Int(part.id), value: Float(adjustedOffset))
    }
    
    // Restore scroll position with retries until UITextView is ready
    private func restoreScrollPosition(to offset: CGFloat, attempt: Int = 0) {
        Task { @MainActor in
            guard pendingRestoreOffset == offset else { return }
            restoreAttemptCount = attempt

            let delays = Self.restoreDelays
            let delay = delays[min(attempt, delays.count - 1)]
            if delay > 0 {
                try? await Task.sleep(for: .milliseconds(delay))
            }

            guard pendingRestoreOffset == offset else { return }
            scrollOffset = offset

            if attempt < delays.count - 1 {
                restoreScrollPosition(to: offset, attempt: attempt + 1)
            }
        }
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

                // Settings button
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape")
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
        .sheet(isPresented: $showSettings) {
            PartSettingsScreen(fontSize: $fontSize)
                .presentationDetents([.medium])
                .presentationDetents([.height(150)])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
        }
        .task {
            // Load saved font size
            let savedSize = LSDefaults.ContentSize
            if savedSize > 0 {
                fontSize = CGFloat(savedSize)
            }
        }
        .onAppear {
            canPersistScrollOffset = false
            pendingRestoreOffset = nil

            let savedOffset = max(0, CGFloat(LSDefaults.getLastContentOffset(Int(part.id))))
            lastPersistedOffset = savedOffset
            restoreAttemptCount = 0

            if savedOffset > 0 {
                pendingRestoreOffset = savedOffset
                restoreScrollPosition(to: savedOffset)
            } else {
                scrollOffset = 0
                canPersistScrollOffset = true
            }
        }
    }
}
