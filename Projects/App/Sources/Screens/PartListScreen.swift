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
    let chapter: Chapter

    var sortedParts: [Part] {
        (chapter.parts ?? []).sorted { $0.seq < $1.seq }
    }

    var body: some View {
        TabView {
            ForEach(sortedParts, id: \.seq) { part in
                PartScreen(
                    part: part,
                    viewModel: PartScreenModel(part: part, modelContext: modelContext)
                )
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .background(Color(red: 0.506, green: 0.831, blue: 0.980))
    }
}
