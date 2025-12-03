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

    @State private var scrollOffset: CGFloat = 0

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
            // Title header
            Text("\(part.seq). \(part.name)")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.506, green: 0.831, blue: 0.980))

            // Content using UITextView wrapper for performance
            SwiftUITextView(
                text: formattedContent,
                font: .systemFont(ofSize: 17),
                textColor: .label,
                backgroundColor: .clear,
                isEditable: false,
                isScrollEnabled: true,
                scrollOffset: $scrollOffset,
                onScroll: handleScroll
            )
        }
        .task {
            // Load saved scroll position when view appears
            let savedOffset = LSDefaults.getLastContentOffset(Int(part.id))
            scrollOffset = CGFloat(savedOffset)
        }
    }
}
