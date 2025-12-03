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
    let font: UIFont
    let textColor: UIColor
    let backgroundColor: UIColor
    let isEditable: Bool
    let isScrollEnabled: Bool
    @Binding var scrollOffset: CGFloat
    let onScroll: ((CGFloat) -> Void)?
    
    init(
        text: String,
        font: UIFont = .systemFont(ofSize: 17),
        textColor: UIColor = .label,
        backgroundColor: UIColor = .clear,
        isEditable: Bool = false,
        isScrollEnabled: Bool = true,
        scrollOffset: Binding<CGFloat> = .constant(0),
        onScroll: ((CGFloat) -> Void)? = nil
    ) {
        self.text = text
        self.font = font
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.isEditable = isEditable
        self.isScrollEnabled = isScrollEnabled
        self._scrollOffset = scrollOffset
        self.onScroll = onScroll
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
        
        // Performance optimizations
        textView.layoutManager.allowsNonContiguousLayout = true
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Only update if text changed to avoid unnecessary re-renders
        if uiView.text != text {
            uiView.text = text
        }
        
        // Set scroll position when scrollOffset binding changes (one-way: binding → view)
        let currentOffset = uiView.contentOffset.y - uiView.contentInset.top
        if abs(currentOffset - scrollOffset) > 1.0 {
            uiView.contentOffset = CGPoint(
                x: uiView.contentInset.left,
                y: scrollOffset + uiView.contentInset.top
            )
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
