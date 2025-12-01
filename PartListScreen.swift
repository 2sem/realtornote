//
//  PartListScreen.swift
//  
//
//  Created by 영준 이 on 11/30/25.
//


import SwiftUI
import SwiftData

struct PartListScreen: View {
    let chapter: Chapter

    var sortedParts: [Part] {
        (chapter.parts ?? []).sorted { $0.seq < $1.seq }
    }

    var body: some View {
        TabView {
            ForEach(sortedParts, id: \.seq) { part in
                PartDetailView(part: part)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .background(Color(red: 0.506, green: 0.831, blue: 0.980))
    }
}