//
//  PartListScreen.swift
//  
//
//  Created by 영준 이 on 11/30/25.
//


import SwiftUI
import SwiftData

/// Holds one `PartScreenModel` per part. Plain class (not `@Observable`) so reads and writes
/// during view updates don't trigger SwiftUI invalidation.
final class PartScreenModelCache {
    var models: [Int: PartScreenModel] = [:]
}

struct PartListScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(KeyboardState.self) private var keyboardState
    let chapter: Chapter
    let initialPartSeq: Int?
    
    // Reference-type cache: filling it while `body` runs must not mutate view state
    // ("Modifying state during view update"), which a `@State` dictionary would.
    @State private var viewModelCache = PartScreenModelCache()
    @State private var selectedPartSeq: Int = 0
    
    // Theme colors matching app
    private let backgroundColor = Color.themeBackground

    var sortedParts: [Part] {
        chapter.parts.sorted { $0.seq < $1.seq }
    }
    
    private func savedPartSeq() -> Int? {
        LSDefaults.LastPart[chapter.id.description]
    }

    private func applySelection(preferredSeq: Int?) {
        let candidateSeq = preferredSeq ?? savedPartSeq()
        if let seq = candidateSeq,
           sortedParts.contains(where: { $0.seq == seq }) {
            selectedPartSeq = seq
            return
        }

        guard let firstSeq = sortedParts.first?.seq else {
            selectedPartSeq = 0
            return
        }

        selectedPartSeq = firstSeq
    }

    private func getViewModel(for part: Part) -> PartScreenModel {
        if let existing = viewModelCache.models[part.seq] {
            return existing
        }
        let newModel = PartScreenModel(part: part, modelContext: modelContext)
        viewModelCache.models[part.seq] = newModel
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
            // Spacer to account for Subject TabBar height (only when keyboard hidden)
            // Subject TabBar: ~49pt + padding: ~10pt
            if !keyboardState.isVisible && UIDevice.current.userInterfaceIdiom != .pad {
                Color.clear.frame(height: 80)
            }
        }
        .onAppear {
            applySelection(preferredSeq: initialPartSeq)
        }
        .onChange(of: initialPartSeq) { _, newValue in
            applySelection(preferredSeq: newValue)
        }
        .onChange(of: chapter.id) { _, _ in
            applySelection(preferredSeq: initialPartSeq)
        }
        .onChange(of: selectedPartSeq) { _, newValue in
            guard newValue > 0 else { return }
            LSDefaults.setLastPart(chapter: chapter.id, value: newValue)
        }
    }
}
