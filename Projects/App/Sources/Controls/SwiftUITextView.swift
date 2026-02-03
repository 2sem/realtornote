//
//  SwiftUITextView.swift
//  
//
//  Created by Claude on 12/1/25.
//


import SwiftUI
import UIKit

/// A SwiftUI wrapper around UITextView for better performance with large text content
struct SwiftUITextView: UIViewRepresentable {
    let text: String
    let attributedText: NSAttributedString?
    let font: UIFont
    let textColor: UIColor
    let backgroundColor: UIColor
    let isEditable: Bool
    let isScrollEnabled: Bool
    @Binding var scrollOffset: CGFloat
    let onScroll: ((CGFloat) -> Void)?
    let scrollToRange: NSRange?
    @Binding var showSearchBar: Bool
    let contentBottomInset: CGFloat
    @Binding var searchBarHeight: CGFloat
    let lineSpacing: CGFloat

    init(
        text: String,
        attributedText: NSAttributedString? = nil,
        font: UIFont = .systemFont(ofSize: 17),
        textColor: UIColor = .label,
        backgroundColor: UIColor = .clear,
        isEditable: Bool = false,
        isScrollEnabled: Bool = true,
        scrollOffset: Binding<CGFloat> = .constant(0),
        onScroll: ((CGFloat) -> Void)? = nil,
        scrollToRange: NSRange? = nil,
        showSearchBar: Binding<Bool> = .constant(false),
        contentBottomInset: CGFloat = 0,
        searchBarHeight: Binding<CGFloat> = .constant(0),
        lineSpacing: CGFloat = 0
    ) {
        self.text = text
        self.attributedText = attributedText
        self.font = font
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.isEditable = isEditable
        self.isScrollEnabled = isScrollEnabled
        self._scrollOffset = scrollOffset
        self.onScroll = onScroll
        self.scrollToRange = scrollToRange
        self._showSearchBar = showSearchBar
        self.contentBottomInset = contentBottomInset
        self._searchBarHeight = searchBarHeight
        self.lineSpacing = lineSpacing
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onScroll: onScroll)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = font
        textView.textColor = textColor
        textView.backgroundColor = backgroundColor
        textView.isEditable = isEditable
        textView.isScrollEnabled = isScrollEnabled
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = context.coordinator
        
        // Enable native iOS Find interaction
        textView.isFindInteractionEnabled = true

        // Performance optimizations
        textView.layoutManager.allowsNonContiguousLayout = true
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Update with attributed text if available, otherwise use plain text
        if let attributedText = attributedText {
            if uiView.attributedText != attributedText {
                // Apply font and line spacing to attributed text
                let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)
                let fullRange = NSRange(location: 0, length: mutableAttributedText.length)
                mutableAttributedText.addAttribute(.font, value: font, range: fullRange)
                if lineSpacing > 0 {
                    let paragraph = NSParagraphStyle.mutable()
                    paragraph.lineSpacing = lineSpacing
                    mutableAttributedText.addAttribute(.paragraphStyle, value: paragraph, range: fullRange)
                }
                uiView.attributedText = mutableAttributedText
            }
        } else if lineSpacing > 0 {
            // Rebuild attributed text when content, font, or line spacing changes
            if uiView.text != text || uiView.font != font {
                let mutableText = NSMutableAttributedString(string: text)
                let fullRange = NSRange(location: 0, length: mutableText.length)
                mutableText.addAttribute(.font, value: font, range: fullRange)
                mutableText.addAttribute(.foregroundColor, value: textColor, range: fullRange)
                let paragraph = NSParagraphStyle.mutable()
                paragraph.lineSpacing = lineSpacing
                mutableText.addAttribute(.paragraphStyle, value: paragraph, range: fullRange)
                uiView.attributedText = mutableText
            }
        } else if uiView.text != text {
            uiView.text = text
        }
        
        // Scroll to specific range if provided
        if let range = scrollToRange {
            uiView.scrollRangeToVisible(range)
        }
        
        // Set scroll position when scrollOffset binding changes (one-way: binding → view)
        // Only set if contentSize is ready (height > 0) to ensure scroll position can be applied
        if scrollToRange == nil && uiView.contentSize.height > 0 {
            let currentOffset = uiView.contentOffset.y - uiView.contentInset.top
            if abs(currentOffset - scrollOffset) > 1.0 {
                // Ensure scroll offset doesn't exceed content bounds
                let maxOffset = max(0, uiView.contentSize.height - uiView.bounds.height + uiView.contentInset.top + uiView.contentInset.bottom)
                let clampedOffset = min(scrollOffset, maxOffset)
                uiView.contentOffset = CGPoint(
                    x: uiView.contentInset.left,
                    y: clampedOffset + uiView.contentInset.top
                )
            }
        }
        
        if uiView.font != font {
            uiView.font = font
        }
        
        if uiView.textColor != textColor {
            uiView.textColor = textColor
        }
        
        if uiView.backgroundColor != backgroundColor {
            uiView.backgroundColor = backgroundColor
        }
        
        // Adjust content inset for bottom padding (allows content to scroll under overlays)
        var contentInset = uiView.contentInset
        contentInset.bottom = contentBottomInset
        if uiView.contentInset.bottom != contentInset.bottom {
            uiView.contentInset = contentInset
            
            var scrollIndicatorInsets = uiView.verticalScrollIndicatorInsets
            scrollIndicatorInsets.bottom = contentBottomInset
            uiView.verticalScrollIndicatorInsets = scrollIndicatorInsets
        }
        
        // Show/hide search bar
        if let findInteraction = uiView.findInteraction {
            if showSearchBar {
                // Present find navigator with keyboard
                if !findInteraction.isFindNavigatorVisible {
                    findInteraction.presentFindNavigator(showingReplace: false)
                }
                
                // Detect FindNavigator height if not already known
                detectSearchBarHeightIfNeeded(in: uiView)
            } else {
                // Dismiss find navigator
                if findInteraction.isFindNavigatorVisible {
                    findInteraction.dismissFindNavigator()
                }
            }
        }
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, UITextViewDelegate {
        let onScroll: ((CGFloat) -> Void)?

        init(onScroll: ((CGFloat) -> Void)?) {
            self.onScroll = onScroll
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            // Only call callback, don't update binding to avoid cycle
            onScroll?(scrollView.contentOffset.y)
        }
    }
}

// MARK: - Private Helpers

private extension SwiftUITextView {
    /// Detects the FindNavigator height by searching the view hierarchy if not already set
    func detectSearchBarHeightIfNeeded(in textView: UITextView) {
        guard searchBarHeight == 0 else { return }
        
        // Height not set yet, search for it
        Task { @MainActor in
            // Wait for view layout
            try? await Task.sleep(for: .milliseconds(300))
            
            guard let windowScene = textView.window?.windowScene else { return }
            
            let allWindows = windowScene.windows
            let searchPattern = "FindNavigator"
            
            for window in allWindows {
                if let findNavigatorView = window.findViewContaining(name: searchPattern) {
                    let height = findNavigatorView.frame.height
                    // Update binding directly
                    self.searchBarHeight = height
                    return
                }
            }
        }
    }
}

// MARK: - UIView Helpers

private extension UIView {
    /// Recursively searches the view hierarchy for a view whose class name contains the given string
    func findViewContaining(name: String) -> UIView? {
        // Check current view's class name
        let className = String(describing: type(of: self))
        if className.contains(name) {
            return self
        }
        
        // Recursively search subviews
        for subview in subviews {
            if let found = subview.findViewContaining(name: name) {
                return found
            }
        }
        
        return nil
    }
}

