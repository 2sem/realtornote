//
//  ChapterPicker.swift
//  
//
//  Created by 영준 이 on 11/30/25.
//


import SwiftUI
import SwiftData
import LSExtensions

struct ChapterPicker: View {
    let chapters: [Chapter]
    @Binding var selectedChapter: Chapter?

    var body: some View {
        Menu {
            ForEach(Array(chapters.enumerated()), id: \.element.id) { index, chapter in
                Button(action: {
                    selectedChapter = chapter
                }) {
                    HStack {
                        Text("\((index + 1).toRoman()). \(chapter.name)")
                        if selectedChapter?.id == chapter.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                if let chapter = selectedChapter,
                   let index = chapters.firstIndex(where: { $0.id == chapter.id }) {
                    Text("\((index + 1).toRoman()). \(chapter.name)")
                        .font(.headline)
                        .foregroundColor(Color.themePrimary)
                } else {
                    Text("챕터 선택")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(Color.themePrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.themeSurface)
            .cornerRadius(8)
        }
    }
}
