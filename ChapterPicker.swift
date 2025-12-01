//
//  ChapterPicker.swift
//  
//
//  Created by 영준 이 on 11/30/25.
//


import SwiftUI
import SwiftData

struct ChapterPicker: View {
    let chapters: [Chapter]
    @Binding var selectedChapter: Chapter?

    var body: some View {
        Menu {
            ForEach(chapters, id: \.id) { chapter in
                Button(action: {
                    selectedChapter = chapter
                }) {
                    HStack {
                        Text("\(chapter.id.roman). \(chapter.name)")
                        if selectedChapter?.id == chapter.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                if let chapter = selectedChapter {
                    Text("\(chapter.id.roman). \(chapter.name)")
                        .font(.headline)
                        .foregroundColor(Color(red: 0.004, green: 0.341, blue: 0.608))
                } else {
                    Text("챕터 선택")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.004, green: 0.341, blue: 0.608))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(8)
        }
    }
}