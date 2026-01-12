//
//  PartListScreen.swift
//  
//
//  Created by 영준 이 on 11/30/25.
//


import SwiftUI
import SwiftData

struct PartListScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(KeyboardState.self) private var keyboardState
    let chapter: Chapter
    let initialPartSeq: Int?
    
    @State private var viewModels: [Int: PartScreenModel] = [:]
    @State private var selectedPartSeq: Int = 0
    
    // Theme colors matching app
    private let backgroundColor = Color(red: 0.506, green: 0.831, blue: 0.980)

    var sortedParts: [Part] {
        chapter.parts.sorted { $0.seq < $1.seq }
    }
    
    private func getViewModel(for part: Part) -> PartScreenModel {
        if let existing = viewModels[part.seq] {
            return existing
        }
        let newModel = PartScreenModel(part: part, modelContext: modelContext)
        viewModels[part.seq] = newModel
        return newModel
    }

    var body: some View {
        TabView(selection: $selectedPartSeq) {
            ForEach(sortedParts, id: \.seq) { part in
                PartScreen(
                    part: part,
                    viewModel: getViewModel(for: part)
                )
                .tag(part.seq)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .scrollContentBackground(.hidden)
        .background(backgroundColor.ignoresSafeArea())
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Spacer to account for ExternalLinksBar + Subject TabBar height (only when keyboard hidden)
            // ExternalLinksBar: ~60pt + Subject TabBar: ~49pt + padding: ~10pt
            if !keyboardState.isVisible {
                Color.clear.frame(height: 80)
            }
        }
        .onAppear {
            print("📄 PartListScreen.onAppear - initialPartSeq: \(initialPartSeq ?? -1), selectedPartSeq: \(selectedPartSeq)")
            // Set initial selection if provided, otherwise use first part
            if let initialSeq = initialPartSeq {
                print("📄 Setting selectedPartSeq to initialPartSeq: \(initialSeq)")
                selectedPartSeq = initialSeq
            } else if selectedPartSeq == 0, let firstPart = sortedParts.first {
                print("📄 Setting selectedPartSeq to first part: \(firstPart.seq)")
                selectedPartSeq = firstPart.seq
            }
        }
        .onChange(of: initialPartSeq) { oldValue, newValue in
            print("📄 PartListScreen.onChange - initialPartSeq changed from \(oldValue ?? -1) to \(newValue ?? -1)")
            if let newSeq = newValue {
                print("📄 Updating selectedPartSeq to: \(newSeq)")
                selectedPartSeq = newSeq
            }
        }
    }
}
