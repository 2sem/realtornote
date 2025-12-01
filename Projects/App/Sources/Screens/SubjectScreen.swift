import SwiftUI
import SwiftData

struct SubjectScreen: View {
    let subject: Subject

    @State private var selectedChapter: Chapter?

    var sortedChapters: [Chapter] {
        subject.chapters.sorted { $0.id < $1.id }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 챕터 선택기
            ChapterPicker(
                chapters: sortedChapters,
                selectedChapter: $selectedChapter
            )
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(red: 0.88, green: 0.96, blue: 0.996))

            // 파트 내용
            if let chapter = selectedChapter {
                PartListScreen(chapter: chapter)
            } else {
                Spacer()
                Text("챕터를 선택하세요")
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .navigationTitle(subject.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 마지막으로 본 챕터 복원
            if selectedChapter == nil {
                let lastChapterId = LSDefaults.LastChapter[subject.id.description] ?? sortedChapters.first?.id ?? 1
                selectedChapter = sortedChapters.first { $0.id == lastChapterId } ?? sortedChapters.first
            }
        }
        .onChange(of: selectedChapter) { oldValue, newValue in
            // 선택한 챕터 저장
            if let chapter = newValue {
                LSDefaults.setLastChapter(subject: subject.id, value: chapter.id)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SubjectScreen(subject: Subject(id: 1, name: "민법 및 민사특별법", detail: "Test"))
    }
}
