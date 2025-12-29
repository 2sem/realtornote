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
    let showSearchBar: Bool
    let onSearchDismissed: (() -> Void)?

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
        showSearchBar: Bool = false,
        onSearchDismissed: (() -> Void)? = nil
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
        self.showSearchBar = showSearchBar
        self.onSearchDismissed = onSearchDismissed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onScroll: onScroll, onSearchDismissed: onSearchDismissed)
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
                // Apply font to attributed text
                let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)
                mutableAttributedText.addAttribute(.font, value: font, range: NSRange(location: 0, length: mutableAttributedText.length))
                uiView.attributedText = mutableAttributedText
            }
        } else if uiView.text != text {
            uiView.text = text
        }
        
        // Scroll to specific range if provided
        if let range = scrollToRange {
            uiView.scrollRangeToVisible(range)
        }
        
        // Set scroll position when scrollOffset binding changes (one-way: binding → view)
        if scrollToRange == nil {
            let currentOffset = uiView.contentOffset.y - uiView.contentInset.top
            if abs(currentOffset - scrollOffset) > 1.0 {
                uiView.contentOffset = CGPoint(
                    x: uiView.contentInset.left,
                    y: scrollOffset + uiView.contentInset.top
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
        
        // Show/hide search bar
        if showSearchBar, let findInteraction = uiView.findInteraction {
            // Present find navigator with keyboard
            if !findInteraction.isFindNavigatorVisible {
                findInteraction.presentFindNavigator(showingReplace: false)
            }
            // Start monitoring for manual dismissal
            context.coordinator.startMonitoringFindInteraction(findInteraction)
        } else if !showSearchBar, let findInteraction = uiView.findInteraction {
            // Dismiss find navigator
            if findInteraction.isFindNavigatorVisible {
                findInteraction.dismissFindNavigator()
            }
            // Stop monitoring
            context.coordinator.stopMonitoringFindInteraction()
        }
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, UITextViewDelegate {
        let onScroll: ((CGFloat) -> Void)?
        let onSearchDismissed: (() -> Void)?
        private var findInteractionTimer: Timer?

        init(onScroll: ((CGFloat) -> Void)?, onSearchDismissed: (() -> Void)?) {
            self.onScroll = onScroll
            self.onSearchDismissed = onSearchDismissed
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            // Only call callback, don't update binding to avoid cycle
            onScroll?(scrollView.contentOffset.y)
        }
        
        func startMonitoringFindInteraction(_ findInteraction: UIFindInteraction?) {
            // Stop any existing timer
            stopMonitoringFindInteraction()
            
            guard let findInteraction = findInteraction else { return }
            
            // Poll every 0.1 seconds to check if find navigator is still visible
            findInteractionTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self, weak findInteraction] _ in
                guard let self = self, let findInteraction = findInteraction else {
                    self?.stopMonitoringFindInteraction()
                    return
                }
                
                // If find navigator became invisible, user dismissed it
                if !findInteraction.isFindNavigatorVisible {
                    self.onSearchDismissed?()
                    self.stopMonitoringFindInteraction()
                }
            }
        }
        
        func stopMonitoringFindInteraction() {
            findInteractionTimer?.invalidate()
            findInteractionTimer = nil
        }
    }
}

